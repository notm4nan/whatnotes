import 'package:flutter_test/flutter_test.dart';
import 'package:byte_task/data/repositories/inbox_repository.dart';
import 'package:byte_task/data/services/storage_service.dart';
import 'package:byte_task/domain/models/filter_options.dart';
import 'package:byte_task/domain/models/inbox_item.dart';

/// In-memory storage mock to test repository operations and relaunch simulation.
class InMemoryStorageService implements StorageService {
  List<InboxItem> saved = [];

  @override
  Future<List<InboxItem>> loadItems() async {
    return List.from(saved);
  }

  @override
  Future<void> saveItems(List<InboxItem> items) async {
    saved = List.from(items);
  }

  @override
  Future<void> deleteItem(String id) async {
    saved.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> clear() async {
    saved.clear();
  }
}

void main() {
  group('InboxRepository Tests', () {
    late InMemoryStorageService storage;
    late InboxRepository repository;

    setUp(() async {
      storage = InMemoryStorageService();
      repository = InboxRepository(storageService: storage);
      await repository.init(seedIfEmpty: false);
    });

    test('initializes empty when seedIfEmpty is false', () {
      expect(repository.items, isEmpty);
      expect(repository.isInitialized, isTrue);
    });

    test('seeds initial starter items when storage is empty and seedIfEmpty is true', () async {
      final freshStorage = InMemoryStorageService();
      final seededRepo = InboxRepository(storageService: freshStorage);
      await seededRepo.init(seedIfEmpty: true);

      expect(seededRepo.items, isNotEmpty);
      expect(seededRepo.items.length, equals(3));
      expect(freshStorage.saved.length, equals(3));
    });

    test('adds note, link, and image items and persists them', () async {
      final note = InboxItem.create(
        type: InboxItemType.note,
        title: 'Project Idea',
        content: 'Build offline local apps with Flutter.',
        tags: ['ideas'],
      );
      final link = InboxItem.create(
        type: InboxItemType.link,
        title: 'GitHub',
        content: 'https://github.com',
        tags: ['code'],
      );
      final image = InboxItem.create(
        type: InboxItemType.image,
        title: 'Sketch',
        content: 'images/sketch.png',
        tags: ['art'],
      );

      await repository.addItem(note);
      await repository.addItem(link);
      await repository.addItem(image);

      expect(repository.items.length, equals(3));
      expect(storage.saved.length, equals(3));
      expect(repository.getAllTags(), equals(['art', 'code', 'ideas']));
    });

    test('edits an existing item and updates updatedAt', () async {
      final item = InboxItem.create(
        type: InboxItemType.note,
        title: 'Original Title',
        content: 'Original Content',
        tags: ['draft'],
      );
      await repository.addItem(item);

      final updated = item.copyWith(
        title: 'Updated Title',
        content: 'Updated Content',
        tags: ['final'],
      );
      await repository.updateItem(updated);

      final retrieved = repository.getById(item.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.title, equals('Updated Title'));
      expect(retrieved.content, equals('Updated Content'));
      expect(retrieved.tags, equals(['final']));
    });

    test('deletes an item permanently', () async {
      final item = InboxItem.create(
        type: InboxItemType.note,
        title: 'To Delete',
        content: 'Content',
      );
      await repository.addItem(item);
      expect(repository.items.length, equals(1));

      final deleted = await repository.deleteItem(item.id);
      expect(deleted, isTrue);
      expect(repository.items, isEmpty);
      expect(storage.saved, isEmpty);
    });

    test('archives and restores items', () async {
      final item = InboxItem.create(
        type: InboxItemType.note,
        title: 'Active Item',
        content: 'Active Content',
      );
      await repository.addItem(item);
      expect(item.isArchived, isFalse);

      // Archive item
      final archived = await repository.toggleArchive(item.id);
      expect(archived!.isArchived, isTrue);
      expect(repository.getById(item.id)!.isArchived, isTrue);

      // Verify active query excludes archived item
      final activeList = repository.query(showArchived: false);
      expect(activeList, isEmpty);

      // Verify archive query includes archived item
      final archivedList = repository.query(showArchived: true);
      expect(archivedList.length, equals(1));

      // Restore item
      final restored = await repository.toggleArchive(item.id);
      expect(restored!.isArchived, isFalse);
      expect(repository.query(showArchived: false).length, equals(1));
    });

    group('Search & Filtering', () {
      setUp(() async {
        await repository.addItem(
          InboxItem.create(
            type: InboxItemType.note,
            title: 'Flutter Architecture Plan',
            content: 'Discussing state management with Provider.',
            tags: ['flutter', 'code'],
          ),
        );
        await repository.addItem(
          InboxItem.create(
            type: InboxItemType.link,
            title: 'Dart Language Tour',
            content: 'https://dart.dev/language',
            tags: ['dart', 'docs'],
          ),
        );
        await repository.addItem(
          InboxItem.create(
            type: InboxItemType.image,
            title: 'Design Wireframe',
            content: 'wireframe.png',
            tags: ['design', 'ui'],
          ),
        );
      });

      test('filters by type: notes only', () {
        final notes = repository.query(
          showArchived: false,
          typeFilter: ItemTypeFilter.notes,
        );
        expect(notes.length, equals(1));
        expect(notes.first.type, equals(InboxItemType.note));
      });

      test('filters by type: links only', () {
        final links = repository.query(
          showArchived: false,
          typeFilter: ItemTypeFilter.links,
        );
        expect(links.length, equals(1));
        expect(links.first.type, equals(InboxItemType.link));
      });

      test('filters by type: images only', () {
        final images = repository.query(
          showArchived: false,
          typeFilter: ItemTypeFilter.images,
        );
        expect(images.length, equals(1));
        expect(images.first.type, equals(InboxItemType.image));
      });

      test('filters by tag', () {
        final codeItems = repository.query(
          showArchived: false,
          tagFilter: 'code',
        );
        expect(codeItems.length, equals(1));
        expect(codeItems.first.title, contains('Flutter Architecture'));
      });

      test('searches across title, content, and tags', () {
        // Matches content
        final matchContent = repository.query(
          showArchived: false,
          searchQuery: 'provider',
        );
        expect(matchContent.length, equals(1));

        // Matches title
        final matchTitle = repository.query(
          showArchived: false,
          searchQuery: 'Wireframe',
        );
        expect(matchTitle.length, equals(1));

        // Matches tag
        final matchTag = repository.query(
          showArchived: false,
          searchQuery: 'docs',
        );
        expect(matchTag.length, equals(1));
      });

      test('sorts alphabetically by title', () {
        final sorted = repository.query(
          showArchived: false,
          sortOption: SortOption.alphabetical,
        );
        expect(sorted.length, equals(3));
        expect(sorted[0].title, equals('Dart Language Tour'));
        expect(sorted[1].title, equals('Design Wireframe'));
        expect(sorted[2].title, equals('Flutter Architecture Plan'));
      });
    });

    group('Relaunch / Persistence Simulation', () {
      test('data survives closing and reopening the app', () async {
        // 1. Add items in session 1
        final note = InboxItem.create(
          type: InboxItemType.note,
          title: 'Persistent Note',
          content: 'This note must survive app restart.',
          tags: ['critical'],
        );
        final link = InboxItem.create(
          type: InboxItemType.link,
          title: 'Persistent Link',
          content: 'https://example.com',
          tags: ['web'],
        );
        await repository.addItem(note);
        await repository.addItem(link);
        await repository.toggleArchive(link.id); // Archive the link

        // Verify storage received data
        expect(storage.saved.length, equals(2));

        // 2. Simulate app termination and relaunch with a fresh repository instance
        final relaunchedRepo = InboxRepository(storageService: storage);
        await relaunchedRepo.init(seedIfEmpty: false);

        // 3. Verify all data was completely restored in session 2
        expect(relaunchedRepo.items.length, equals(2));
        final restoredNote = relaunchedRepo.getById(note.id);
        final restoredLink = relaunchedRepo.getById(link.id);

        expect(restoredNote, isNotNull);
        expect(restoredNote!.title, equals('Persistent Note'));
        expect(restoredNote.isArchived, isFalse);
        expect(restoredNote.tags, equals(['critical']));

        expect(restoredLink, isNotNull);
        expect(restoredLink!.title, equals('Persistent Link'));
        expect(restoredLink.isArchived, isTrue); // Archive state preserved!
      });
    });
  });
}

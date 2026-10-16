import 'package:flutter_test/flutter_test.dart';
import 'package:byte_task/data/repositories/inbox_repository.dart';
import 'package:byte_task/domain/models/filter_options.dart';
import 'package:byte_task/domain/models/inbox_item.dart';
import 'package:byte_task/ui/view_models/inbox_view_model.dart';

import '../data/repositories/inbox_repository_test.dart';

void main() {
  group('InboxViewModel Tests', () {
    late InMemoryStorageService storage;
    late InboxRepository repository;
    late InboxViewModel viewModel;

    setUp(() async {
      storage = InMemoryStorageService();
      repository = InboxRepository(storageService: storage);
      await repository.init(seedIfEmpty: false);
      viewModel = InboxViewModel(repository: repository);
    });

    test('creates new note and notifies listeners', () async {
      var notified = false;
      viewModel.addListener(() => notified = true);

      final created = await viewModel.createItem(
        type: InboxItemType.note,
        title: 'New Note',
        content: 'Note Body',
        tags: ['test'],
      );

      expect(notified, isTrue);
      expect(viewModel.items.length, equals(1));
      expect(viewModel.items.first.id, equals(created.id));
      expect(viewModel.activeCount, equals(1));
      expect(viewModel.archivedCount, equals(0));
    });

    test('creates item with empty title auto-infers title', () async {
      final created = await viewModel.createItem(
        type: InboxItemType.note,
        title: '   ',
        content: 'First line of note\nSecond line',
      );

      expect(created.title, equals('First line of note'));
    });

    test('updates item content and tags', () async {
      final item = await viewModel.createItem(
        type: InboxItemType.note,
        title: 'Initial Title',
        content: 'Initial Content',
        tags: ['v1'],
      );

      await viewModel.updateItem(
        id: item.id,
        title: 'Updated Title',
        content: 'Updated Content',
        tags: ['v2'],
      );

      final updated = viewModel.getItemById(item.id);
      expect(updated!.title, equals('Updated Title'));
      expect(updated.content, equals('Updated Content'));
      expect(updated.tags, equals(['v2']));
    });

    test('deletes item permanently', () async {
      final item = await viewModel.createItem(
        type: InboxItemType.note,
        title: 'To Delete',
        content: 'Content',
      );
      expect(viewModel.totalCount, equals(1));

      final deleted = await viewModel.deleteItem(item.id);
      expect(deleted, isTrue);
      expect(viewModel.totalCount, equals(0));
    });

    test('archives and restores item', () async {
      final item = await viewModel.createItem(
        type: InboxItemType.note,
        title: 'Item to Archive',
        content: 'Content',
      );

      // Archive item
      await viewModel.archiveItem(item.id);
      expect(viewModel.activeCount, equals(0));
      expect(viewModel.archivedCount, equals(1));

      // View active inbox: should be empty
      viewModel.setViewFilter(InboxViewFilter.active);
      expect(viewModel.items, isEmpty);

      // View archived inbox: should show item
      viewModel.setViewFilter(InboxViewFilter.archived);
      expect(viewModel.items.length, equals(1));

      // Restore item
      await viewModel.restoreItem(item.id);
      expect(viewModel.activeCount, equals(1));
      expect(viewModel.archivedCount, equals(0));
    });

    test('applies search, type, and tag filters, then clears them', () async {
      await viewModel.createItem(
        type: InboxItemType.note,
        title: 'Flutter Widgets',
        content: 'Stateless and stateful widgets',
        tags: ['flutter'],
      );
      await viewModel.createItem(
        type: InboxItemType.link,
        title: 'Dart Docs',
        content: 'https://dart.dev',
        tags: ['dart'],
      );

      expect(viewModel.items.length, equals(2));

      // Filter by type: links only
      viewModel.setTypeFilter(ItemTypeFilter.links);
      expect(viewModel.items.length, equals(1));
      expect(viewModel.items.first.type, equals(InboxItemType.link));

      // Filter by tag
      viewModel.setSelectedTag('flutter');
      // No links with tag 'flutter', so items is 0
      expect(viewModel.items, isEmpty);

      // Search query
      viewModel.clearFilters();
      viewModel.setSearchQuery('widgets');
      expect(viewModel.items.length, equals(1));
      expect(viewModel.items.first.title, equals('Flutter Widgets'));

      // Clear filters
      viewModel.clearFilters();
      expect(viewModel.items.length, equals(2));
      expect(viewModel.hasActiveFilters, isFalse);
    });
  });
}

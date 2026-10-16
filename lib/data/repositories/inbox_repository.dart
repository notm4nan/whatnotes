import '../../domain/models/filter_options.dart';
import '../../domain/models/inbox_item.dart';
import '../services/storage_service.dart';

/// Repository managing inbox items, persistence coordination,
/// query filtering, tagging, and search indexing.
class InboxRepository {
  InboxRepository({required this.storageService});

  final StorageService storageService;
  final List<InboxItem> _items = [];
  bool _initialized = false;

  bool get isInitialized => _initialized;
  List<InboxItem> get items => List.unmodifiable(_items);

  /// Initializes the repository by loading items from local storage.
  /// Seeds initial welcome items if local storage is completely empty.
  Future<void> init({bool seedIfEmpty = true}) async {
    final loaded = await storageService.loadItems();
    _items.clear();

    if (loaded.isEmpty && seedIfEmpty) {
      final sampleItems = _generateSeedData();
      _items.addAll(sampleItems);
      await storageService.saveItems(_items);
    } else {
      final migrated = loaded
          .where((item) => item.id != 'seed-sample-image')
          .map((item) {
            if (item.id == 'seed-welcome-note') {
              return item.copyWith(id: 'dashnote-new');
            }
            return item;
          })
          .toList();
      if (loaded.any((item) => item.id == 'seed-sample-image')) {
        await storageService.deleteItem('seed-sample-image');
      }
      if (migrated.any((item) => item.id == 'dashnote-new') &&
          loaded.any((item) => item.id == 'seed-welcome-note')) {
        await storageService.deleteItem('seed-welcome-note');
        await storageService.saveItems(migrated);
      }
      _items.addAll(migrated);
    }
    _initialized = true;
  }

  /// Adds a new item and persists to storage.
  Future<InboxItem> addItem(InboxItem item) async {
    _items.insert(0, item);
    await storageService.saveItems(_items);
    return item;
  }

  /// Updates an existing item and persists to storage.
  Future<InboxItem> updateItem(InboxItem updatedItem) async {
    final index = _items.indexWhere((item) => item.id == updatedItem.id);
    if (index == -1) {
      throw ArgumentError('Item with ID ${updatedItem.id} not found.');
    }
    _items[index] = updatedItem;
    await storageService.saveItems(_items);
    return updatedItem;
  }

  /// Deletes an item by ID and persists to storage.
  Future<bool> deleteItem(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return false;
    _items.removeAt(index);
    await storageService.deleteItem(id);
    return true;
  }

  /// Toggles the archive status of an item.
  Future<InboxItem?> toggleArchive(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return null;
    final current = _items[index];
    final updated = current.copyWith(
      isArchived: !current.isArchived,
      updatedAt: DateTime.now(),
    );
    _items[index] = updated;
    await storageService.saveItems(_items);
    return updated;
  }

  /// Explicitly sets archive state for an item.
  Future<InboxItem?> setArchived(String id, bool archived) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return null;
    final current = _items[index];
    if (current.isArchived == archived) return current;

    final updated = current.copyWith(
      isArchived: archived,
      updatedAt: DateTime.now(),
    );
    _items[index] = updated;
    await storageService.saveItems(_items);
    return updated;
  }

  /// Retrieves an item by its unique ID.
  InboxItem? getById(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Returns all unique tags used across all items, sorted alphabetically.
  List<String> getAllTags() {
    final tagSet = <String>{};
    for (final item in _items) {
      tagSet.addAll(item.tags);
    }
    final sorted = tagSet.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return List.unmodifiable(sorted);
  }

  /// Filters, searches, and sorts inbox items based on criteria.
  List<InboxItem> query({
    required bool showArchived,
    ItemTypeFilter typeFilter = ItemTypeFilter.all,
    String? tagFilter,
    String searchQuery = '',
    SortOption sortOption = SortOption.newestFirst,
  }) {
    final queryText = searchQuery.trim().toLowerCase();

    final filtered = _items.where((item) {
      // 1. Archive filter
      if (item.isArchived != showArchived) {
        return false;
      }

      // 2. Type filter
      if (typeFilter.targetType != null && item.type != typeFilter.targetType) {
        return false;
      }

      // 3. Tag filter
      if (tagFilter != null && tagFilter.isNotEmpty) {
        final hasTag = item.tags.any(
          (t) => t.toLowerCase() == tagFilter.toLowerCase(),
        );
        if (!hasTag) return false;
      }

      // 4. Search query (matches title, content, or tags)
      if (queryText.isNotEmpty) {
        final matchesTitle = item.title.toLowerCase().contains(queryText);
        final matchesContent = item.content.toLowerCase().contains(queryText);
        final matchesTag = item.tags.any(
          (t) => t.toLowerCase().contains(queryText),
        );

        if (!matchesTitle && !matchesContent && !matchesTag) {
          return false;
        }
      }

      return true;
    }).toList();

    // 5. Sort
    filtered.sort((a, b) {
      switch (sortOption) {
        case SortOption.newestFirst:
          return b.createdAt.compareTo(a.createdAt);
        case SortOption.oldestFirst:
          return a.createdAt.compareTo(b.createdAt);
        case SortOption.recentlyUpdated:
          return b.updatedAt.compareTo(a.updatedAt);
        case SortOption.alphabetical:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    });

    return filtered;
  }

  /// Generates helpful starter seed items for the user's initial inbox.
  static List<InboxItem> _generateSeedData() {
    final now = DateTime.now();
    return [
      InboxItem(
        id: 'dashnote-new',
        type: InboxItemType.note,
        title: 'Welcome to your Offline Inbox!',
        content:
            'This is your personal single-device inbox.\n\n'
            '• Save notes, web links, and images.\n'
            '• Organize with tags like #ideas, #flutter, #work.\n'
            '• Search anything in real-time.\n'
            '• Archive items to declutter, or restore them anytime.\n'
            '• Everything is persisted locally on this device.',
        tags: const ['welcome', 'guide'],
        createdAt: now.subtract(const Duration(minutes: 1)),
        updatedAt: now.subtract(const Duration(minutes: 1)),
        isArchived: false,
      ),
      InboxItem(
        id: 'seed-flutter-link',
        type: InboxItemType.link,
        title: 'Flutter Documentation & Guides',
        content: 'https://docs.flutter.dev',
        tags: const ['flutter', 'docs', 'reference'],
        createdAt: now.subtract(const Duration(minutes: 5)),
        updatedAt: now.subtract(const Duration(minutes: 5)),
        isArchived: false,
      ),
    ];
  }
}

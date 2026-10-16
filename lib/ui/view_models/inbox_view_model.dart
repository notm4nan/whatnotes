import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/inbox_repository.dart';
import '../../domain/models/filter_options.dart';
import '../../domain/models/inbox_item.dart';

/// ViewModel managing state for the local inbox.
/// Connects the UI to [InboxRepository] following MVVM pattern.
class InboxViewModel extends ChangeNotifier {
  InboxViewModel({required this.repository});

  final InboxRepository repository;

  bool _isLoading = false;
  String? _errorMessage;

  InboxViewFilter _viewFilter = InboxViewFilter.active;
  ItemTypeFilter _typeFilter = ItemTypeFilter.all;
  String? _selectedTag;
  String _searchQuery = '';
  SortOption _sortOption = SortOption.newestFirst;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  InboxViewFilter get viewFilter => _viewFilter;
  ItemTypeFilter get typeFilter => _typeFilter;
  String? get selectedTag => _selectedTag;
  String get searchQuery => _searchQuery;
  SortOption get sortOption => _sortOption;

  bool get isArchivedView => _viewFilter == InboxViewFilter.archived;

  /// Returns currently filtered, searched, and sorted list of items.
  List<InboxItem> get items {
    return repository.query(
      showArchived: _viewFilter == InboxViewFilter.archived,
      typeFilter: _typeFilter,
      tagFilter: _selectedTag,
      searchQuery: _searchQuery,
      sortOption: _sortOption,
    );
  }

  /// All unique tags across all items in storage.
  List<String> get allTags => repository.getAllTags();

  /// Total count of active (unarchived) items.
  int get activeCount => repository.items.where((i) => !i.isArchived).length;

  /// Total count of archived items.
  int get archivedCount => repository.items.where((i) => i.isArchived).length;

  /// Total count of all items.
  int get totalCount => repository.items.length;

  /// Retrieves an item by its ID directly from the repository.
  InboxItem? getItemById(String id) => repository.getById(id);

  /// Check whether any filter (type, tag, or search) is currently applied.
  bool get hasActiveFilters =>
      _typeFilter != ItemTypeFilter.all ||
      _selectedTag != null ||
      _searchQuery.trim().isNotEmpty;

  /// Initializes the repository data.
  Future<void> init() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.init();
    } catch (e) {
      _errorMessage = 'Failed to load inbox: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new inbox item.
  Future<InboxItem> createItem({
    required InboxItemType type,
    required String title,
    required String content,
    List<String> tags = const [],
  }) async {
    final newItem = InboxItem.create(
      type: type,
      title: title,
      content: content,
      tags: tags,
      isArchived: false,
    );

    await repository.addItem(newItem);
    notifyListeners();
    return newItem;
  }

  /// Updates an existing item.
  Future<InboxItem> updateItem({
    required String id,
    String? title,
    String? content,
    InboxItemType? type,
    List<String>? tags,
  }) async {
    final existing = repository.getById(id);
    if (existing == null) {
      throw ArgumentError('Item not found: $id');
    }

    final updated = existing.copyWith(
      title: title,
      content: content,
      type: type,
      tags: tags,
      updatedAt: DateTime.now(),
    );

    await repository.updateItem(updated);
    notifyListeners();
    return updated;
  }

  /// Deletes an item permanently.
  Future<bool> deleteItem(String id) async {
    final result = await repository.deleteItem(id);
    if (result) {
      notifyListeners();
    }
    return result;
  }

  /// Toggles archive status of an item.
  Future<InboxItem?> toggleArchive(String id) async {
    final updated = await repository.toggleArchive(id);
    if (updated != null) {
      notifyListeners();
    }
    return updated;
  }

  /// Explicitly archives an item.
  Future<InboxItem?> archiveItem(String id) async {
    final updated = await repository.setArchived(id, true);
    if (updated != null) {
      notifyListeners();
    }
    return updated;
  }

  /// Explicitly restores an archived item.
  Future<InboxItem?> restoreItem(String id) async {
    final updated = await repository.setArchived(id, false);
    if (updated != null) {
      notifyListeners();
    }
    return updated;
  }

  /// Switch between Inbox and Archived view.
  void setViewFilter(InboxViewFilter filter) {
    if (_viewFilter != filter) {
      _viewFilter = filter;
      notifyListeners();
    }
  }

  /// Filter items by type (Notes, Links, Images, or All).
  void setTypeFilter(ItemTypeFilter filter) {
    if (_typeFilter != filter) {
      _typeFilter = filter;
      notifyListeners();
    }
  }

  /// Filter items by a specific tag.
  void setSelectedTag(String? tag) {
    if (_selectedTag != tag) {
      _selectedTag = tag;
      notifyListeners();
    }
  }

  /// Update search text query.
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  /// Change sorting criterion.
  void setSortOption(SortOption option) {
    if (_sortOption != option) {
      _sortOption = option;
      notifyListeners();
    }
  }

  /// Resets all filters back to default.
  void clearFilters() {
    _typeFilter = ItemTypeFilter.all;
    _selectedTag = null;
    _searchQuery = '';
    notifyListeners();
  }

  /// Opens the device file picker to select an image.
  /// Returns the file path or null if canceled.
  Future<String?> pickImageFile() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image);

      if (result.isNotEmpty) {
        final path = result.first.path;
        return path;
      }
    } catch (e) {
      debugPrint('[InboxViewModel] Error picking image: $e');
    }
    return null;
  }

}

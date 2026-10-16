import '../../domain/models/inbox_item.dart';

/// Abstract storage service interface for persisting inbox items locally.
abstract class StorageService {
  /// Loads all saved items from local storage.
  Future<List<InboxItem>> loadItems();

  /// Persists the complete list of items to local storage.
  Future<void> saveItems(List<InboxItem> items);

  Future<void> deleteItem(String id) async {
    final items = await loadItems();
    items.removeWhere((item) => item.id == id);
    await saveItems(items);
  }

  /// Clears all items from storage (used in testing or factory reset).
  Future<void> clear();
}

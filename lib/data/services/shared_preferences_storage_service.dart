import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/inbox_item.dart';
import 'storage_service.dart';

/// Concrete [StorageService] implementation backed by [SharedPreferences].
/// Persists inbox items locally across app relaunches on all supported platforms.
class SharedPreferencesStorageService implements StorageService {
  SharedPreferencesStorageService({this.preferences});

  static const String _storageKey = 'byte_task_inbox_items_v1';
  SharedPreferences? preferences;

  Future<SharedPreferences> _getPrefs() async {
    preferences ??= await SharedPreferences.getInstance();
    return preferences!;
  }

  @override
  Future<List<InboxItem>> loadItems() async {
    try {
      final prefs = await _getPrefs();
      final rawJsonString = prefs.getString(_storageKey);
      if (rawJsonString == null || rawJsonString.trim().isEmpty) {
        return [];
      }

      final decoded = jsonDecode(rawJsonString);
      if (decoded is! List) {
        debugPrint(
          '[StorageService] Stored items was not a JSON list: $decoded',
        );
        return [];
      }

      final items = <InboxItem>[];
      for (final element in decoded) {
        if (element is Map<String, dynamic>) {
          try {
            items.add(InboxItem.fromJson(element));
          } catch (e, stack) {
            debugPrint('[StorageService] Error deserializing item: $e\n$stack');
          }
        }
      }
      return items;
    } catch (e, stack) {
      debugPrint(
        '[StorageService] Failed to load items from SharedPreferences: $e\n$stack',
      );
      return [];
    }
  }

  @override
  Future<void> saveItems(List<InboxItem> items) async {
    try {
      final prefs = await _getPrefs();
      final mappedList = items.map((item) => item.toJson()).toList();
      final encodedJson = jsonEncode(mappedList);
      await prefs.setString(_storageKey, encodedJson);
    } catch (e, stack) {
      debugPrint(
        '[StorageService] Failed to save items to SharedPreferences: $e\n$stack',
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteItem(String id) async {
    final items = await loadItems();
    items.removeWhere((item) => item.id == id);
    await saveItems(items);
  }

  @override
  Future<void> clear() async {
    final prefs = await _getPrefs();
    await prefs.remove(_storageKey);
  }
}

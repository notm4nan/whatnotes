import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/inbox_item.dart';
import 'storage_service.dart';

/// Firestore-backed storage. Every query is scoped to the signed-in UID and
/// every write includes ownerId; Firestore rules enforce the same boundary.
class FirestoreStorageService implements StorageService {
  FirestoreStorageService({required this.ownerId, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final String ownerId;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _items =>
      _firestore.collection('items');

  Query<Map<String, dynamic>> get _ownedItems =>
      _items.where('ownerId', isEqualTo: ownerId);

  @override
  Future<List<InboxItem>> loadItems() async {
    final snapshot = await _ownedItems.get();
    return snapshot.docs.map((doc) => InboxItem.fromJson(doc.data())).toList();
  }

  @override
  Future<void> saveItems(List<InboxItem> items) async {
    final batch = _firestore.batch();
    for (final item in items) {
      final ref = _items.doc(item.id);
      batch.set(ref, {...item.toJson(), 'ownerId': ownerId});
    }
    await batch.commit();
  }

  Future<InboxItem> addItem(InboxItem item) async {
    final owned = item.copyWith(ownerId: ownerId);
    await _items.doc(owned.id).set({...owned.toJson(), 'ownerId': ownerId});
    return owned;
  }

  Future<InboxItem> updateItem(InboxItem item) async {
    final owned = item.copyWith(ownerId: ownerId);
    await _items.doc(owned.id).update({...owned.toJson(), 'ownerId': ownerId});
    return owned;
  }

  Future<InboxItem?> getById(String id) async {
    final doc = await _items.doc(id).get();
    if (!doc.exists || doc.data()?['ownerId'] != ownerId) return null;
    return InboxItem.fromJson(doc.data()!);
  }

  @override
  Future<void> deleteItem(String id) async {
    await _items.doc(id).delete();
  }

  @override
  Future<void> clear() async {
    final snapshot = await _ownedItems.get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreRecipesService {
  FirestoreRecipesService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<Map<String, dynamic>>> fetchRecipes({String collection = 'recipes'}) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _firestore.collection(collection).get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<({List<Map<String, dynamic>> items, String? lastId})> fetchRecipesPage({
    String collection = 'recipes',
    int limit = 10,
    String? startAfterId,
  }) async {
    Query<Map<String, dynamic>> q = _firestore
        .collection(collection)
        .orderBy(FieldPath.documentId)
        .limit(limit);
    if (startAfterId != null && startAfterId.isNotEmpty) {
      q = q.startAfter([startAfterId]);
    }
    final QuerySnapshot<Map<String, dynamic>> snapshot = await q.get();
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = snapshot.docs;
    final List<Map<String, dynamic>> items = docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
    final String? lastId = docs.isEmpty ? null : docs.last.id;
    return (items: items, lastId: lastId);
  }

  Future<List<String>> fetchCollectionStrings(String collection) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _firestore.collection(collection).get();
    return snapshot.docs.map((d) {
      final data = d.data();
      final Object? name = data['name'] ?? data['label'] ?? data['title'];
      return (name == null || name.toString().isEmpty) ? d.id : name.toString();
    }).toList();
  }
}



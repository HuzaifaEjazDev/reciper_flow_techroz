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

  Future<Map<String, dynamic>?> fetchRecipeById(String id, {String collection = 'recipes'}) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore.collection(collection).doc(id).get();
      if (!doc.exists) return null;
      final Map<String, dynamic>? data = doc.data();
      if (data == null) return null;
      data['id'] = doc.id;
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<({List<Map<String, dynamic>> items, String? lastId})> fetchRecipesPage({
    String collection = 'recipes',
    int limit = 10,
    String? startAfterId,
  })
  async {
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

  Future<({List<Map<String, dynamic>> items, String? lastTitle})> fetchRecipesPageByTitlePrefix({
    String collection = 'recipes',
    required String prefix,
    int limit = 10,
    String? startAfterTitle,
  })
  async {
    final String start = prefix;
    final String end = '$prefix\uf8ff';
    Query<Map<String, dynamic>> q = _firestore
        .collection(collection)
        .orderBy('title')
        .startAt([start])
        .endAt([end])
        .limit(limit);
    if (startAfterTitle != null && startAfterTitle.isNotEmpty) {
      q = q.startAfter([startAfterTitle]);
    }
    final QuerySnapshot<Map<String, dynamic>> snapshot = await q.get();
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = snapshot.docs;
    final List<Map<String, dynamic>> items = docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
    final String? lastTitle = docs.isEmpty ? null : (docs.last.data()['title']?.toString());
    return (items: items, lastTitle: lastTitle);
  }

  // method to fetch recipes with label filters
  Future<({List<Map<String, dynamic>> items, String? lastId})> fetchRecipesPageWithFilters({
    String collection = 'recipes',
    int limit = 10,
    String? startAfterId,
    String? mealType,
    String? diet,
    String? cuisine,
    String? tag,
  })
  async {
    Query<Map<String, dynamic>> q = _firestore.collection(collection).limit(limit);
    
    // Apply filters if provided
    if (mealType != null && mealType.isNotEmpty) {
      q = q.where('mealType', isEqualTo: mealType);
    }
    if (diet != null && diet.isNotEmpty) {
      q = q.where('diet', isEqualTo: diet);
    }
    if (cuisine != null && cuisine.isNotEmpty) {
      q = q.where('cuisine', isEqualTo: cuisine);
    }
    if (tag != null && tag.isNotEmpty) {
      // Assuming tags are stored in an array field called 'tags'
      q = q.where('tags', arrayContains: tag);
    }
    
    // Ordering and pagination
    q = q.orderBy(FieldPath.documentId);
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

  Future<int> fetchCollectionCountByTitlePrefix(String collection, String prefix) async {
    try {
      final String start = prefix;
      final String end = '$prefix\uf8ff';
      final AggregateQuerySnapshot snap = await _firestore
          .collection(collection)
          .orderBy('title')
          .startAt([start])
          .endAt([end])
          .count()
          .get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // method to filter recipe on lables cateogires
  Future<int> fetchCollectionCountWithFilters({
    String collection = 'recipes',
    String? mealType,
    String? diet,
    String? cuisine,
    String? tag,
  }) async {
    try {
      Query<Map<String, dynamic>> q = _firestore.collection(collection);
      
      // Apply filters if provided
      if (mealType != null && mealType.isNotEmpty) {
        q = q.where('mealType', isEqualTo: mealType);
      }
      if (diet != null && diet.isNotEmpty) {
        q = q.where('diet', isEqualTo: diet);
      }
      if (cuisine != null && cuisine.isNotEmpty) {
        q = q.where('cuisine', isEqualTo: cuisine);
      }
      if (tag != null && tag.isNotEmpty) {
        // Assuming tags are stored in an array field called 'tags'
        q = q.where('tags', arrayContains: tag);
      }
      
      final AggregateQuerySnapshot snap = await q.count().get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
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

  Future<int> fetchCollectionCount(String collection) async {
    try {
      final AggregateQuerySnapshot snap =
          await _firestore.collection(collection).count().get();
      return snap.count ?? 0;
    } catch (_) {
      // Fallback to full fetch if count aggregate not available
      final q = await _firestore.collection(collection).limit(1).get();
      // Not accurate without full scan; return at least docs length
      return q.docs.length; 
    }
  }

  Future<List<String>> fetchDocumentArray(String collection, String docId) async {
    try {
      final doc = await _firestore.collection(collection).doc(docId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          for (final key in const ['values', 'items', 'labels', 'options', 'list', 'data']) {
            final v = data[key];
            if (v is List) {
              return v.map((e) => e.toString()).toList();
            }
          }
          // Fallback: if any field is a List, use the first
          for (final entry in data.entries) {
            final v = entry.value;
            if (v is List) {
              return v.map((e) => e.toString()).toList();
            }
          }
          // Fallback: if the doc is a map of flags/labels: true, use keys
          final keys = <String>[];
          for (final entry in data.entries) {
            final val = entry.value;
            if (val is bool && val == true) keys.add(entry.key.toString());
          }
          if (keys.isNotEmpty) return keys;
        }
      }
    } catch (e) {
      print('Error fetching document array from $collection/$docId: $e');
    }
    return <String>[];
  }
}
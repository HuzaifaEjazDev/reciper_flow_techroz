import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipe_app/models/meal_plan.dart';

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
        .orderBy('titleLower') // Use titleLower field for case-insensitive search
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
    final String? lastTitle = docs.isEmpty ? null : (docs.last.data()['titleLower']?.toString());
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
          .orderBy('titleLower') // Use titleLower field for case-insensitive search
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

  // New methods for PlannedMeals schema
  // Save a planned meal directly in the PlannedMeals collection
  Future<String> savePlannedMeal(PlannedMeal plannedMeal) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final CollectionReference<Map<String, dynamic>> plannedMealsRef =
          _firestore.collection('users').doc(user.uid).collection('PlannedMeals');
      
      // First create a new doc ref to get an auto id
      final DocumentReference<Map<String, dynamic>> mealDoc = plannedMealsRef.doc();

      // Persist uniqueId inside document as a field
      final Map<String, dynamic> data = {
        ...plannedMeal.toFirestore(),
        'uniqueId': mealDoc.id,
      };

      await mealDoc.set(data);
      return mealDoc.id;
    } catch (e) {
      throw Exception('Error saving planned meal: $e');
    }
  }

  // Get all planned meals for a specific date
  Future<List<PlannedMeal>> getPlannedMealsForDate(String dateForRecipe) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final CollectionReference<Map<String, dynamic>> plannedMealsRef =
          _firestore.collection('users').doc(user.uid).collection('PlannedMeals');
      
      // Query all meals where dateForRecipe field matches
      final QuerySnapshot<Map<String, dynamic>> mealsSnapshot = await plannedMealsRef
          .where('dateForRecipe', isEqualTo: dateForRecipe)
          .get();
      
      return mealsSnapshot.docs.map((doc) {
        return PlannedMeal.fromFirestore(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Error fetching planned meals for date: $e');
    }
  }

  // Get all planned meals for a week (multiple dates)
  Future<Map<String, List<PlannedMeal>>> getPlannedMealsForWeek(List<String> dateKeys) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final CollectionReference<Map<String, dynamic>> plannedMealsRef =
          _firestore.collection('users').doc(user.uid).collection('PlannedMeals');
      
      // Query all meals where dateForRecipe is in the list of dateKeys
      final QuerySnapshot<Map<String, dynamic>> mealsSnapshot = await plannedMealsRef
          .where('dateForRecipe', whereIn: dateKeys)
          .get();
      
      // Group meals by datedateForRecipeKey
      final Map<String, List<PlannedMeal>> weekMeals = {};
      for (final dateForRecipe in dateKeys) {
        weekMeals[dateForRecipe] = [];
      }
      
      for (final doc in mealsSnapshot.docs) {
        final PlannedMeal meal = PlannedMeal.fromFirestore(doc.data(), doc.id);
        weekMeals[meal.dateForRecipe]?.add(meal);
      }
      
      return weekMeals;
    } catch (e) {
      throw Exception('Error fetching planned meals for week: $e');
    }
  }

  // Get all planned meals (for "Show All" functionality)
  Future<List<PlannedMeal>> getAllPlannedMeals() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final CollectionReference<Map<String, dynamic>> plannedMealsRef =
          _firestore.collection('users').doc(user.uid).collection('PlannedMeals');
      
      // Query all meals
      final QuerySnapshot<Map<String, dynamic>> mealsSnapshot = await plannedMealsRef.get();
      
      return mealsSnapshot.docs.map((doc) {
        return PlannedMeal.fromFirestore(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Error fetching all planned meals: $e');
    }
  }

  // Delete a planned meal
  Future<void> deletePlannedMeal(String mealId) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final CollectionReference<Map<String, dynamic>> plannedMealsRef =
          _firestore.collection('users').doc(user.uid).collection('PlannedMeals');
      
      await plannedMealsRef.doc(mealId).delete();
    } catch (e) {
      throw Exception('Error deleting planned meal: $e');
    }
  }

  // Update a planned meal
  Future<void> updatePlannedMeal(String mealId, PlannedMeal updatedMeal) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final CollectionReference<Map<String, dynamic>> plannedMealsRef =
          _firestore.collection('users').doc(user.uid).collection('PlannedMeals');
      
      await plannedMealsRef.doc(mealId).update(updatedMeal.toFirestore());
    } catch (e) {
      throw Exception('Error updating planned meal: $e');
    }
  }

  // Helper method to format date as "D MMM" (e.g., "2 Oct", "7 Oct")
  String formatDateKey(DateTime date) {
    const List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  // Save a user-created recipe to the RecipesCreatedByUser sub-collection
  Future<String> saveUserCreatedRecipe({
    required String title,
    required List<Map<String, dynamic>> ingredients,
    required List<String> steps,
    int minutes = 0, // Add minutes parameter
  }) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final CollectionReference<Map<String, dynamic>> userRecipesRef =
          _firestore.collection('users').doc(user.uid).collection('RecipesCreatedByUser');
      
      // Create the recipe data
      final Map<String, dynamic> recipeData = {
        'title': title,
        'imageUrl': 'assets/images/vegitables.jpg',
        'ingredients': ingredients,
        'steps': steps,
        'minutes': minutes, // Add minutes to recipe data
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'userId': user.uid,
      };

      // Add the document and get the ID
      final DocumentReference<Map<String, dynamic>> docRef = await userRecipesRef.add(recipeData);
      return docRef.id;
    } catch (e) {
      throw Exception('Error saving user-created recipe: $e');
    }
  }

  // ===================
  // GroceryRecipes (per user)
  // ===================

  Future<String> saveGroceryRecipe({
    required String title,
    required String imageUrl,
    int minutes = 0,
    required String dateKey, // e.g., formatDateKey(DateTime.now())
    required int servings,
    required List<Map<String, dynamic>> ingredients, // [{name, quantity, isChecked:false}]
  }) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final CollectionReference<Map<String, dynamic>> col = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('GroceryRecipes');
    final DocumentReference<Map<String, dynamic>> docRef = col.doc();
    await docRef.set({
      'title': title,
      'imageUrl': imageUrl,
      'minutes': minutes,
      'dateKey': dateKey,
      'servings': servings,
      'ingredients': ingredients,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
    return docRef.id;
  }

  Future<List<Map<String, dynamic>>> fetchGroceryRecipesByDate(String dateKey) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return <Map<String, dynamic>>[];
    final QuerySnapshot<Map<String, dynamic>> q = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('GroceryRecipes')
        .where('dateKey', isEqualTo: dateKey)
        .get();
    return q.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  Future<List<Map<String, dynamic>>> fetchAllGroceryRecipes() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return <Map<String, dynamic>>[];
    final QuerySnapshot<Map<String, dynamic>> q = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('GroceryRecipes')
        .get();
    return q.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  Future<void> toggleGroceryIngredientChecked({
    required String groceryId,
    required int ingredientIndex,
    required bool isChecked,
  }) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final DocumentReference<Map<String, dynamic>> docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('GroceryRecipes')
        .doc(groceryId);
    final DocumentSnapshot<Map<String, dynamic>> snap = await docRef.get();
    if (!snap.exists) return;
    final data = snap.data();
    if (data == null) return;
    final List<dynamic> ingredients = (data['ingredients'] as List<dynamic>? ?? <dynamic>[]);
    if (ingredientIndex < 0 || ingredientIndex >= ingredients.length) return;
    final dynamic item = ingredients[ingredientIndex];
    if (item is Map<String, dynamic>) {
      ingredients[ingredientIndex] = {
        ...item,
        'isChecked': isChecked,
      };
      await docRef.update({'ingredients': ingredients});
    }
  }

  /// Update the entire ingredients list for a grocery recipe
  Future<void> updateGroceryRecipeIngredients(String groceryId, List<Map<String, dynamic>> updatedIngredients) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final DocumentReference<Map<String, dynamic>> docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('GroceryRecipes')
        .doc(groceryId);
    await docRef.update({'ingredients': updatedIngredients});
  }

  /// Delete an entire grocery recipe document
  Future<void> deleteGroceryRecipe(String groceryId) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final DocumentReference<Map<String, dynamic>> docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('GroceryRecipes')
        .doc(groceryId);
    await docRef.delete();
  }

  // ===================
  // Bookmarks (per user, server-only)
  // ===================

  Future<void> toggleBookmark({
    required String recipeId,
    required String title,
    required String imageUrl,
    int minutes = 0,
  }) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final DocumentReference<Map<String, dynamic>> docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('BookMarkedRecipes')
        .doc(recipeId);
    final DocumentSnapshot<Map<String, dynamic>> snap = await docRef.get();
    if (snap.exists) {
      await docRef.delete();
    } else {
      await docRef.set({
        'recipeId': recipeId,
        'title': title,
        'titleLower': title.toLowerCase(),
        'imageUrl': imageUrl,
        'minutes': minutes,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
    }
  }

  Stream<bool> isBookmarkedStream(String recipeId) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream<bool>.empty();
    }
    final DocumentReference<Map<String, dynamic>> docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('BookMarkedRecipes')
        .doc(recipeId);
    return docRef.snapshots().map((s) => s.exists);
  }

  Future<({List<Map<String, dynamic>> items, String? lastId})> fetchBookmarksPage({
    int limit = 10,
    String? startAfterId,
  }) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return (items: <Map<String, dynamic>>[], lastId: null);
    }
    Query<Map<String, dynamic>> q = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('BookMarkedRecipes')
        .orderBy(FieldPath.documentId)
        .limit(limit);
    if (startAfterId != null && startAfterId.isNotEmpty) {
      q = q.startAfter([startAfterId]);
    }
    final QuerySnapshot<Map<String, dynamic>> snapshot = await q.get();
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = snapshot.docs;
    final List<Map<String, dynamic>> items = docs.map((d) {
      final data = d.data();
      data['id'] = d.id; // same as recipeId
      return data;
    }).toList();
    final String? lastId = docs.isEmpty ? null : docs.last.id;
    return (items: items, lastId: lastId);
  }

  Future<int> fetchBookmarksCount() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    try {
      final AggregateQuerySnapshot snap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('BookMarkedRecipes')
          .count()
          .get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<({List<Map<String, dynamic>> items, String? lastTitle})> fetchBookmarksPageByTitlePrefix({
    int limit = 10,
    String? startAfterTitle,
    required String prefix,
  }) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return (items: <Map<String, dynamic>>[], lastTitle: null);
    }
    final String lp = prefix.toLowerCase();
    final String start = lp;
    final String endExclusive = '$lp\uf8ff';
    Query<Map<String, dynamic>> q = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('BookMarkedRecipes')
        .orderBy('titleLower')
        .where('titleLower', isGreaterThanOrEqualTo: start)
        .where('titleLower', isLessThan: endExclusive)
        .limit(limit);
    if (startAfterTitle != null && startAfterTitle.isNotEmpty) {
      q = q.startAfter([startAfterTitle.toLowerCase()]);
    }
    QuerySnapshot<Map<String, dynamic>> snapshot = await q.get();
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = snapshot.docs;
    if (docs.isEmpty) {
      // Fallback to legacy 'title' if lower index/field missing
      final String s2 = prefix;
      final String e2 = '$prefix\uf8ff';
      Query<Map<String, dynamic>> q2 = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('BookMarkedRecipes')
          .orderBy('title')
          .where('title', isGreaterThanOrEqualTo: s2)
          .where('title', isLessThan: e2)
          .limit(limit);
      if (startAfterTitle != null && startAfterTitle.isNotEmpty) {
        q2 = q2.startAfter([startAfterTitle]);
      }
      snapshot = await q2.get();
      docs = snapshot.docs;
    }
    final List<Map<String, dynamic>> items = docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return data;
    }).toList();
    final String? lastTitle = docs.isEmpty
        ? null
        : (docs.last.data()['titleLower']?.toString() ?? docs.last.data()['title']?.toString());
    return (items: items, lastTitle: lastTitle);
  }

  Future<int> fetchBookmarksCountByTitlePrefix(String prefix) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    try {
      final String lp = prefix.toLowerCase();
      final String start = lp;
      final String endExclusive = '$lp\uf8ff';
      AggregateQuerySnapshot snap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('BookMarkedRecipes')
          .orderBy('titleLower')
          .where('titleLower', isGreaterThanOrEqualTo: start)
          .where('titleLower', isLessThan: endExclusive)
          .count()
          .get();
      int count = snap.count ?? 0;
      if (count == 0) {
        final String s2 = prefix;
        final String e2 = '$prefix\uf8ff';
        snap = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('BookMarkedRecipes')
            .orderBy('title')
            .where('title', isGreaterThanOrEqualTo: s2)
            .where('title', isLessThan: e2)
            .count()
            .get();
        count = snap.count ?? 0;
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  // Add this new method for fetching user-created recipes with pagination
  Future<({List<Map<String, dynamic>> items, String? lastId})> fetchUserRecipesPage({
    int limit = 10,
    String? startAfterId,
  }) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return (items: <Map<String, dynamic>>[], lastId: null);
    }
    
    Query<Map<String, dynamic>> q = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('RecipesCreatedByUser')
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

  // Add this new method for counting user-created recipes
  Future<int> fetchUserRecipesCount() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    
    try {
      final AggregateQuerySnapshot snap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('RecipesCreatedByUser')
          .count()
          .get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // Add this new method for fetching user-created recipes with title prefix search
  Future<({List<Map<String, dynamic>> items, String? lastTitle})> fetchUserRecipesPageByTitlePrefix({
    int limit = 10,
    String? startAfterTitle,
    required String prefix,
  }) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return (items: <Map<String, dynamic>>[], lastTitle: null);
    }
    
    final String lp = prefix.toLowerCase();
    final String start = lp;
    final String endExclusive = '$lp\uf8ff';
    
    Query<Map<String, dynamic>> q = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('RecipesCreatedByUser')
        .orderBy('titleLower')
        .where('titleLower', isGreaterThanOrEqualTo: start)
        .where('titleLower', isLessThan: endExclusive)
        .limit(limit);
        
    if (startAfterTitle != null && startAfterTitle.isNotEmpty) {
      q = q.startAfter([startAfterTitle.toLowerCase()]);
    }
    
    QuerySnapshot<Map<String, dynamic>> snapshot = await q.get();
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = snapshot.docs;
    
    // Fallback to legacy 'title' if lower index/field missing
    if (docs.isEmpty) {
      final String s2 = prefix;
      final String e2 = '$prefix\uf8ff';
      Query<Map<String, dynamic>> q2 = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('RecipesCreatedByUser')
          .orderBy('title')
          .where('title', isGreaterThanOrEqualTo: s2)
          .where('title', isLessThan: e2)
          .limit(limit);
          
      if (startAfterTitle != null && startAfterTitle.isNotEmpty) {
        q2 = q2.startAfter([startAfterTitle]);
      }
      
      snapshot = await q2.get();
      docs = snapshot.docs;
    }
    
    final List<Map<String, dynamic>> items = docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
    
    final String? lastTitle = docs.isEmpty
        ? null
        : (docs.last.data()['titleLower']?.toString() ?? docs.last.data()['title']?.toString());
        
    return (items: items, lastTitle: lastTitle);
  }

  // Add this new method for counting user-created recipes with title prefix search
  Future<int> fetchUserRecipesCountByTitlePrefix(String prefix) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    
    try {
      final String lp = prefix.toLowerCase();
      final String start = lp;
      final String endExclusive = '$lp\uf8ff';
      
      AggregateQuerySnapshot snap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('RecipesCreatedByUser')
          .orderBy('titleLower')
          .where('titleLower', isGreaterThanOrEqualTo: start)
          .where('titleLower', isLessThan: endExclusive)
          .count()
          .get();
          
      int count = snap.count ?? 0;
      
      // Fallback to legacy 'title' if lower index/field missing
      if (count == 0) {
        final String s2 = prefix;
        final String e2 = '$prefix\uf8ff';
        snap = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('RecipesCreatedByUser')
            .orderBy('title')
            .where('title', isGreaterThanOrEqualTo: s2)
            .where('title', isLessThan: e2)
            .count()
            .get();
        count = snap.count ?? 0;
      }
      
      return count;
    } catch (_) {
      return 0;
    }
  }
}
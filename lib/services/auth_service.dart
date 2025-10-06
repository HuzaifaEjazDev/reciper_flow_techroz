import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/models/meal_plan.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  // Register with email and password and store user data in Firestore
  Future<User?> createUserWithEmailAndPassword(String email, String password, {String? name}) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Store user data in Firestore
      if (result.user != null) {
        // Update Firebase Auth display name if provided
        if (name != null && name.isNotEmpty) {
          await result.user!.updateDisplayName(name);
        }
        await _firestore.collection('users').doc(result.user!.uid).set({
          'uid': result.user!.uid,
          'email': email,
          if (name != null && name.isNotEmpty) 'name': name,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  // Store a meal plan for the current user under PlannedMeals subcollection
  Future<void> saveMealPlan(DayPlan dayPlan) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Create a reference to the user's PlannedMeals subcollection
      final CollectionReference plannedMealsRef = 
          _firestore.collection('users').doc(user.uid).collection('PlannedMeals');
      
      // Format date as "D MMM" (e.g., "4 Aug", "6 Aug")
      final String dateForRecipe = '${dayPlan.date.day} ${_getMonthName(dayPlan.date.month)}';
      
      // Create or update the document for this date
      final DocumentReference dateDoc = plannedMealsRef.doc(dateForRecipe);
      
      // Save each meal entry under the date document with meal type as document ID
      for (final meal in dayPlan.meals) {
        await dateDoc.collection(meal.type).doc().set({
          'uid': user.uid,
          'idOfRecipe': meal.id,
          'time': meal.time,
          'date': dayPlan.date,
          'Persons': meal.people,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get meal plans for the current user from PlannedMeals subcollection
  Future<List<DayPlan>> getUserMealPlans() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get all planned meals for this user
      final QuerySnapshot plannedMealsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('PlannedMeals')
          .get();

      // This would need to be implemented based on how you want to retrieve and reconstruct DayPlan objects
      // For now, returning empty list as this requires more complex logic to reconstruct from the new structure
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Helper method to get month name abbreviation
  String _getMonthName(int month) {
    const List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Update display name for current user and Firestore
  Future<void> updateDisplayName(String name) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    await user.updateDisplayName(name);
    await _firestore.collection('users').doc(user.uid).set({
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Delete current user account and Firestore user doc
  Future<void> deleteAccount() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    try {
      // Best effort: delete Firestore user doc first
      await _firestore.collection('users').doc(user.uid).delete().catchError((_) {});
      // Delete auth user (may require recent login)
      await user.delete();
    } on FirebaseAuthException catch (e) {
      // Propagate to caller for UX handling (e.g., re-auth required)
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}
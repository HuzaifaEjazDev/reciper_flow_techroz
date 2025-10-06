import 'package:cloud_firestore/cloud_firestore.dart';

class UserCreatedRecipe {
  final String id;
  final String title;
  final String imageUrl;
  final List<Map<String, dynamic>> ingredients;
  final List<String> steps;
  final DateTime createdAt;
  final String userId;
  final int minutes; // Add minutes field

  UserCreatedRecipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.ingredients,
    required this.steps,
    required this.createdAt,
    required this.userId,
    this.minutes = 0, // Add minutes parameter with default value
  });

  factory UserCreatedRecipe.fromFirestore(Map<String, dynamic> data, String documentId) {
    return UserCreatedRecipe(
      id: documentId,
      title: data['title'] ?? '',
      imageUrl: data['imageUrl'] ?? 'assets/images/vegitables.jpg',
      ingredients: data['ingredients'] is List ? List<Map<String, dynamic>>.from(data['ingredients']) : [],
      steps: data['steps'] is List ? List<String>.from(data['steps']) : [],
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
      userId: data['userId'] ?? '',
      minutes: data['minutes'] is int ? data['minutes'] : 0, // Add minutes from Firestore
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'imageUrl': imageUrl,
      'ingredients': ingredients,
      'steps': steps,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'minutes': minutes, // Add minutes to Firestore
    };
  }
}
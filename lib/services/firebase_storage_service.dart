import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads an image file to Firebase Storage and returns the URL of the uploaded image
  static Future<String> uploadImage(String imagePath) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create a reference to the file in Firebase Storage
      // Use user ID as folder name to organize images by user
      final String fileName = path.basename(imagePath);
      final String fileExtension = path.extension(fileName);
      final String uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      final Reference storageRef = _storage.ref()
          .child('user_recipe_images')
          .child(user.uid)
          .child(uniqueFileName);

      // Upload the file
      final UploadTask uploadTask = storageRef.putFile(File(imagePath));
      final TaskSnapshot snapshot = await uploadTask;

      // Get the download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image to Firebase Storage: $e');
    }
  }
}
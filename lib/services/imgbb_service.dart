import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ImgbbService {
  static const String _apiKey = 'c48054475b73e25bd38da2a2fc436e56';
  static const String _apiUrl = 'https://api.imgbb.com/1/upload';

  /// Uploads an image file to imgbb and returns the URL of the uploaded image
  static Future<String> uploadImage(String imagePath) async {
    final uri = Uri.parse('$_apiUrl?key=$_apiKey');
    
    final request = http.MultipartRequest('POST', uri);
    
    // Add the image file to the request
    final file = await http.MultipartFile.fromPath('image', imagePath);
    request.files.add(file);
    
    // Send the request
    final response = await request.send();
    
    // Get the response as a string
    final responseBody = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      // Parse the JSON response
      final jsonResponse = json.decode(responseBody);
      
      // Check if the upload was successful
      if (jsonResponse['success'] == true) {
        // Return the URL of the uploaded image
        return jsonResponse['data']['url'];
      } else {
        throw Exception('Image upload failed: ${jsonResponse['error']['message']}');
      }
    } else {
      throw Exception('Image upload failed with status code: ${response.statusCode}');
    }
  }
}
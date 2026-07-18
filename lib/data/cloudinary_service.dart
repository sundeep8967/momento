import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  static Future<String> uploadRawVideo(String localFilePath) async {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME']!;
    final apiKey = dotenv.env['CLOUDINARY_API_KEY']!;
    final apiSecret = dotenv.env['CLOUDINARY_API_SECRET']!;

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/video/upload');
    
    // Cloudinary requires timestamp in seconds
    final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
    
    // Create signature: sha1("timestamp=$timestamp" + apiSecret)
    final signatureStr = 'timestamp=$timestamp$apiSecret';
    final signature = sha1.convert(utf8.encode(signatureStr)).toString();
    
    final request = http.MultipartRequest('POST', uri)
      ..fields['api_key'] = apiKey
      ..fields['timestamp'] = timestamp
      ..fields['signature'] = signature
      ..files.add(await http.MultipartFile.fromPath('file', localFilePath));
      
    final response = await request.send();
    
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final jsonMap = jsonDecode(respStr);
      return jsonMap['secure_url']; // The direct video URL
    } else {
      final err = await response.stream.bytesToString();
      throw Exception('Failed to upload video to Cloudinary: ${response.statusCode} - $err');
    }
  }

  static Future<String> uploadImage(String localFilePath) async {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME']!;
    final apiKey = dotenv.env['CLOUDINARY_API_KEY']!;
    final apiSecret = dotenv.env['CLOUDINARY_API_SECRET']!;

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    
    // Cloudinary requires timestamp in seconds
    final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
    
    // Create signature: sha1("timestamp=$timestamp" + apiSecret)
    final signatureStr = 'timestamp=$timestamp$apiSecret';
    final signature = sha1.convert(utf8.encode(signatureStr)).toString();
    
    final request = http.MultipartRequest('POST', uri)
      ..fields['api_key'] = apiKey
      ..fields['timestamp'] = timestamp
      ..fields['signature'] = signature
      ..files.add(await http.MultipartFile.fromPath('file', localFilePath));
      
    final response = await request.send();
    
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final jsonMap = jsonDecode(respStr);
      return jsonMap['secure_url']; // The direct image URL
    } else {
      final err = await response.stream.bytesToString();
      throw Exception('Failed to upload image to Cloudinary: ${response.statusCode} - $err');
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

/// Service class for RAG (Retrieval-Augmented Generation) communication with FastAPI backend
/// 
/// IMPORTANT FOR MOBILE DEVICES:
/// - localhost/127.0.0.1 will NOT work on mobile devices
/// - Use your computer's local IP address instead (e.g., 192.168.1.100:8080)
/// - Find your IP: Windows (ipconfig), Mac/Linux (ifconfig), or check router settings
/// - Make sure your phone and computer are on the same WiFi network
class RagService {
  // Base URL for FastAPI backend
  // For desktop/web: use 'http://localhost:8080'
  // For mobile: replace with your computer's local IP (e.g., 'http://192.168.1.100:8080')
  // You can also make this configurable via settings or environment variables
  static const String _baseUrl = 'http://192.168.11.142:8000';
  
  // Alternative: Use platform detection to automatically switch
  // Uncomment the following and use _getBaseUrl() instead of _baseUrl:
  /*
  static String _getBaseUrl() {
    if (Platform.isAndroid || Platform.isIOS) {
      // For mobile, you need to set this to your computer's IP
      // Example: return 'http://192.168.1.100:8080';
      // You could also read this from a config file or user settings
      return 'http://YOUR_COMPUTER_IP:8080'; // Replace with your actual IP
    }
    return 'http://localhost:8080';
  }
  */

  /// Upload a document to FastAPI backend
  /// 
  /// Expected FastAPI endpoint: POST /upload
  /// Expected request: multipart/form-data with file
  /// Expected response: JSON with success status
  Future<Map<String, dynamic>> uploadDocument(PlatformFile file) async {
    try {
      // Get file bytes
      Uint8List? fileBytes = file.bytes;
      if (fileBytes == null && file.path != null) {
        final fileObj = File(file.path!);
        fileBytes = await fileObj.readAsBytes();
      }

      if (fileBytes == null) {
        throw Exception('Unable to read file data');
      }

      // Create multipart request
      final uri = Uri.parse('$_baseUrl/upload');
      final request = http.MultipartRequest('POST', uri);

      // Add file to request with the correct field name 'files'
      request.files.add(
        http.MultipartFile.fromBytes(
          'files', // Changed to 'files' to match FastAPI's expected field name
          fileBytes,
          filename: file.name,
        ),
      );

      // Add any additional fields if needed
      // request.fields['key'] = 'value';

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Parse response
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          return json.decode(response.body) as Map<String, dynamic>;
        } catch (e) {
          return {
            'success': true,
            'message': 'File uploaded successfully',
            'raw_response': response.body,
          };
        }
      } else {
        throw Exception(
          'Upload failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  /// Send a prompt/question to FastAPI RAG endpoint
  /// 
  /// Expected FastAPI endpoint: POST /ask
  /// Expected request: JSON with 'prompt' and 'model' fields
  /// Expected response: JSON with 'response' field
  Future<Map<String, dynamic>> askQuestion({
    required String prompt,
    required String model,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/ask');
      
      // Prepare request body
      final requestBody = json.encode({
          'question': prompt,
          'model_choice': model,
      });

      // Send POST request
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      // Parse response
      if (response.statusCode == 200) {
        try {
          return json.decode(response.body) as Map<String, dynamic>;
        } catch (e) {
          return {
            'success': true,
            'response': response.body,
          };
        }
      } else {
        throw Exception(
          'Request failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      // Handle connection errors (e.g., backend not running, network issues)
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused')) {
        throw Exception(
          'Cannot connect to backend. Make sure FastAPI is running on $_baseUrl\n'
          'For mobile devices, use your computer\'s IP address instead of localhost.',
        );
      }
      throw Exception('Failed to send question: $e');
    }
  }

  /// Reset the RAG session
  /// 
  /// Expected FastAPI endpoint: POST /reset
  /// Expected response: JSON with success status
  Future<Map<String, dynamic>> resetSession() async {
    try {
      final uri = Uri.parse('$_baseUrl/reset');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        try {
          return json.decode(response.body) as Map<String, dynamic>;
        } catch (e) {
          return {
            'success': true,
            'message': 'Session reset successfully',
          };
        }
      } else {
        throw Exception(
          'Reset failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to reset session: $e');
    }
  }

  /// Get the base URL (useful for debugging)
  String get baseUrl => _baseUrl;
}


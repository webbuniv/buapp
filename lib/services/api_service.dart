import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:buapp/utils/constants.dart';

class ApiService {
  static final String _baseUrl = Constants.apiBaseUrl;
  
  // Helper method for GET requests
  static Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: headers ?? {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
  
  // Helper method for POST requests
  static Future<dynamic> post(String endpoint, dynamic data, {Map<String, String>? headers}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: headers ?? {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to post data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
  
  // Helper method for PUT requests
  static Future<dynamic> put(String endpoint, dynamic data, {Map<String, String>? headers}) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/$endpoint'),
        body: json.encode(data),
        headers: headers ?? {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
  
  // Helper method for DELETE requests
  static Future<dynamic> delete(String endpoint, {Map<String, String>? headers}) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: headers ?? {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception('Failed to delete data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
  
  // Moodle API integration
  static Future<dynamic> getMoodleCourses(String token, String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.moodleApiUrl}/webservice/rest/server.php?wstoken=$token&wsfunction=core_course_get_enrolled_courses_by_timeline_classification&classification=all&moodlewsrestformat=json'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load Moodle courses: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
  
  // Library API integration
  static Future<dynamic> getLibraryBooks(String query, {int page = 1, int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.libraryApiUrl}/books?query=$query&page=$page&limit=$limit'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load library books: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}


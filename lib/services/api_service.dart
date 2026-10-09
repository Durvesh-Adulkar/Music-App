import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/track_model.dart';

class ApiService {
  // Provided Jamendo API Client ID
  static const String clientId = 'bc66595a';
  static const String baseUrl = 'https://api.jamendo.com/v3.0';

  // Fetch a list of tracks with pagination and 8s timeout
  Future<List<Track>> fetchTracks({int limit = 20, int offset = 0}) async {
    final url = Uri.parse(
      '$baseUrl/tracks/?client_id=$clientId&format=json&limit=$limit&offset=$offset',
    );
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null) {
          return (data['results'] as List)
              .map((json) => Track.fromJson(json))
              .toList();
        }
      }
    } catch (e) {
      rethrow;
    }
    return [];
  }

  // Search for tracks with pagination and 8s timeout
  Future<List<Track>> searchTracks({
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    final encodedQuery = Uri.encodeComponent(query.trim());
    final url = Uri.parse(
      '$baseUrl/tracks/?client_id=$clientId&format=json&namesearch=$encodedQuery&limit=$limit&offset=$offset',
    );
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null) {
          return (data['results'] as List)
              .map((json) => Track.fromJson(json))
              .toList();
        }
      }
    } catch (e) {
      rethrow;
    }
    return [];
  }
}

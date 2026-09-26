import 'dart:convert';

import 'package:http/http.dart' as http;

class ExerciseApi {
  static const String baseUrl =
      'https://oss.exercisedb.dev/api/v1';

  static Future<Map<String, dynamic>?> getExerciseByName(
    String name,
  ) async {
    try {
      final encodedName = Uri.encodeComponent(name.trim());

      final response = await http.get(
        Uri.parse(
          '$baseUrl/exercises/name/$encodedName',
        ),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is List && decoded.isNotEmpty) {
        final first = decoded.first;

        if (first is Map) {
          return Map<String, dynamic>.from(first);
        }
      }

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}
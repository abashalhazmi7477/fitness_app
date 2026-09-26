import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl =
      'https://lqvqomlswivsplzvbpwq.supabase.co';

  static const String supabasePublishableKey =
      'sb_publishable_iUdzoW80mYO-PIKAfwjheA_LbU2olxV';

  static Map<String, String> get headers {
    final headers = <String, String>{
      'apikey': supabasePublishableKey,
      'Content-Type': 'application/json',
      'Prefer': 'return=representation',
    };

    try {
      final session =
          Supabase.instance.client.auth.currentSession;

      final accessToken = session?.accessToken;

      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
    } catch (_) {
      // إذا لم تكن جلسة Supabase متاحة،
      // نستخدم apikey فقط.
    }

    return headers;
  }

  static Future<List<Map<String, dynamic>>> get(
    String table, {
    String? query,
  }) async {
    final uri = Uri.parse(
      '$supabaseUrl/rest/v1/$table${query ?? ''}',
    );

    final response = await http.get(
      uri,
      headers: headers,
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (response.body.isEmpty) {
        return [];
      }

      final data = jsonDecode(response.body);

      if (data is List) {
        return data
            .map(
              (item) =>
                  Map<String, dynamic>.from(item),
            )
            .toList();
      }

      return [];
    }

    throw Exception(
      'Supabase GET Error '
      '${response.statusCode}: ${response.body}',
    );
  }

  static Future<Map<String, dynamic>> post(
    String table,
    Map<String, dynamic> data,
  ) async {
    final uri = Uri.parse(
      '$supabaseUrl/rest/v1/$table',
    );

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }

      final decoded = jsonDecode(response.body);

      if (decoded is List &&
          decoded.isNotEmpty) {
        return Map<String, dynamic>.from(
          decoded.first,
        );
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(
          decoded,
        );
      }

      return {};
    }

    throw Exception(
      'Supabase POST Error '
      '${response.statusCode}: ${response.body}',
    );
  }

  static Future<void> update(
    String table,
    String filter,
    Map<String, dynamic> data,
  ) async {
    final uri = Uri.parse(
      '$supabaseUrl/rest/v1/$table?$filter',
    );

    final response = await http.patch(
      uri,
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Supabase PATCH Error '
        '${response.statusCode}: ${response.body}',
      );
    }
  }

  static Future<void> delete(
    String table,
    String filter,
  ) async {
    final uri = Uri.parse(
      '$supabaseUrl/rest/v1/$table?$filter',
    );

    final response = await http.delete(
      uri,
      headers: headers,
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Supabase DELETE Error '
        '${response.statusCode}: ${response.body}',
      );
    }
  }
}
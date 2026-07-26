import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import 'partner_token.dart';

/// Thin HTTP wrapper around the FarmFresh backend `/partner/*` API.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// Called on any 401 so the app can drop back to login.
  static void Function()? onUnauthorized;

  final http.Client _client;
  final String _baseUrl;
  static const _timeout = Duration(seconds: 20);

  Map<String, String> get _headers {
    final h = {'Content-Type': 'application/json'};
    final token = PartnerToken.value;
    if (token != null && token.isNotEmpty) h['Authorization'] = 'Bearer $token';
    return h;
  }

  Future<dynamic> getJson(String path, [Map<String, String>? query]) async {
    final uri = Uri.parse('$_baseUrl$path').replace(
      queryParameters: (query?.isEmpty ?? true) ? null : query,
    );
    final res = await _client.get(uri, headers: _headers).timeout(_timeout);
    return _decode(res, uri);
  }

  Future<dynamic> postJson(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$path');
    final res = await _client
        .post(uri, headers: _headers, body: jsonEncode(body))
        .timeout(_timeout);
    return _decode(res, uri);
  }

  Future<dynamic> putJson(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$path');
    final res = await _client
        .put(uri, headers: _headers, body: jsonEncode(body))
        .timeout(_timeout);
    return _decode(res, uri);
  }

  dynamic _decode(http.Response res, Uri uri) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isEmpty ? null : jsonDecode(res.body);
    }
    if (res.statusCode == 401) {
      PartnerToken.value = null;
      onUnauthorized?.call();
    }
    // Surface the server's { error } message when present.
    String message = 'Request failed (${res.statusCode})';
    try {
      final j = jsonDecode(res.body);
      if (j is Map && j['error'] is String) message = j['error'] as String;
    } catch (_) {}
    throw ApiException(res.statusCode, message);
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => message;
}

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import 'auth_token.dart';

/// Thin HTTP wrapper around the FarmFresh backend. Centralises the base URL,
/// JSON decoding, timeouts and error handling for the remote repositories.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// Called when any request returns 401, so the app can clear an
  /// invalid/expired session and drop back to guest. Set in main().
  static void Function()? onUnauthorized;

  final http.Client _client;
  final String _baseUrl;
  static const _timeout = Duration(seconds: 15);

  /// Base headers, plus the auth token when the user is signed in.
  Map<String, String> get _headers {
    final h = {'Content-Type': 'application/json'};
    final token = AuthToken.value;
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Future<dynamic> getJson(String path,
      [Map<String, String>? query]) async {
    final uri = Uri.parse('$_baseUrl$path').replace(
      queryParameters: query?.isEmpty ?? true ? null : query,
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

  Future<void> deleteJson(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final res = await _client.delete(uri, headers: _headers).timeout(_timeout);
    _decode(res, uri);
  }

  dynamic _decode(http.Response res, Uri uri) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isEmpty ? null : jsonDecode(res.body);
    }
    if (res.statusCode == 401) {
      AuthToken.value = null;
      onUnauthorized?.call();
    }
    throw ApiException(res.statusCode, uri.toString(), res.body);
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.url, this.body);
  final int statusCode;
  final String url;
  final String body;

  @override
  String toString() => 'ApiException($statusCode) $url';
}

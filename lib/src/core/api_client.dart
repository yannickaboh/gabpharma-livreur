import 'dart:convert';
import 'dart:io';

import 'app_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

String _extractErrorMessage(dynamic decoded) {
  if (decoded is Map) {
    final detail = decoded['detail'];
    if (detail is String && detail.isNotEmpty) return detail;
    for (final value in decoded.values) {
      if (value is String && value.isNotEmpty) return value;
      if (value is List && value.isNotEmpty) {
        final first = value.first;
        if (first is String) return first;
        if (first is Map && first['message'] is String) {
          return first['message'] as String;
        }
      }
      if (value is Map) {
        final nested = _extractErrorMessage(value);
        if (nested != 'Une erreur est survenue.') return nested;
      }
    }
  }
  return 'Une erreur est survenue.';
}

class ApiClient {
  ApiClient({HttpClient? httpClient}) : _httpClient = httpClient ?? HttpClient();

  final HttpClient _httpClient;
  String? accessToken;

  Future<Map<String, dynamic>> getJson(String path) => _send('GET', path);

  Future<Map<String, dynamic>> postJson(String path, [Map<String, dynamic>? body]) =>
      _send('POST', path, body: body);

  Future<Map<String, dynamic>> patchJson(String path, Map<String, dynamic> body) =>
      _send('PATCH', path, body: body);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final request = await _httpClient.openUrl(
      method,
      Uri.parse('${AppConfig.apiBaseUrl}$path'),
    );
    request.headers.contentType = ContentType.json;
    if (accessToken case final token?) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    if (body != null) {
      // dart:io defaults to Transfer-Encoding: chunked when the byte length
      // isn't set explicitly before writing — Django's dev server (wsgiref)
      // rejects chunked request bodies outright, so the Content-Length must
      // be fixed up front rather than left to be inferred.
      final encoded = utf8.encode(jsonEncode(body));
      request.headers.contentLength = encoded.length;
      request.add(encoded);
    } else {
      request.headers.contentLength = 0;
    }

    final response = await request.close();
    final raw = await utf8.decoder.bind(response).join();
    final dynamic decoded = raw.isEmpty ? <String, dynamic>{} : jsonDecode(raw);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final code = decoded is Map ? decoded['code'] as String? : null;
      throw ApiException(
        _extractErrorMessage(decoded),
        statusCode: response.statusCode,
        code: code,
      );
    }
    return decoded is Map ? Map<String, dynamic>.from(decoded) : <String, dynamic>{};
  }

  void close() => _httpClient.close(force: true);
}

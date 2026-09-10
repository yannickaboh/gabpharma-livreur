import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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

  /// Appelé quand une requête authentifiée reçoit un 401 et qu'un
  /// rafraîchissement (via [onRefreshToken]) n'a pas résolu le problème —
  /// c'est le vrai abandon (déconnexion).
  void Function()? onUnauthorized;

  /// Tente un rafraîchissement du token d'accès (POST /mobile/auth/refresh/
  /// côté AuthSession) ; renvoie true si un nouveau `accessToken` a été posé
  /// sur ce client, auquel cas la requête d'origine est rejouée une fois.
  Future<bool> Function()? onRefreshToken;

  Future<Map<String, dynamic>> getJson(String path) => _send('GET', path);

  Future<Map<String, dynamic>> postJson(
    String path, [
    Map<String, dynamic>? body,
  ]) =>
      _send('POST', path, body: body);

  /// Variante utilisée par AuthSession pour l'appel de rafraîchissement
  /// lui-même : `allowTokenRefresh: false` évite une boucle si /refresh/
  /// répond lui-même 401 (refresh token expiré/révoqué).
  Future<Map<String, dynamic>> postJsonNoRefresh(
    String path,
    Map<String, dynamic> body,
  ) =>
      _send('POST', path, body: body, allowTokenRefresh: false);

  Future<Map<String, dynamic>> patchJson(String path, Map<String, dynamic> body) =>
      _send('PATCH', path, body: body);

  /// Upload `multipart/form-data` (dossier de vérification livreur, écran
  /// 14) : mêmes champs texte que `fields`, plus un unique fichier sous
  /// `fileFieldName`. Construit la trame manuellement (pas de package
  /// `http`/`dio` dans ce projet) en suivant le même principe que `_send`
  /// pour `Content-Length` : dart:io bascule en `Transfer-Encoding: chunked`
  /// si la taille n'est pas fixée avant écriture, rejeté par le serveur de
  /// dev Django.
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    required String fileFieldName,
    required List<int> fileBytes,
    required String fileName,
    required String contentType,
  }) async {
    final boundary = '----gabpharma-${DateTime.now().microsecondsSinceEpoch}';
    final body = BytesBuilder();
    for (final entry in fields.entries) {
      body.add(utf8.encode(
        '--$boundary\r\n'
        'Content-Disposition: form-data; name="${entry.key}"\r\n\r\n'
        '${entry.value}\r\n',
      ));
    }
    body.add(utf8.encode(
      '--$boundary\r\n'
      'Content-Disposition: form-data; name="$fileFieldName"; filename="$fileName"\r\n'
      'Content-Type: $contentType\r\n\r\n',
    ));
    body.add(fileBytes);
    body.add(utf8.encode('\r\n--$boundary--\r\n'));

    return _sendRaw(
      'POST',
      path,
      contentType: 'multipart/form-data; boundary=$boundary',
      bytes: body.takeBytes(),
    );
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool allowTokenRefresh = true,
  }) {
    final bytes = body != null ? utf8.encode(jsonEncode(body)) : <int>[];
    return _sendRaw(
      method,
      path,
      contentType: 'application/json',
      bytes: bytes,
      allowTokenRefresh: allowTokenRefresh,
    );
  }

  Future<Map<String, dynamic>> _sendRaw(
    String method,
    String path, {
    required String contentType,
    required List<int> bytes,
    bool allowTokenRefresh = true,
  }) async {
    final request = await _httpClient.openUrl(
      method,
      Uri.parse('${AppConfig.apiBaseUrl}$path'),
    );
    request.headers.set(HttpHeaders.contentTypeHeader, contentType);
    if (accessToken case final token?) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    request.headers.contentLength = bytes.length;
    request.add(bytes);

    final response = await request.close();
    final raw = await utf8.decoder.bind(response).join();
    final dynamic decoded = raw.isEmpty ? <String, dynamic>{} : jsonDecode(raw);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401 &&
          accessToken != null &&
          allowTokenRefresh &&
          onRefreshToken != null) {
        final refreshed = await onRefreshToken!.call();
        if (refreshed) {
          return _sendRaw(
            method,
            path,
            contentType: contentType,
            bytes: bytes,
            allowTokenRefresh: false,
          );
        }
      }
      if (response.statusCode == 401 && accessToken != null) {
        onUnauthorized?.call();
      }
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

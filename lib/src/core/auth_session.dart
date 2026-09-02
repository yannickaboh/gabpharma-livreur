import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';

class AuthChallenge {
  const AuthChallenge({required this.id, required this.method, required this.canResend});

  final String id;
  final String method; // "email" or "totp"
  final bool canResend;

  factory AuthChallenge.fromJson(Map<String, dynamic> json) => AuthChallenge(
    id: json['id'] as String,
    method: json['method'] as String,
    canResend: json['can_resend'] as bool? ?? false,
  );
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.status,
  });

  final int id;
  final String email;
  final String phone;
  final String firstName;
  final String lastName;
  final String role;
  final String status;

  String get fullName => [firstName, lastName].where((part) => part.isNotEmpty).join(' ');

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    final combined = (first + last).toUpperCase();
    return combined.isEmpty ? '?' : combined;
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as int,
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    firstName: json['first_name'] as String? ?? '',
    lastName: json['last_name'] as String? ?? '',
    role: json['role'] as String? ?? '',
    status: json['status'] as String? ?? '',
  );
}

/// Session livreur : jetons JWT, profil courant, et les appels d'authentification
/// (login/2FA/mot de passe oublié) qui n'exigent pas encore de token.
class AuthSession {
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  static const _accessKey = 'gp_livreur_access_token';
  static const _refreshKey = 'gp_livreur_refresh_token';

  final ApiClient client = ApiClient();
  final _storage = const FlutterSecureStorage();

  AuthUser? currentUser;

  Future<AuthChallenge> login({required String identifier, required String password}) async {
    final response = await client.postJson('/mobile/auth/login/', {
      'identifier': identifier,
      'password': password,
      'app': 'courier',
    });
    return AuthChallenge.fromJson(response['challenge'] as Map<String, dynamic>);
  }

  Future<void> verifyTwoFactor({
    required String challengeId,
    required String method,
    required String code,
  }) async {
    final response = await client.postJson('/mobile/auth/verify-2fa/', {
      'challenge_id': challengeId,
      'method': method,
      'code': code,
    });
    await _storeTokens(response);
  }

  Future<AuthChallenge> resendCode(String challengeId) async {
    final response = await client.postJson('/mobile/auth/resend-2fa/', {
      'challenge_id': challengeId,
    });
    return AuthChallenge.fromJson(response['challenge'] as Map<String, dynamic>);
  }

  /// Tente de restaurer une session déjà stockée. Ne lève jamais : renvoie
  /// simplement `false` (et efface tout jeton invalide) si ça échoue.
  Future<bool> restoreSession() async {
    final access = await _storage.read(key: _accessKey);
    if (access == null) return false;
    client.accessToken = access;
    try {
      final response = await client.getJson('/mobile/auth/me/');
      currentUser = AuthUser.fromJson(response['user'] as Map<String, dynamic>);
      return true;
    } on ApiException {
      await logout();
      return false;
    }
  }

  Future<void> logout() async {
    currentUser = null;
    client.accessToken = null;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  Future<AuthChallenge> requestPasswordReset(String identifier) async {
    final response = await client.postJson('/mobile/auth/password-reset/', {
      'identifier': identifier,
    });
    return AuthChallenge.fromJson(response['challenge'] as Map<String, dynamic>);
  }

  Future<String> verifyPasswordReset({required String challengeId, required String code}) async {
    final response = await client.postJson('/mobile/auth/password-reset/verify/', {
      'challenge_id': challengeId,
      'code': code,
    });
    return response['reset_token'] as String;
  }

  Future<void> confirmPasswordReset({
    required String resetToken,
    required String newPassword1,
    required String newPassword2,
  }) => client.postJson('/mobile/auth/password-reset/confirm/', {
    'reset_token': resetToken,
    'new_password1': newPassword1,
    'new_password2': newPassword2,
  });

  Future<void> _storeTokens(Map<String, dynamic> tokenPayload) async {
    final access = tokenPayload['access'] as String;
    final refresh = tokenPayload['refresh'] as String;
    client.accessToken = access;
    currentUser = AuthUser.fromJson(tokenPayload['user'] as Map<String, dynamic>);
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }
}

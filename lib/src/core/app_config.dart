import 'package:flutter/widgets.dart';

abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8004/api/v1',
  );

  static const demoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: true);

  /// Permet à AuthSession de rediriger vers /login sur une déconnexion
  /// forcée (401 non résolu par un refresh) sans dépendre d'un BuildContext.
  static final navigatorKey = GlobalKey<NavigatorState>();
}

import 'package:flutter/material.dart';

import 'auth_screens.dart';
import 'core/app_config.dart';
import 'core/theme.dart';
import 'courier_shell.dart';
import 'detail_screens.dart';

class GabPharmaLivreurApp extends StatelessWidget {
  const GabPharmaLivreurApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: AppConfig.navigatorKey,
    debugShowCheckedModeBanner: false,
    title: "Gab'Pharma Livreur",
    theme: buildCourierTheme(),
    initialRoute: '/',
    routes: {
      '/': (_) => const SplashScreen(),
      '/login': (_) => const LoginScreen(),
      '/verify': (_) => const VerifyScreen(),
      '/home': (_) => const CourierShell(),
      '/password-reset': (_) => const PasswordResetScreen(),
      '/available-detail': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map?;
        return AvailableCourseDetailScreen(deliveryId: args?['deliveryId'] as int?);
      },
      '/active-delivery': (_) => const ActiveDeliveryScreen(),
      '/map': (_) => const NavigationMapScreen(),
      '/incident': (_) => const IncidentScreen(),
      '/availability': (_) => const AvailabilityScreen(),
      '/documents': (_) => const DocumentsScreen(),
      '/notifications': (_) => const NotificationsScreen(),
      '/support': (_) => const SupportScreen(),
      '/support-thread': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map?;
        return SupportThreadScreen(ticketId: args?['ticketId'] as int? ?? 0);
      },
      '/security': (_) => const ChangePasswordScreen(),
    },
  );
}

import 'package:flutter/material.dart';

import 'auth_screens.dart';
import 'core/theme.dart';
import 'courier_shell.dart';
import 'detail_screens.dart';

class GabPharmaLivreurApp extends StatelessWidget {
  const GabPharmaLivreurApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
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
      '/available-detail': (_) => const AvailableCourseDetailScreen(),
      '/active-delivery': (_) => const ActiveDeliveryScreen(),
      '/map': (_) => const NavigationMapScreen(),
      '/incident': (_) => const IncidentScreen(),
      '/availability': (_) => const AvailabilityScreen(),
      '/documents': (_) => const DocumentsScreen(),
      '/notifications': (_) => const SimpleFeatureScreen(
        title: 'Notifications',
        icon: Icons.notifications_outlined,
        description:
            'Affectations, transitions de course, incidents et informations de règlement.',
      ),
      '/support': (_) => const SimpleFeatureScreen(
        title: 'Centre Support',
        icon: Icons.support_agent,
        description: 'Tickets Livraison, Compte ou Paiement liés à une course.',
        actionLabel: 'Ouvrir une conversation',
        nextRoute: '/support-thread',
      ),
      '/support-thread': (_) => const SimpleFeatureScreen(
        title: 'Conversation Support',
        icon: Icons.forum_outlined,
        description:
            'Messages visibles du livreur, réponses Staff et pièces jointes protégées.',
      ),
      '/security': (_) => const SimpleFeatureScreen(
        title: 'Profil et sécurité',
        icon: Icons.security_outlined,
        description:
            'Identité, téléphone, véhicule, mot de passe, confidentialité et déconnexion.',
      ),
    },
  );
}

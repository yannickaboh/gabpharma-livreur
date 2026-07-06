import 'package:flutter/material.dart';

import 'core/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: GabColors.primary,
            child: Icon(Icons.delivery_dining, color: Colors.white, size: 46),
          ),
          SizedBox(height: 18),
          Text(
            "Gab'Pharma",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          Text('Espace Livreur'),
        ],
      ),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool obscure = true;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Prêt pour la tournée ?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text('Connectez-vous à votre espace Livreur sécurisé.'),
        const SizedBox(height: 32),
        const TextField(
          decoration: InputDecoration(
            labelText: 'E-mail, téléphone ou identifiant',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          obscureText: obscure,
          decoration: InputDecoration(
            labelText: 'Mot de passe',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: () => setState(() => obscure = !obscure),
              icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pushNamed(context, '/password-reset'),
            child: const Text('Mot de passe oublié ?'),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pushNamed(context, '/verify'),
          child: const Text('Continuer'),
        ),
      ],
    ),
  );
}

class VerifyScreen extends StatelessWidget {
  const VerifyScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Vérification 2FA')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(
          Icons.verified_user_outlined,
          size: 68,
          color: GabColors.primary,
        ),
        const SizedBox(height: 20),
        Text(
          'Code de sécurité',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'En démonstration, utilisez 123456.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        const TextField(
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, letterSpacing: 12),
          decoration: InputDecoration(counterText: '', hintText: '123456'),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (route) => false,
          ),
          child: const Text('Vérifier'),
        ),
      ],
    ),
  );
}

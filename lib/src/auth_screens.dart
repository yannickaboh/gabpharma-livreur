import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/auth_session.dart';
import 'core/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _offline = false;
  String _status = 'Vérification de la session...';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup(
        'example.com',
      ).timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on Object {
      return false;
    }
  }

  Future<void> _bootstrap() async {
    setState(() {
      _offline = false;
      _status = 'Vérification de la session...';
    });

    if (!await _hasInternetConnection()) {
      if (!mounted) return;
      setState(() {
        _offline = true;
        _status = 'Connexion impossible';
      });
      return;
    }

    if (!mounted) return;
    setState(() => _status = 'Vérification de la session...');
    final restored = await AuthSession.instance.restoreSession();
    if (!mounted) return;

    if (restored) {
      setState(() => _status = 'Session retrouvée...');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: GabColors.background,
    body: SafeArea(
      child: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: _offline
                ? Material(
                    color: GabColors.danger.withValues(alpha: 0.12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cloud_off,
                            color: GabColors.danger,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Mode Hors Ligne : Vérifiez votre connexion internet.',
                              style: TextStyle(
                                color: GabColors.danger,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: SizedBox.expand(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IgnorePointer(
                    child: Opacity(
                      opacity: 0.35,
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [GabColors.secondary, Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _GabPharmaLogo(),
                      const SizedBox(height: 32),
                      if (!_offline) ...[
                        const SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            color: GabColors.primary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _status,
                          style: const TextStyle(
                            color: GabColors.muted,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ] else ...[
                        Text(
                          _status,
                          style: const TextStyle(
                            color: GabColors.danger,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _bootstrap,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(160, 48),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: Text(
              'Version 1.0.4',
              style: TextStyle(
                color: GabColors.muted.withValues(alpha: 0.6),
                fontSize: 12,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _GabPharmaLogo extends StatelessWidget {
  const _GabPharmaLogo();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            border: Border.all(color: GabColors.primary, width: 2),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(
            Icons.add_rounded,
            color: GabColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
            ),
            children: [
              TextSpan(text: "Gab'", style: TextStyle(color: GabColors.ink)),
              const TextSpan(
                text: 'Pharma',
                style: TextStyle(color: GabColors.primary),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool obscure = true;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSupportContact() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Support logistique'),
        content: const Text(
          'Contactez le support logistique Gab’Pharma au 01 23 45 67 89.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final challenge = await AuthSession.instance.login(
        identifier: _identifierController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      Navigator.pushNamed(
        context,
        '/verify',
        arguments: {
          'challengeId': challenge.id,
          'method': challenge.method,
          'canResend': challenge.canResend,
        },
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: GabColors.background,
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                const _GabPharmaLogo(),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: GabColors.primary.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connexion Livreur',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: GabColors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Accédez à votre espace pour gérer vos livraisons.',
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _identifierController,
                          decoration: const InputDecoration(
                            labelText: 'Identifiant',
                            hintText: 'E-mail, téléphone ou nom d’utilisateur',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'Identifiant requis'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: obscure,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => obscure = !obscure),
                              icon: Icon(
                                obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Mot de passe requis'
                              : null,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/password-reset',
                            ),
                            child: const Text('Mot de passe oublié ?'),
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: GabColors.danger),
                          ),
                        ],
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Se connecter'),
                                    SizedBox(width: 8),
                                    Icon(Icons.login),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    const Text("Besoin d'aide ? "),
                    GestureDetector(
                      onTap: _showSupportContact,
                      child: Text(
                        'Contacter le support logistique',
                        style: TextStyle(
                          color: GabColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: GabColors.muted.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: GabColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SERVEUR OPÉRATIONNEL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: GabColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});
  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen>
    with SingleTickerProviderStateMixin {
  String _code = '';
  bool _showError = false;
  String? _errorMessage;
  bool _verifying = false;
  bool _success = false;
  int _timeLeft = 59;
  Timer? _timer;
  late final AnimationController _shakeController;

  late String _challengeId;
  late String _method;
  bool _canResend = true;
  bool _argsLoaded = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsLoaded) return;
    _argsLoaded = true;
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    _challengeId = args?['challengeId'] as String? ?? '';
    _method = args?['method'] as String? ?? 'email';
    _canResend = args?['canResend'] as bool? ?? true;
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _timeLeft = 59);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft <= 1) {
        timer.cancel();
        setState(() => _timeLeft = 0);
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_code.length >= 6 || _verifying || _success) return;
    setState(() {
      _code += digit;
      _showError = false;
    });
  }

  void _onBackspace() {
    if (_code.isEmpty || _verifying || _success) return;
    setState(() => _code = _code.substring(0, _code.length - 1));
  }

  Future<void> _verify() async {
    if (_code.length != 6 || _verifying || _success) return;
    setState(() {
      _verifying = true;
      _showError = false;
    });
    try {
      await AuthSession.instance.verifyTwoFactor(
        challengeId: _challengeId,
        method: _method,
        code: _code,
      );
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _success = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _showError = true;
        _errorMessage = error.message;
        _code = '';
      });
      unawaited(_shakeController.forward(from: 0));
    }
  }

  Future<void> _resend() async {
    if (_timeLeft > 0 || !_canResend) return;
    setState(() {
      _code = '';
      _showError = false;
    });
    try {
      final challenge = await AuthSession.instance.resendCode(_challengeId);
      if (!mounted) return;
      setState(() => _challengeId = challenge.id);
      _startCountdown();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _showError = true;
        _errorMessage = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canVerify = _code.length == 6 && !_success;
    return Scaffold(
      backgroundColor: GabColors.background,
      appBar: AppBar(
        backgroundColor: GabColors.background,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Gab'Pharma",
          style: TextStyle(color: GabColors.primary, fontWeight: FontWeight.w800),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.security, color: GabColors.primary),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFFA8F4B9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sms_outlined,
                        size: 40,
                        color: Color(0xFF287243),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Vérification de sécurité',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: GabColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _method == 'totp'
                          ? "Entrez le code à 6 chiffres de votre application d'authentification"
                          : 'Entrez le code à 6 chiffres envoyé par e-mail',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: GabColors.muted),
                    ),
                    const SizedBox(height: 28),
                    AnimatedBuilder(
                      animation: _shakeController,
                      builder: (context, child) {
                        final t = _shakeController.value;
                        final offset = sin(t * pi * 4) * 8 * (1 - t);
                        return Transform.translate(
                          offset: Offset(offset, 0),
                          child: child,
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          final filled = index < _code.length;
                          final isNext = index == _code.length;
                          return Container(
                            width: 44,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD7E6DE),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _showError
                                    ? GabColors.danger
                                    : (isNext
                                          ? GabColors.primary
                                          : Colors.transparent),
                                width: 2,
                              ),
                            ),
                            child: Text(
                              filled ? _code[index] : '',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    if (_showError) ...[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.report, size: 18, color: GabColors.danger),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _errorMessage ?? 'Code incorrect',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: GabColors.danger,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),
                    if (_canResend)
                      TextButton(
                        onPressed: _timeLeft == 0 ? _resend : null,
                        child: Text(
                          _timeLeft > 0
                              ? 'Renvoyer le code  0:${_timeLeft.toString().padLeft(2, '0')}'
                              : 'Renvoyer le code',
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFFE2F1E9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  for (final row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: row
                            .map(
                              (digit) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: _NumpadKey(
                                    label: digit,
                                    onTap: () => _onDigit(digit),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  Row(
                    children: [
                      const Expanded(child: SizedBox()),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: _NumpadKey(
                            label: '0',
                            onTap: () => _onDigit('0'),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: _NumpadKey(
                            icon: Icons.backspace_outlined,
                            onTap: _onBackspace,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: canVerify ? _verify : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: _success
                            ? GabColors.secondary
                            : GabColors.primary,
                        shape: const StadiumBorder(),
                        disabledBackgroundColor: GabColors.primary.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      child: _verifying
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(_success ? '' : 'Vérifier'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumpadKey extends StatelessWidget {
  const _NumpadKey({this.label, this.icon, required this.onTap});
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFD7E6DE),
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        height: 44,
        child: Center(
          child: icon != null
              ? Icon(icon, color: GabColors.ink, size: 20)
              : Text(
                  label!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GabColors.ink,
                  ),
                ),
        ),
      ),
    ),
  );
}

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});
  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  int _step = 1;
  final _identifierFormKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _otpError;
  String? _passwordError;
  String? _challengeId;
  String? _resetToken;
  bool _submittingIdentifier = false;
  bool _verifyingOtp = false;
  bool _resettingPassword = false;

  @override
  void dispose() {
    _identifierController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitIdentifier() async {
    if (_submittingIdentifier) return;
    if (!_identifierFormKey.currentState!.validate()) return;
    setState(() => _submittingIdentifier = true);
    try {
      final challenge = await AuthSession.instance.requestPasswordReset(
        _identifierController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _submittingIdentifier = false;
        _challengeId = challenge.id;
        _step = 2;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _submittingIdentifier = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _verifyOtp() async {
    if (_verifyingOtp) return;
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length != 6) {
      setState(() => _otpError = 'Entrez les 6 chiffres du code.');
      return;
    }
    setState(() {
      _verifyingOtp = true;
      _otpError = null;
    });
    try {
      final resetToken = await AuthSession.instance.verifyPasswordReset(
        challengeId: _challengeId!,
        code: code,
      );
      if (!mounted) return;
      setState(() {
        _verifyingOtp = false;
        _resetToken = resetToken;
        _step = 3;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _verifyingOtp = false;
        _otpError = error.message;
      });
    }
  }

  Future<void> _resendOtp() async {
    for (final controller in _otpControllers) {
      controller.clear();
    }
    _otpFocusNodes.first.requestFocus();
    setState(() => _otpError = null);
    try {
      final challenge = await AuthSession.instance.resendCode(_challengeId!);
      if (!mounted) return;
      setState(() => _challengeId = challenge.id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nouveau code envoyé.')));
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _resetPassword() async {
    if (_resettingPassword) return;
    final password = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;
    final hasDigit = RegExp(r'\d').hasMatch(password);
    if (password.length < 8 || !hasDigit) {
      setState(
        () => _passwordError =
            'Le mot de passe doit contenir au moins 8 caractères et un chiffre.',
      );
      return;
    }
    if (password != confirm) {
      setState(() => _passwordError = 'Les mots de passe ne correspondent pas.');
      return;
    }
    setState(() {
      _resettingPassword = true;
      _passwordError = null;
    });
    try {
      await AuthSession.instance.confirmPasswordReset(
        resetToken: _resetToken!,
        newPassword1: password,
        newPassword2: confirm,
      );
      if (!mounted) return;
      setState(() {
        _resettingPassword = false;
        _step = 4;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _resettingPassword = false;
        _passwordError = error.message;
      });
    }
  }

  Widget _stepCard({required IconData icon, required List<Widget> children}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD7E6DE)),
          boxShadow: [
            BoxShadow(
              color: GabColors.primary.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFA8F4B9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF287243)),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: GabColors.background,
    appBar: AppBar(
      backgroundColor: GabColors.background,
      elevation: 0,
      title: const Text(
        'Récupération',
        style: TextStyle(color: GabColors.primary, fontWeight: FontWeight.w800),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: GabColors.softGreen,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delivery_dining, size: 16, color: GabColors.primary),
                SizedBox(width: 4),
                Text(
                  "Gab'Pharma",
                  style: TextStyle(
                    color: GabColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_step < 4) ...[
              const Text(
                'Récupération du mot de passe',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: GabColors.ink,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: List.generate(3, (i) {
                  final active = i < _step;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                      height: 6,
                      decoration: BoxDecoration(
                        color: active
                            ? GabColors.primary
                            : const Color(0xFFBEC9BD),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
            ],
            if (_step == 1) ...[
              _stepCard(
                icon: Icons.person_search,
                children: [
                  const Text(
                    'Entrez votre identifiant pour recevoir un code de vérification',
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _identifierFormKey,
                    child: TextFormField(
                      controller: _identifierController,
                      decoration: const InputDecoration(
                        labelText: 'Identifiant',
                        hintText: 'E-mail, téléphone ou nom d’utilisateur',
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Identifiant requis'
                          : null,
                    ),
                  ),
                ],
              ),
              FilledButton(
                onPressed: _submittingIdentifier ? null : _submitIdentifier,
                child: _submittingIdentifier
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Text('Continuer'),
              ),
            ] else if (_step == 2) ...[
              _stepCard(
                icon: Icons.mark_email_read,
                children: [
                  const Text('Code de vérification envoyé !'),
                  const SizedBox(height: 4),
                  const Text(
                    'Veuillez saisir le code à 6 chiffres reçu par e-mail.',
                    style: TextStyle(color: GabColors.muted),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 44,
                        height: 56,
                        child: TextField(
                          controller: _otpControllers[index],
                          focusNode: _otpFocusNodes[index],
                          maxLength: 1,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                          decoration: const InputDecoration(counterText: ''),
                          onChanged: (value) {
                            setState(() => _otpError = null);
                            if (value.isNotEmpty && index < 5) {
                              _otpFocusNodes[index + 1].requestFocus();
                            } else if (value.isEmpty && index > 0) {
                              _otpFocusNodes[index - 1].requestFocus();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  if (_otpError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _otpError!,
                      style: const TextStyle(color: GabColors.danger),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _resendOtp,
                    child: const Text('Renvoyer le code'),
                  ),
                ],
              ),
              FilledButton(
                onPressed: _verifyingOtp ? null : _verifyOtp,
                child: _verifyingOtp
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Text('Vérifier'),
              ),
            ] else if (_step == 3) ...[
              _stepCard(
                icon: Icons.lock_reset,
                children: [
                  const Text('Définissez votre nouveau mot de passe'),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      hintText: '••••••••',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      hintText: '••••••••',
                    ),
                  ),
                  if (_passwordError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _passwordError!,
                      style: const TextStyle(color: GabColors.danger),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: GabColors.softGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: GabColors.secondary, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Le mot de passe doit contenir au moins 8 caractères et un chiffre.',
                            style: TextStyle(
                              fontSize: 12,
                              color: GabColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              FilledButton(
                onPressed: _resettingPassword ? null : _resetPassword,
                child: _resettingPassword
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Text('Réinitialiser'),
              ),
            ] else ...[
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        color: Color(0xFFA8F4B9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Color(0xFF287243),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Félicitations !',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: GabColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Votre mot de passe a été réinitialisé avec succès. '
                        'Vous pouvez maintenant vous connecter.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: GabColors.muted),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.popUntil(
                          context,
                          ModalRoute.withName('/login'),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          side: const BorderSide(
                            color: GabColors.primary,
                            width: 2,
                          ),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Se connecter'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Assistance technique : 01 23 45 67 89',
                style: TextStyle(color: GabColors.muted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

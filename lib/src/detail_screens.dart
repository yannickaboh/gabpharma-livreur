import 'package:flutter/material.dart';

import 'core/theme.dart';

class AvailableCourseDetailScreen extends StatelessWidget {
  const AvailableCourseDetailScreen({super.key});

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: GabColors.muted,
      ),
    ),
  );

  Widget _card({required List<Widget> children}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: GabColors.outlineVariant.withValues(alpha: 0.4)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  void _applyForCourse(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Candidature envoyée. Vous serez notifié dès que le Staff confirme l’affectation.',
        ),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: GabColors.background,
    appBar: AppBar(
      backgroundColor: GabColors.background,
      elevation: 0,
      title: const Text(
        'Détails Course',
        style: TextStyle(color: GabColors.primary, fontWeight: FontWeight.w800),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: Row(
            children: [
              Icon(Icons.circle, size: 9, color: GabColors.primary),
              SizedBox(width: 6),
              Text(
                'DISPONIBLE',
                style: TextStyle(
                  color: GabColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: GabColors.routeBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: GabColors.routeBlue.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info, color: GabColors.routeBlue),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "En attente d'affectation",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: GabColors.routeBlue,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Cette course est visible par tous les livreurs '
                              'à proximité. Elle sera confirmée par le Staff '
                              'après votre demande.',
                              style: TextStyle(color: GabColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _sectionTitle('PHARMACIE DE DÉPART'),
                _card(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: GabColors.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.local_pharmacy,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Pharmacie de l'Estuaire",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: GabColors.primary,
                                ),
                              ),
                              const Text(
                                'Boulevard Triomphal, Libreville',
                                style: TextStyle(color: GabColors.muted),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _InfoChip(
                                    icon: Icons.social_distance,
                                    label: '1.2 km',
                                  ),
                                  const SizedBox(width: 8),
                                  _InfoChip(icon: Icons.timer_outlined, label: '5 min'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionTitle('ZONE DE LIVRAISON'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: GabColors.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 130,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFBFE3D0),
                                  Color(0xFF9AC9E0),
                                ],
                              ),
                            ),
                            child: const Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: EdgeInsets.all(14),
                                child: Icon(
                                  Icons.map_outlined,
                                  color: Colors.white70,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: GabColors.primary,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Owendo - Cité SNI',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        color: GabColors.danger.withValues(alpha: 0.06),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.visibility_off_outlined,
                              size: 20,
                              color: GabColors.danger,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "L'adresse exacte et le numéro de contact "
                                'seront révélés uniquement après affectation '
                                'par le Staff.',
                                style: TextStyle(
                                  color: GabColors.danger,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _sectionTitle('DÉTAILS FINANCIERS'),
                _card(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Frais de livraison',
                          style: TextStyle(color: GabColors.muted),
                        ),
                        Text('2 500 FCFA'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: GabColors.outlineVariant),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Commission Plateforme',
                                style: TextStyle(color: GabColors.muted),
                              ),
                              Text(
                                '- 500 FCFA',
                                style: TextStyle(color: GabColors.danger),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Part Livreur',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: GabColors.primary,
                          ),
                        ),
                        const Text(
                          '2 000 FCFA',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: GabColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionTitle('CONTRAINTES & NOTES'),
                Row(
                  children: [
                    Expanded(
                      child: _ConstraintTile(
                        icon: Icons.ac_unit,
                        iconColor: GabColors.primary,
                        background: GabColors.primary.withValues(alpha: 0.06),
                        title: 'Chaîne du froid',
                        titleColor: GabColors.primary,
                        caption: 'Sac isotherme requis pour le transport.',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ConstraintTile(
                        icon: Icons.inventory_2_outlined,
                        iconColor: GabColors.muted,
                        background: const Color(0xFFDCECE3),
                        title: 'Colis Fragile',
                        titleColor: GabColors.ink,
                        caption: 'Contient des flacons en verre.',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: () => _applyForCourse(context),
                icon: const Icon(Icons.touch_app_outlined),
                label: const Text('Postuler pour cette course'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFDCECE3),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: GabColors.muted),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: GabColors.muted)),
      ],
    ),
  );
}

class _ConstraintTile extends StatelessWidget {
  const _ConstraintTile({
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.title,
    required this.titleColor,
    required this.caption,
  });
  final IconData icon;
  final Color iconColor;
  final Color background;
  final String title;
  final Color titleColor;
  final String caption;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w800, color: titleColor),
        ),
        const SizedBox(height: 2),
        Text(
          caption,
          style: const TextStyle(fontSize: 11, color: GabColors.muted),
        ),
      ],
    ),
  );
}

class ActiveDeliveryScreen extends StatefulWidget {
  const ActiveDeliveryScreen({super.key});
  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  static const _validOtp = '654321';

  int step = 2;
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  String? _otpError;

  @override
  void dispose() {
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _callClient(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appeler la cliente'),
        content: const Text(
          'Appelez Mme. Obiang au +241 07 00 00 00 depuis votre téléphone.',
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

  void _resendOtp() {
    for (final controller in _otpControllers) {
      controller.clear();
    }
    _otpFocusNodes.first.requestFocus();
    setState(() => _otpError = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nouveau code envoyé à la cliente (démonstration).')),
    );
  }

  void _confirmDelivery() {
    final code = _otpControllers.map((c) => c.text).join();
    if (code == _validOtp) {
      setState(() {
        _otpError = null;
        step = 3;
      });
    } else {
      setState(() => _otpError = 'Code incorrect.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: GabColors.background,
    appBar: AppBar(
      backgroundColor: GabColors.background,
      elevation: 0,
      title: Row(
        children: const [
          Icon(Icons.delivery_dining, color: GabColors.primary, size: 26),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Course en cours',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: GabColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
      titleSpacing: 0,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: GabColors.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'EN LIGNE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: GabColors.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                _DeliveryTimeline(step: step),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: GabColors.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: Color(0xFFA8F4B9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF287243),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mme. Obiang',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  size: 14,
                                  color: GabColors.muted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '+241 07 00 00 00',
                                  style: TextStyle(
                                    color: GabColors.muted.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: GabColors.primary.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      height: 150,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFBFE3D0), Color(0xFF8FCBAE)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.route,
                          color: Colors.white70,
                          size: 40,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          '12 min restantes',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              const Icon(Icons.store, size: 18, color: GabColors.primary),
                              Container(
                                width: 2,
                                height: 32,
                                color: GabColors.outlineVariant,
                              ),
                              const Icon(
                                Icons.location_on,
                                size: 18,
                                color: GabColors.danger,
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'RAMASSAGE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    color: GabColors.muted,
                                  ),
                                ),
                                const Text(
                                  'Pharmacie du Bord de Mer',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'LIVRAISON',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    color: GabColors.muted,
                                  ),
                                ),
                                const Text(
                                  'Quartier Louis, Libreville',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: GabColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => Navigator.pushNamed(context, '/map'),
                              style: FilledButton.styleFrom(
                                backgroundColor: GabColors.routeBlue,
                              ),
                              icon: const Icon(Icons.directions),
                              label: const Text('Ouvrir Navigation'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _callClient(context),
                              icon: const Icon(Icons.call_outlined),
                              label: const Text('Appeler'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (step < 2)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: GabColors.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Text(
                    step == 0 ? 'Course affectée' : 'Collecte effectuée',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: GabColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step == 0
                        ? 'Rendez-vous à la pharmacie pour récupérer la commande.'
                        : 'Démarrez la livraison vers la cliente.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: GabColors.muted),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => setState(() => step++),
                      child: Text(
                        step == 0 ? 'Confirmer la collecte' : 'Démarrer la livraison',
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (step == 2)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFDCECE3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: GabColors.primary, width: 2),
              ),
              child: Column(
                children: [
                  const Text(
                    'Confirmation de remise',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: GabColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Saisissez le code OTP reçu par la cliente',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: GabColors.muted),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: SizedBox(
                          width: 38,
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
                            decoration: const InputDecoration(
                              counterText: '',
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (value) {
                              setState(() => _otpError = null);
                              if (value.isNotEmpty && index < 5) {
                                _otpFocusNodes[index + 1].requestFocus();
                              } else if (value.isEmpty && index > 0) {
                                _otpFocusNodes[index - 1].requestFocus();
                              }
                            },
                          ),
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
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _confirmDelivery,
                      icon: const Icon(Icons.task_alt),
                      label: const Text('Valider la remise (OTP)'),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _resendOtp,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Renvoyer OTP'),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: GabColors.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: GabColors.primary, size: 48),
                  const SizedBox(height: 10),
                  const Text(
                    'Course livrée avec succès',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.popUntil(
                        context,
                        (route) => route.isFirst,
                      ),
                      child: const Text("Retour à l'accueil"),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/incident'),
            style: OutlinedButton.styleFrom(
              foregroundColor: GabColors.danger,
              side: BorderSide(color: GabColors.danger.withValues(alpha: 0.3)),
            ),
            icon: const Icon(Icons.report_problem_outlined),
            label: const Text('Signaler un problème'),
          ),
        ],
      ),
    ),
  );
}

class _DeliveryTimeline extends StatelessWidget {
  const _DeliveryTimeline({required this.step});
  final int step;

  static const _labels = ['Assigné', 'Récupéré', 'En transit', 'Livré'];
  static const _icons = [
    Icons.assignment_turned_in_outlined,
    Icons.inventory_2_outlined,
    Icons.route,
    Icons.inventory_2,
  ];

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(_labels.length * 2 - 1, (i) {
      if (i.isOdd) {
        final leftStepDone = (i - 1) ~/ 2 < step;
        return Expanded(
          child: Container(
            height: 2,
            color: leftStepDone ? GabColors.primary : GabColors.outlineVariant,
          ),
        );
      }
      final index = i ~/ 2;
      final done = index < step;
      final current = index == step;
      final pending = index > step;
      return Column(
        children: [
          Container(
            width: current ? 40 : 32,
            height: current ? 40 : 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pending ? GabColors.outlineVariant : GabColors.primary,
              border: current
                  ? Border.all(
                      color: GabColors.primary.withValues(alpha: 0.2),
                      width: 6,
                    )
                  : null,
            ),
            child: Icon(
              done ? Icons.check : _icons[index],
              size: current ? 22 : 18,
              color: pending ? GabColors.ink : Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Opacity(
            opacity: pending ? 0.4 : 1,
            child: Text(
              _labels[index],
              style: TextStyle(
                fontSize: 11,
                fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                color: pending ? GabColors.muted : GabColors.primary,
              ),
            ),
          ),
        ],
      );
    }),
  );
}

enum _ReportState { idle, sending, sent }

class IncidentScreen extends StatefulWidget {
  const IncidentScreen({super.key});
  @override
  State<IncidentScreen> createState() => _IncidentScreenState();
}

class _IncidentScreenState extends State<IncidentScreen> {
  static const _types = [
    'Accident',
    'Panne véhicule',
    'Client absent',
    'Problème pharmacie',
  ];
  static const _severityLabels = ['Faible', 'Moyenne', 'Critique'];
  static const _severityColors = [
    GabColors.primary,
    Color(0xFFC16A00),
    GabColors.danger,
  ];

  String? _selectedType;
  int _severity = 0;
  final _descriptionController = TextEditingController();
  _ReportState _reportState = _ReportState.idle;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reportState != _ReportState.idle) return;
    setState(() => _reportState = _ReportState.sending);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _reportState = _ReportState.sent);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _reportState = _ReportState.idle);
  }

  void _showIncidentDetails(BuildContext context, String title, String description) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: GabColors.background,
    appBar: AppBar(
      backgroundColor: GabColors.background,
      elevation: 0,
      title: const Row(
        children: [
          Icon(Icons.report_problem, color: GabColors.primary, size: 26),
          SizedBox(width: 10),
          Flexible(
            child: Text(
              'Signaler un incident',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: GabColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
      titleSpacing: 0,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.circle, size: 8, color: GabColors.primary),
              const SizedBox(width: 6),
              Text(
                'EN LIGNE',
                style: TextStyle(
                  color: GabColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: GabColors.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Détails de l'incident",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Type d'incident",
                  style: TextStyle(color: GabColors.muted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  hint: const Text('Sélectionner le type'),
                  items: _types
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedType = value),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Sévérité',
                  style: TextStyle(color: GabColors.muted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(3, (index) {
                    final selected = _severity == index;
                    final color = _severityColors[index];
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: index < 2 ? 8 : 0),
                        child: InkWell(
                          onTap: () => setState(() => _severity = index),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected ? color : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected ? Colors.transparent : GabColors.outlineVariant,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              _severityLabels[index],
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : GabColors.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Description',
                  style: TextStyle(color: GabColors.muted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Veuillez décrire brièvement le problème...',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _reportState == _ReportState.idle ? _submit : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _reportState == _ReportState.sent
                          ? GabColors.routeBlue
                          : GabColors.primary,
                      disabledBackgroundColor: _reportState == _ReportState.sent
                          ? GabColors.routeBlue
                          : GabColors.primary,
                      disabledForegroundColor: Colors.white,
                    ),
                    icon: Icon(
                      switch (_reportState) {
                        _ReportState.idle => Icons.send,
                        _ReportState.sending => Icons.sync,
                        _ReportState.sent => Icons.check_circle,
                      },
                    ),
                    label: Text(
                      switch (_reportState) {
                        _ReportState.idle => 'Envoyer le signalement',
                        _ReportState.sending => 'Envoi...',
                        _ReportState.sent => 'Signalé !',
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Incidents ouverts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: GabColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '2 actifs',
                  style: TextStyle(
                    color: GabColors.danger,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _OpenIncidentCard(
            icon: Icons.emergency,
            iconColor: GabColors.danger,
            iconBackground: GabColors.danger.withValues(alpha: 0.12),
            borderColor: GabColors.danger,
            title: 'Accident Mineur',
            statusLabel: 'Signalé',
            statusColor: GabColors.danger,
            description: 'Moto bloquée suite à une collision légère. Attente assistance.',
            timeAgo: 'Il y a 15 min',
            onDetails: () => _showIncidentDetails(
              context,
              'Accident Mineur',
              'Moto bloquée suite à une collision légère. Attente assistance.\n\n'
                  'Statut : Signalé · Il y a 15 min',
            ),
          ),
          const SizedBox(height: 12),
          _OpenIncidentCard(
            icon: Icons.person_off,
            iconColor: const Color(0xFFC16A00),
            iconBackground: const Color(0xFFC16A00).withValues(alpha: 0.12),
            borderColor: const Color(0xFFC16A00),
            title: 'Client absent',
            statusLabel: 'En résolution',
            statusColor: const Color(0xFFC16A00),
            description: 'Le client ne répond pas aux appels. Support contacté.',
            timeAgo: 'Il y a 42 min',
            onDetails: () => _showIncidentDetails(
              context,
              'Client absent',
              'Le client ne répond pas aux appels. Support contacté.\n\n'
                  'Statut : En résolution · Il y a 42 min',
            ),
          ),
        ],
      ),
    ),
  );
}

class _OpenIncidentCard extends StatelessWidget {
  const _OpenIncidentCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.borderColor,
    required this.title,
    required this.statusLabel,
    required this.statusColor,
    required this.description,
    required this.timeAgo,
    required this.onDetails,
  });
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Color borderColor;
  final String title;
  final String statusLabel;
  final Color statusColor;
  final String description;
  final String timeAgo;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border(left: BorderSide(color: borderColor, width: 4)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(description, style: const TextStyle(color: GabColors.muted)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    timeAgo,
                    style: const TextStyle(color: GabColors.muted, fontSize: 12),
                  ),
                  TextButton(
                    onPressed: onDetails,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Détails', style: TextStyle(fontSize: 12)),
                        Icon(Icons.chevron_right, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class NavigationMapScreen extends StatelessWidget {
  const NavigationMapScreen({super.key});

  void _callPatient(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appeler la patiente'),
        content: const Text(
          'Appelez Mme. Obiang au +241 07 00 00 00 depuis votre téléphone.',
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

  void _showDeliveryInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations de livraison'),
        content: const Text(
          'Portail vert, 2ème étage. Sonnez chez Obiang. '
          'Colis à remettre en main propre contre code OTP.',
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

  void _recenter(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Carte simplifiée à titre illustratif : recentrage indisponible en démonstration.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: GabColors.background,
    body: Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _MockMapPainter(),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Material(
                color: Colors.white,
                elevation: 1,
                shadowColor: Colors.black.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: GabColors.primary),
                      ),
                      const Icon(Icons.delivery_dining, color: GabColors.primary, size: 26),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "Gab'Pharma Livreur",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: GabColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: GabColors.softGreen,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 8, color: GabColors.primary),
                            SizedBox(width: 6),
                            Text(
                              'EN LIGNE',
                              style: TextStyle(
                                color: GabColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    constraints: const BoxConstraints(maxWidth: 180),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: GabColors.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SECTEUR ACTUEL',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: GabColors.muted,
                          ),
                        ),
                        Text(
                          'Libreville Centre',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.schedule, color: GabColors.primary),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Temps estimé',
                                  style: TextStyle(fontSize: 11, color: GabColors.muted),
                                ),
                                const Text(
                                  '12 min',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: GabColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 36, color: GabColors.outlineVariant),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.straighten, color: GabColors.primary),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Distance',
                                  style: TextStyle(fontSize: 11, color: GabColors.muted),
                                ),
                                const Text(
                                  '4.2 km',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: GabColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Color(0xFFA8F4B9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, color: Color(0xFF287243)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Patiente : Mme. Obiang',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Text(
                                  'Quartier Louis, Rue 12.045',
                                  style: TextStyle(color: GabColors.muted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showDeliveryInfo(context),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFDCECE3),
                            ),
                            icon: const Icon(Icons.info_outline, color: GabColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _callPatient(context),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(56),
                                shape: const StadiumBorder(),
                                side: const BorderSide(color: GabColors.primary, width: 2),
                              ),
                              icon: const Icon(Icons.call_outlined),
                              label: const Text('Appeler Patiente'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => Navigator.pop(context),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(56),
                                shape: const StadiumBorder(),
                              ),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Retour à la course'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 240,
          child: FloatingActionButton(
            heroTag: 'recenter',
            backgroundColor: Colors.white,
            foregroundColor: GabColors.primary,
            onPressed: () => _recenter(context),
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    ),
  );
}

class _MockMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFE2EFE8);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final roadPaint = Paint()
      ..color = const Color(0xFFBEC9BD)
      ..strokeWidth = 6;
    for (final fraction in [0.2, 0.45, 0.7]) {
      canvas.drawLine(
        Offset(0, size.height * fraction),
        Offset(size.width, size.height * fraction),
        roadPaint,
      );
    }
    for (final fraction in [0.25, 0.55, 0.85]) {
      canvas.drawLine(
        Offset(size.width * fraction, 0),
        Offset(size.width * fraction, size.height),
        roadPaint,
      );
    }

    final start = Offset(size.width * 0.25, size.height * 0.44);
    final bend = Offset(size.width * 0.5, size.height * 0.44);
    final end = Offset(size.width * 0.5, size.height * 0.68);

    final routePaint = Paint()
      ..color = const Color(0xFF004F26)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(bend.dx, bend.dy)
      ..lineTo(end.dx, end.dy);
    canvas.drawPath(path, routePaint);

    canvas.drawCircle(start, 10, Paint()..color = const Color(0xFF006A35));
    canvas.drawCircle(
      end,
      26,
      Paint()..color = const Color(0xFFBA1A1A).withValues(alpha: 0.15),
    );
    canvas.drawCircle(end, 12, Paint()..color = const Color(0xFFBA1A1A));

    final courierPos = Offset(size.width * 0.5, size.height * 0.44);
    canvas.drawCircle(courierPos, 9, Paint()..color = const Color(0xFF004F26));

    TextPainter buildLabel(String text, Color color) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );
      painter.layout();
      return painter;
    }

    buildLabel(
      'Pharmacie du Bord de Mer',
      const Color(0xFF004F26),
    ).paint(canvas, start + const Offset(16, -6));
    buildLabel(
      'Patiente',
      const Color(0xFFBA1A1A),
    ).paint(canvas, end + const Offset(18, -6));
  }

  @override
  bool shouldRepaint(covariant _MockMapPainter oldDelegate) => false;
}

typedef _Zone = ({String name, String subtitle});

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});
  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  static const _zones = <_Zone>[
    (name: 'Libreville Centre', subtitle: 'Forte demande • 45 pharmacies'),
    (name: 'Akanda', subtitle: 'Demande moyenne • 12 pharmacies'),
    (name: 'Owendo', subtitle: 'Secteur Portuaire • 8 pharmacies'),
    (name: 'SNI / Angondjé', subtitle: 'Zone Résidentielle • 15 pharmacies'),
  ];

  bool _online = true;
  final Set<String> _selectedZones = {'Libreville Centre'};
  final String _activeZone = 'Libreville Centre';
  bool _updating = false;

  void _toggleZone(String name, bool checked) {
    setState(() {
      if (checked) {
        _selectedZones.add(name);
      } else if (_selectedZones.length > 1) {
        _selectedZones.remove(name);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous devez couvrir au moins une zone.')),
        );
      }
    });
  }

  Future<void> _updateZone() async {
    if (_updating) return;
    if (_selectedZones.length == 1 && _selectedZones.single == _activeZone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun changement de zone à valider.')),
      );
      return;
    }
    setState(() => _updating = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _updating = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Demande envoyée au support logistique. Validation sous ~5 min avant '
          'activation de la nouvelle zone.',
        ),
      ),
    );
  }

  void _zoomMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Carte simplifiée à titre illustratif : zoom indisponible en démonstration.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: GabColors.background,
    appBar: AppBar(
      backgroundColor: GabColors.background,
      elevation: 0,
      title: const Row(
        children: [
          Icon(Icons.map_outlined, color: GabColors.primary, size: 26),
          SizedBox(width: 10),
          Flexible(
            child: Text(
              'Disponibilité',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: GabColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
      titleSpacing: 0,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _online ? GabColors.softGreen : GabColors.background,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: GabColors.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: _online ? GabColors.primary : GabColors.muted,
                ),
                const SizedBox(width: 6),
                Text(
                  _online ? 'EN LIGNE' : 'HORS LIGNE',
                  style: TextStyle(
                    color: _online ? GabColors.primary : GabColors.muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: GabColors.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Statut Actuel',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Prêt à recevoir des commandes',
                            style: TextStyle(color: GabColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _online,
                      activeThumbColor: Colors.white,
                      activeTrackColor: GabColors.primary,
                      onChanged: (value) => setState(() => _online = value),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _online
                        ? const Color(0xFFA8F4B9)
                        : GabColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _online ? Icons.check_circle : Icons.do_not_disturb_on,
                        size: 18,
                        color: _online ? const Color(0xFF287243) : GabColors.danger,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _online ? 'VOUS ÊTES EN LIGNE' : 'VOUS ÊTES HORS LIGNE',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: _online ? const Color(0xFF287243) : GabColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              Icon(Icons.map_outlined, size: 22),
              SizedBox(width: 8),
              Text(
                'Zones couvertes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final zone in _zones)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ZoneTile(
                zone: zone,
                checked: _selectedZones.contains(zone.name),
                active: zone.name == _activeZone,
                onChanged: (value) => _toggleZone(zone.name, value),
              ),
            ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 190,
              decoration: BoxDecoration(
                border: Border.all(color: GabColors.outlineVariant.withValues(alpha: 0.6), width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: _ZoneMapPainter())),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Column(
                      children: [
                        _MapZoomButton(icon: Icons.add, onTap: _zoomMessage),
                        const SizedBox(height: 8),
                        _MapZoomButton(icon: Icons.remove, onTap: _zoomMessage),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: GabColors.primary,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Zone active : $_activeZone',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFD4E3FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFA5C8FF)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xFF004481)),
                SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(color: Color(0xFF004481), height: 1.3),
                      children: [
                        TextSpan(
                          text: 'Le changement de zone nécessite une validation par le '
                              'support logistique. Temps d’attente moyen : ',
                        ),
                        TextSpan(
                          text: '5 min',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _updateZone,
              icon: _updating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.sync),
              label: const Text('Mettre à jour ma zone'),
              style: FilledButton.styleFrom(
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ZoneTile extends StatelessWidget {
  const _ZoneTile({
    required this.zone,
    required this.checked,
    required this.active,
    required this.onChanged,
  });
  final _Zone zone;
  final bool checked;
  final bool active;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: () => onChanged(!checked),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: checked ? GabColors.primary : GabColors.outlineVariant,
            width: checked ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: checked,
              activeColor: GabColors.primary,
              onChanged: (value) => onChanged(value ?? false),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(zone.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(zone.subtitle, style: const TextStyle(color: GabColors.muted, fontSize: 12)),
                ],
              ),
            ),
            if (active) const Icon(Icons.verified, color: GabColors.primary),
          ],
        ),
      ),
    ),
  );
}

class _MapZoomButton extends StatelessWidget {
  const _MapZoomButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: 0.92),
    borderRadius: BorderRadius.circular(10),
    elevation: 1,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, size: 20, color: GabColors.ink),
      ),
    ),
  );
}

class _ZoneMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final landPaint = Paint()..color = const Color(0xFFE2EFE8);
    canvas.drawRect(Offset.zero & size, landPaint);

    final seaPaint = Paint()..color = const Color(0xFFB9D9E8);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * 0.32, size.height),
      seaPaint,
    );

    final activeZonePaint = Paint()..color = const Color(0xFF9DF6B2).withValues(alpha: 0.7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.3, size.height * 0.12, size.width * 0.4, size.height * 0.5),
        const Radius.circular(18),
      ),
      activeZonePaint,
    );

    final roadPaint = Paint()
      ..color = const Color(0xFFBEC9BD)
      ..strokeWidth = 4;
    for (final fraction in [0.3, 0.55, 0.8]) {
      canvas.drawLine(
        Offset(size.width * 0.32, size.height * fraction),
        Offset(size.width, size.height * fraction),
        roadPaint,
      );
    }

    void marker(Offset offset, String label) {
      canvas.drawCircle(offset, 6, Paint()..color = const Color(0xFF006A35));
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Color(0xFF111E19),
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      painter.layout();
      painter.paint(canvas, offset + const Offset(9, -6));
    }

    marker(Offset(size.width * 0.42, size.height * 0.3), 'Libreville Centre');
    marker(Offset(size.width * 0.78, size.height * 0.22), 'Akanda');
    marker(Offset(size.width * 0.7, size.height * 0.75), 'Owendo');
    marker(Offset(size.width * 0.9, size.height * 0.6), 'SNI/Angondjé');
  }

  @override
  bool shouldRepaint(covariant _ZoneMapPainter oldDelegate) => false;
}

enum _DocStatus { valide, enAttente, refuse }

typedef _DocInfo = ({
  String name,
  IconData thumbnailIcon,
  Color thumbnailColor,
  _DocStatus status,
  String? rejectionReason,
});

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});
  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  static const _cni = (
    name: 'CNI/Passeport',
    thumbnailIcon: Icons.badge,
    thumbnailColor: GabColors.primary,
    status: _DocStatus.valide,
    rejectionReason: null,
  );
  static const _permis = (
    name: 'Permis de conduire',
    thumbnailIcon: Icons.directions_car,
    thumbnailColor: GabColors.routeBlue,
    status: _DocStatus.enAttente,
    rejectionReason: null,
  );
  static const _assuranceRefused = (
    name: 'Assurance',
    thumbnailIcon: Icons.description,
    thumbnailColor: GabColors.danger,
    status: _DocStatus.refuse,
    rejectionReason: 'Refusé - Photo floue',
  );
  static const _assurancePending = (
    name: 'Assurance',
    thumbnailIcon: Icons.description,
    thumbnailColor: GabColors.routeBlue,
    status: _DocStatus.enAttente,
    rejectionReason: null,
  );

  _DocInfo _assurance = _assuranceRefused;
  bool _replacing = false;

  void _previewDocument(String name) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: const Text(
          'Aperçu indisponible en démonstration — l’image du document sera '
          'consultable une fois le stockage sécurisé connecté à l’API.',
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

  Future<void> _replaceDocument() async {
    if (_replacing) return;
    setState(() => _replacing = true);
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() {
      _assurance = _assurancePending;
      _replacing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Nouveau document envoyé. Il sera vérifié par le Staff Gab’Pharma.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: GabColors.background,
    appBar: AppBar(
      backgroundColor: GabColors.background,
      elevation: 0,
      title: const Row(
        children: [
          Icon(Icons.delivery_dining, color: GabColors.primary, size: 26),
          SizedBox(width: 10),
          Flexible(
            child: Text(
              'Mes Documents',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: GabColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
      titleSpacing: 0,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.circle, size: 8, color: GabColors.primary),
              const SizedBox(width: 6),
              Text(
                'EN LIGNE',
                style: TextStyle(
                  color: GabColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: GabColors.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profil Livreur',
                            style: TextStyle(color: GabColors.muted, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Complété à 65%',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.verified_user, color: GabColors.primary),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const LinearProgressIndicator(
                    value: 0.65,
                    minHeight: 10,
                    backgroundColor: Color(0xFFD7E6DE),
                    valueColor: AlwaysStoppedAnimation(GabColors.primary),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Validez vos documents pour commencer à recevoir des courses à Libreville.',
                  style: TextStyle(color: GabColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _DocumentCard(doc: _cni, onPreview: () => _previewDocument(_cni.name)),
          const SizedBox(height: 14),
          _DocumentCard(doc: _permis, onPreview: () => _previewDocument(_permis.name)),
          const SizedBox(height: 14),
          _DocumentCard(
            doc: _assurance,
            onPreview: () => _previewDocument(_assurance.name),
            onReplace: _replaceDocument,
            replacing: _replacing,
          ),
          const SizedBox(height: 28),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Conseils de validation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(
                child: _AdviceCard(
                  icon: Icons.light_mode_outlined,
                  title: 'Bon éclairage',
                  description: 'Évitez les ombres sur le document.',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _AdviceCard(
                  icon: Icons.center_focus_weak,
                  title: 'Mise au point',
                  description: 'Le texte doit être parfaitement net.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Gab’Pharma sécurise vos données conformément aux lois de protection '
            'des données personnelles en vigueur.',
            textAlign: TextAlign.center,
            style: TextStyle(color: GabColors.muted, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.doc,
    required this.onPreview,
    this.onReplace,
    this.replacing = false,
  });
  final _DocInfo doc;
  final VoidCallback onPreview;
  final VoidCallback? onReplace;
  final bool replacing;

  @override
  Widget build(BuildContext context) {
    final refused = doc.status == _DocStatus.refuse;
    final (statusColor, statusLabel, statusIcon) = switch (doc.status) {
      _DocStatus.valide => (GabColors.primary, 'Validé', Icons.check_circle),
      _DocStatus.enAttente => (GabColors.routeBlue, 'En attente de vérification', Icons.schedule),
      _DocStatus.refuse => (GabColors.danger, doc.rejectionReason ?? 'Refusé', Icons.error),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: refused ? GabColors.danger.withValues(alpha: 0.4) : GabColors.outlineVariant.withValues(alpha: 0.3),
          width: refused ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: doc.thumbnailColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(doc.thumbnailIcon, color: doc.thumbnailColor.withValues(alpha: 0.6)),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Icon(statusIcon, size: 16, color: statusColor),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            statusLabel,
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!refused)
                IconButton(
                  onPressed: onPreview,
                  icon: const Icon(Icons.visibility_outlined, color: GabColors.muted),
                ),
            ],
          ),
          if (refused) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GabColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GabColors.danger.withValues(alpha: 0.15)),
              ),
              child: const Text(
                'Veuillez reprendre la photo. Assurez-vous que tous les textes '
                'sont lisibles et qu’il n’y a pas de reflet.',
                style: TextStyle(color: GabColors.danger, fontSize: 13, height: 1.3),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onReplace,
                icon: replacing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.add_a_photo_outlined),
                label: Text(replacing ? 'Envoi...' : 'Remplacer le document'),
                style: FilledButton.styleFrom(shape: const StadiumBorder()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({required this.icon, required this.title, required this.description});
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFE2F1E9),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: GabColors.primary),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 2),
        Text(description, style: const TextStyle(color: GabColors.muted, fontSize: 11)),
      ],
    ),
  );
}

class SimpleFeatureScreen extends StatelessWidget {
  const SimpleFeatureScreen({
    required this.title,
    required this.icon,
    required this.description,
    super.key,
    this.actionLabel,
    this.nextRoute,
  });
  final String title;
  final IconData icon;
  final String description;
  final String? actionLabel;
  final String? nextRoute;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(icon, color: GabColors.primary, size: 56),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(description, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Card(
          child: ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Données minimales'),
            subtitle: Text(
              'Aucun détail médical n’est exposé au livreur. Les actions seront validées par l’API Django.',
            ),
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(height: 20),
          FilledButton(
            onPressed: nextRoute == null
                ? () {}
                : () => Navigator.pushNamed(context, nextRoute!),
            child: Text(actionLabel!),
          ),
        ],
      ],
    ),
  );
}

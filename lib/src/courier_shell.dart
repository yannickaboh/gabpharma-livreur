import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/auth_session.dart';
import 'core/courier_api.dart';
import 'core/theme.dart';
import 'widgets.dart';

class CourierShell extends StatefulWidget {
  const CourierShell({super.key});
  @override
  State<CourierShell> createState() => _CourierShellState();
}

class _CourierShellState extends State<CourierShell> {
  final _api = CourierApi.fromSession();
  int index = 0;
  bool online = false;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    try {
      final summary = await _api.fetchSummary();
      if (!mounted) return;
      setState(() => online = summary.availability.isAvailableForDelivery);
    } on ApiException {
      // Le statut reste tel quel (hors ligne par défaut) ; les écrans
      // enfants ont leur propre gestion d'erreur pour leurs propres appels.
    }
  }

  Future<void> _setOnline(bool value) async {
    final previous = online;
    setState(() => online = value);
    try {
      final availability = await _api.setAvailable(value);
      if (!mounted) return;
      setState(() => online = availability.isAvailableForDelivery);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => online = previous);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CourierHome(
        online: online,
        onOnlineChanged: _setOnline,
        onRefreshAvailability: _loadAvailability,
      ),
      AvailableDeliveries(online: online, onOnlineChanged: _setOnline),
      DeliveryHistory(online: online, onOnlineChanged: _setOnline),
      EarningsScreen(online: online, onOnlineChanged: _setOnline),
      CourierProfile(
        online: online,
        onOnlineChanged: _setOnline,
        onRefreshAvailability: _loadAvailability,
      ),
    ];
    return Scaffold(
      body: Column(
        children: [
          const SafeArea(bottom: false, child: DemoBanner()),
          Expanded(
            child: IndexedStack(index: index, children: pages),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            label: 'Courses',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'Historique'),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Revenus',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

String formatFcfa(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

const _frenchMonths = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

String _historyDateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return "Aujourd'hui";
  if (diff == 1) return 'Hier';
  return '${date.day} ${_frenchMonths[date.month - 1]} ${date.year}';
}

String _historyTimeLabel(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

class CourierHome extends StatefulWidget {
  const CourierHome({
    required this.online,
    required this.onOnlineChanged,
    required this.onRefreshAvailability,
    super.key,
  });
  final bool online;
  final ValueChanged<bool> onOnlineChanged;
  final Future<void> Function() onRefreshAvailability;

  @override
  State<CourierHome> createState() => _CourierHomeState();
}

class _CourierHomeState extends State<CourierHome> {
  final _api = CourierApi.fromSession();
  CourierSummary? _summary;
  List<CourierDelivery> _active = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.fetchSummary(),
        _api.fetchActiveDeliveries(),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as CourierSummary;
        _active = results[1] as List<CourierDelivery>;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  void _showUpdateInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mise à jour disponible'),
        content: const Text(
          'Version 2.4.1 disponible avec de nouveaux tracés GPS. '
          'La mise à jour se fait depuis le Play Store.',
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

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.instance.currentUser;
    final summary = _summary;
    return Column(
      children: [
        _HomeHeader(
          online: widget.online,
          onToggle: () => widget.onOnlineChanged(!widget.online),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _HomeErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Bonjour,',
                                  style: TextStyle(color: GabColors.muted),
                                ),
                                Text(
                                  user?.fullName ?? '',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: GabColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: GabColors.primary, width: 2),
                              color: GabColors.softGreen,
                            ),
                            child: Center(
                              child: Text(
                                user?.initials ?? '',
                                style: const TextStyle(
                                  color: GabColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_active.isNotEmpty) ...[
                        _ActiveCourseCard(
                          delivery: _active.first,
                          onTap: () => Navigator.pushNamed(context, '/active-delivery'),
                          onStartRoute: () => Navigator.pushNamed(context, '/map'),
                        ),
                        const SizedBox(height: 24),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.task_alt,
                              iconColor: GabColors.secondary,
                              caption: 'Total',
                              value: (summary?.completedCount ?? 0).toString().padLeft(2, '0'),
                              label: 'Courses terminées',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.payments_outlined,
                              iconColor: GabColors.routeBlue,
                              caption: 'Solde',
                              value: formatFcfa(summary?.balanceFcfa ?? 0),
                              label: (summary?.balanceFcfa ?? 0) >= 0
                                  ? 'FCFA à reverser'
                                  : 'FCFA à recevoir',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ALERTES & INFOS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: GabColors.muted,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/notifications'),
                            child: const Text(
                              'Tout voir',
                              style: TextStyle(
                                color: GabColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _showUpdateInfo(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCECE3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: GabColors.secondary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.info,
                                  color: GabColors.secondary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mise à jour disponible',
                                      style: TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      'Version 2.4.1 disponible avec de nouveaux tracés GPS.',
                                      style: TextStyle(color: GabColors.muted),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: GabColors.muted),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'ZONE ACTUELLE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: GabColors.muted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          await Navigator.pushNamed(context, '/availability');
                          widget.onRefreshAvailability();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFBFE3D0), Color(0xFF8FCBAE)],
                            ),
                          ),
                          child: Stack(
                            children: [
                              const Positioned(
                                right: 16,
                                top: 16,
                                child: Icon(
                                  Icons.map_outlined,
                                  color: Colors.white70,
                                  size: 40,
                                ),
                              ),
                              Positioned(
                                left: 12,
                                right: 12,
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
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.circle,
                                        size: 10,
                                        color: GabColors.routeBlue,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          summary != null &&
                                                  summary.availability.coverageZoneLabels.isNotEmpty
                                              ? summary.availability.coverageZoneLabels.join(', ')
                                              : 'Aucune zone configurée',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
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
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _HomeErrorState extends StatelessWidget {
  const _HomeErrorState({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 40, color: GabColors.muted),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: GabColors.muted)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    ),
  );
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.online,
    required this.onToggle,
    this.title = "Gab'Pharma Livreur",
  });
  final bool online;
  final VoidCallback onToggle;
  final String title;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 1,
    shadowColor: Colors.black.withValues(alpha: 0.08),
    child: SafeArea(
      bottom: false,
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(
                Icons.delivery_dining,
                color: GabColors.primary,
                size: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: GabColors.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: online ? GabColors.softGreen : GabColors.background,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: GabColors.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: online
                              ? GabColors.primary
                              : GabColors.outlineVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        online ? 'EN LIGNE' : 'HORS LIGNE',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: online ? GabColors.primary : GabColors.muted,
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
    ),
  );
}

class _ActiveCourseCard extends StatelessWidget {
  const _ActiveCourseCard({
    required this.delivery,
    required this.onTap,
    required this.onStartRoute,
  });
  final CourierDelivery delivery;
  final VoidCallback onTap;
  final VoidCallback onStartRoute;

  @override
  Widget build(BuildContext context) => Material(
    color: GabColors.primary,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.route, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Destination',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              delivery.pharmacy.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8FE7A5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'COURSE ACTIVE',
                    style: TextStyle(
                      color: GabColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white24)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Client',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            delivery.recipientName ?? '—',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Statut',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            delivery.statusLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: onStartRoute,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: GabColors.primary,
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.navigation_outlined),
                label: const Text("Démarrer l'itinéraire"),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.caption,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final Color iconColor;
  final String caption;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: GabColors.outlineVariant.withValues(alpha: 0.4)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: iconColor, size: 20),
            Text(
              caption,
              style: const TextStyle(fontSize: 11, color: GabColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          value,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: GabColors.muted)),
      ],
    ),
  );
}

class AvailableDeliveries extends StatefulWidget {
  const AvailableDeliveries({
    required this.online,
    required this.onOnlineChanged,
    super.key,
  });
  final bool online;
  final ValueChanged<bool> onOnlineChanged;

  @override
  State<AvailableDeliveries> createState() => _AvailableDeliveriesState();
}

class _AvailableDeliveriesState extends State<AvailableDeliveries> {
  final _api = CourierApi.fromSession();
  List<CourierDelivery>? _deliveries;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AvailableDeliveries oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.online != widget.online) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final deliveries = await _api.fetchAvailableDeliveries();
      if (!mounted) return;
      setState(() {
        _deliveries = deliveries;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _HomeHeader(
        online: widget.online,
        onToggle: () => widget.onOnlineChanged(!widget.online),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _HomeErrorState(message: _error!, onRetry: _load)
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  children: [
                    const Text(
                      'Courses disponibles',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: GabColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Consultez les commandes en attente d'attribution.",
                      style: TextStyle(color: GabColors.muted),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA8F4B9).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF8CD79F)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info, color: GabColors.secondary, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Affectation manuelle par le Staff Gab'Pharma. Les "
                              'missions vous seront attribuées directement sur '
                              'votre interface active.',
                              style: TextStyle(color: GabColors.secondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if ((_deliveries ?? const []).isEmpty)
                      const _EmptyCoursesState()
                    else
                      for (final delivery in _deliveries!)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _AvailableCourseCard(
                            delivery: delivery,
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/available-detail',
                              arguments: {'deliveryId': delivery.id},
                            ),
                          ),
                        ),
                  ],
                ),
              ),
      ),
    ],
  );
}

class _AvailableCourseCard extends StatelessWidget {
  const _AvailableCourseCard({required this.delivery, required this.onTap});
  final CourierDelivery delivery;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: const Border(
            left: BorderSide(color: GabColors.primary, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delivery.pharmacy.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: GabColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: GabColors.muted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            delivery.zoneLabel,
                            style: const TextStyle(
                              color: GabColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: GabColors.outlineVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'En attente',
                    style: TextStyle(fontSize: 11, color: GabColors.muted),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: GabColors.outlineVariant),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PART LIVREUR EST.',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: GabColors.muted,
                  ),
                ),
                Text(
                  '${formatFcfa(delivery.courierShareFcfa)} FCFA',
                  style: const TextStyle(
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
    ),
  );
}

class _EmptyCoursesState extends StatelessWidget {
  const _EmptyCoursesState();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: GabColors.outlineVariant.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.pending_actions,
            size: 36,
            color: GabColors.muted,
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Plus aucune course en attente pour le moment dans votre secteur.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: GabColors.muted,
            ),
          ),
        ),
      ],
    ),
  );
}

enum _HistoryFilter { tout, livre, retourne, annule }

class DeliveryHistory extends StatefulWidget {
  const DeliveryHistory({
    required this.online,
    required this.onOnlineChanged,
    super.key,
  });
  final bool online;
  final ValueChanged<bool> onOnlineChanged;

  @override
  State<DeliveryHistory> createState() => _DeliveryHistoryState();
}

class _DeliveryHistoryState extends State<DeliveryHistory> {
  final _api = CourierApi.fromSession();
  _HistoryFilter _filter = _HistoryFilter.tout;
  List<CourierDelivery>? _deliveries;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final deliveries = await _api.fetchDeliveryHistory();
      if (!mounted) return;
      setState(() {
        _deliveries = deliveries;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  void _showEntryDetails(CourierDelivery entry) {
    final date = entry.historyDate;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.pharmacy.name),
        content: Text(
          '${entry.statusLabel}'
          '${date != null ? ' · ${_historyDateLabel(date)} à ${_historyTimeLabel(date)}' : ''}\n'
          'Part livreur : ${formatFcfa(entry.courierShareFcfa)} FCFA'
          '${entry.orderReference != null ? '\nCommande ${entry.orderReference}' : ''}',
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

  void _showMonthPicker() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Sélection par mois disponible une fois l’historique complet connecté à l’API.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deliveries = _deliveries ?? const <CourierDelivery>[];
    final filtered = deliveries.where((entry) => switch (_filter) {
      _HistoryFilter.tout => true,
      _HistoryFilter.livre => entry.status == 'delivered',
      _HistoryFilter.retourne => entry.status == 'returned',
      _HistoryFilter.annule => entry.status == 'cancelled',
    }).toList();
    final groups = <String, List<CourierDelivery>>{};
    for (final entry in filtered) {
      final date = entry.historyDate;
      final label = date != null ? _historyDateLabel(date) : 'Date inconnue';
      groups.putIfAbsent(label, () => []).add(entry);
    }
    final now = DateTime.now();
    final thisMonthCount = deliveries.where((entry) {
      final date = entry.historyDate;
      return date != null && date.year == now.year && date.month == now.month;
    }).length;
    // Part livreur des courses effectivement livrées uniquement — le solde
    // faisant autorité (avances/retenues comprises) reste celui du ledger
    // (onglet Revenus), pas encore branché sur ce même total.
    final totalEarningsFcfa = deliveries
        .where((entry) => entry.status == 'delivered')
        .fold<int>(0, (sum, entry) => sum + entry.courierShareFcfa);
    final monthName = _frenchMonths[now.month - 1];
    final monthLabel = '${monthName[0].toUpperCase()}${monthName.substring(1)} ${now.year}';

    return Column(
      children: [
        _HomeHeader(
          title: 'Historique',
          online: widget.online,
          onToggle: () => widget.onOnlineChanged(!widget.online),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _HomeErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    children: [
                      Row(
                        children: [
                          Expanded(child: _HistoryStatCard('Total Courses', '${deliveries.length}')),
                          const SizedBox(width: 12),
                          Expanded(child: _HistoryStatCard('Ce Mois', '$thisMonthCount')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA8F4B9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Revenus Totaux',
                              style: TextStyle(color: Color(0xFF287243), fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${formatFcfa(totalEarningsFcfa)} FCFA',
                              style: const TextStyle(
                                color: Color(0xFF287243),
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _FilterPill(
                              label: 'Tout',
                              selected: _filter == _HistoryFilter.tout,
                              onTap: () => setState(() => _filter = _HistoryFilter.tout),
                            ),
                            const SizedBox(width: 8),
                            _FilterPill(
                              label: 'Livré',
                              selected: _filter == _HistoryFilter.livre,
                              onTap: () => setState(() => _filter = _HistoryFilter.livre),
                            ),
                            const SizedBox(width: 8),
                            _FilterPill(
                              label: 'Retourné',
                              selected: _filter == _HistoryFilter.retourne,
                              onTap: () => setState(() => _filter = _HistoryFilter.retourne),
                            ),
                            const SizedBox(width: 8),
                            _FilterPill(
                              label: 'Annulé',
                              selected: _filter == _HistoryFilter.annule,
                              onTap: () => setState(() => _filter = _HistoryFilter.annule),
                            ),
                            const SizedBox(width: 8),
                            _FilterPill(
                              label: monthLabel,
                              icon: Icons.calendar_month,
                              selected: false,
                              onTap: _showMonthPicker,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'Aucune course pour ce filtre.',
                              style: TextStyle(color: GabColors.muted),
                            ),
                          ),
                        )
                      else
                        for (final group in groups.entries) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                            child: Text(
                              group.key,
                              style: const TextStyle(
                                color: GabColors.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          for (final entry in group.value)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _HistoryEntryCard(
                                entry: entry,
                                onTap: () => _showEntryDetails(entry),
                              ),
                            ),
                        ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _HistoryStatCard extends StatelessWidget {
  const _HistoryStatCard(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: GabColors.outlineVariant.withValues(alpha: 0.4)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: GabColors.muted, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: GabColors.primary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? GabColors.primary : const Color(0xFFDCECE3),
    borderRadius: BorderRadius.circular(999),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? Colors.white : GabColors.muted),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : GabColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({required this.entry, required this.onTap});
  final CourierDelivery entry;
  final VoidCallback onTap;

  static const _statusColors = {
    'delivered': GabColors.secondary,
    'returned': GabColors.warning,
    'cancelled': GabColors.danger,
  };

  static const _statusIcons = {
    'delivered': Icons.task_alt,
    'returned': Icons.assignment_return,
    'cancelled': Icons.cancel,
  };

  // Libellés courts pour le badge (le statusLabel complet du backend, ex.
  // "Retournée à la pharmacie", est trop long pour ce badge en ligne avec
  // l'heure — le libellé complet reste affiché dans le dialogue de détail.
  static const _statusBadgeLabels = {
    'delivered': 'LIVRÉ',
    'returned': 'RETOUR',
    'cancelled': 'ANNULÉ',
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[entry.status] ?? GabColors.muted;
    final icon = _statusIcons[entry.status] ?? Icons.help_outline;
    final badgeLabel = _statusBadgeLabels[entry.status] ?? entry.statusLabel.toUpperCase();
    final date = entry.historyDate;
    final isDelivered = entry.status == 'delivered';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GabColors.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.pharmacy.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${formatFcfa(entry.courierShareFcfa)} FCFA',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isDelivered ? GabColors.primary : GabColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          date != null ? _historyTimeLabel(date) : '',
                          style: const TextStyle(color: GabColors.muted, fontSize: 12),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeLabel,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: GabColors.outlineVariant),
            ],
          ),
        ),
      ),
    );
  }
}

enum _EarningsPeriod { quotidien, hebdomadaire }

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({
    required this.online,
    required this.onOnlineChanged,
    super.key,
  });
  final bool online;
  final ValueChanged<bool> onOnlineChanged;

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

/// Aucun agregat quotidien/hebdomadaire ni repartition especes/electronique
/// n'existe cote API (Option A actee, voir `api_contrat_besoins.md` §3.3) :
/// tout est recalcule ici depuis les ecritures brutes de
/// `GET /mobile/courier/ledger/` (jusqu'a 50, non paginees).
///
/// Decouverte en branchant ce module : le ledger n'a pas de notion
/// "especes/electronique" a proprement parler. `cod_commission` (positif)
/// est la commission que le livreur doit reverser apres avoir deja encaisse
/// une course payee en especes ; `electronic_earning`/`return_earning`
/// (negatifs) sont les parts que Gab'Pharma doit au livreur. Plutot que de
/// forcer un mapping especes/electronique qui n'existe pas cote backend, les
/// deux tuiles ci-dessous regroupent honnetement les ecritures par signe
/// (du a Gab'Pharma vs du par Gab'Pharma), coherent avec la convention deja
/// utilisee pour le libelle du solde ("a reverser"/"a recevoir").
class _EarningsScreenState extends State<EarningsScreen> {
  final _api = CourierApi.fromSession();
  _EarningsPeriod _period = _EarningsPeriod.quotidien;
  CourierLedger? _ledger;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ledger = await _api.fetchLedger();
      if (!mounted) return;
      setState(() {
        _ledger = ledger;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  bool _inPeriod(DateTime date, _EarningsPeriod period) {
    final now = DateTime.now();
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    if (period == _EarningsPeriod.quotidien) return day == today;
    final monday = today.subtract(Duration(days: now.weekday - 1));
    return !day.isBefore(monday) && !day.isAfter(today);
  }

  void _showSplitInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mouvements du compte'),
        content: const Text(
          'Chaque ligne reflète une écriture réelle de votre compte livreur. '
          'Une commission « due à Gab’Pharma » apparaît quand vous avez déjà '
          'encaissé une course payée en espèces (vous gardez 60 %, vous '
          'devez reverser les 40 % restants). Un montant « dû par '
          'Gab’Pharma » apparaît pour une course payée en ligne, ou après '
          'une indemnité de retour patient — la plateforme vous doit alors '
          'votre part de 60 %.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  void _requestPayout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Demande de virement indisponible en démonstration — sera activée '
          'avec la connexion au système de paiement Gab’Pharma.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeekly = _period == _EarningsPeriod.hebdomadaire;
    final ledger = _ledger;
    final entries = ledger?.entries ?? const <CourierLedgerEntry>[];
    final periodEntries = entries
        .where((e) => e.createdAt != null && _inPeriod(e.createdAt!, _period))
        .toList();
    final owedToPlatformFcfa = periodEntries
        .where((e) => e.amountFcfa > 0)
        .fold<int>(0, (sum, e) => sum + e.amountFcfa);
    final owedByPlatformFcfa = periodEntries
        .where((e) => e.amountFcfa < 0)
        .fold<int>(0, (sum, e) => sum - e.amountFcfa);
    final balanceFcfa = ledger?.balanceFcfa ?? 0;

    return Column(
      children: [
        _HomeHeader(
          title: 'Revenus',
          online: widget.online,
          onToggle: () => widget.onOnlineChanged(!widget.online),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _HomeErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: GabColors.primary,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Solde actuel',
                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${formatFcfa(balanceFcfa.abs())} FCFA',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    balanceFcfa >= 0 ? 'À reverser à Gab’Pharma' : 'À recevoir de Gab’Pharma',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2F1E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _PeriodTab(
                                label: 'Quotidien',
                                selected: !isWeekly,
                                onTap: () => setState(() => _period = _EarningsPeriod.quotidien),
                              ),
                            ),
                            Expanded(
                              child: _PeriodTab(
                                label: 'Hebdomadaire',
                                selected: isWeekly,
                                onTap: () => setState(() => _period = _EarningsPeriod.hebdomadaire),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _EarningsBentoCard(
                              icon: Icons.arrow_upward,
                              iconColor: GabColors.warning,
                              label: 'Dû à Gab’Pharma',
                              value: '${formatFcfa(owedToPlatformFcfa)} FCFA',
                              caption: 'Commissions espèces (40 %)',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _EarningsBentoCard(
                              icon: Icons.arrow_downward,
                              iconColor: GabColors.primary,
                              label: 'Dû par Gab’Pharma',
                              value: '${formatFcfa(owedByPlatformFcfa)} FCFA',
                              caption: 'Part livreur due (60 %)',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mouvements du compte',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          IconButton(
                            onPressed: _showSplitInfo,
                            icon: const Icon(Icons.info_outline, color: GabColors.muted),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (entries.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'Aucun mouvement pour le moment.',
                              style: TextStyle(color: GabColors.muted),
                            ),
                          ),
                        )
                      else
                        for (final entry in entries)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _LedgerEntryCard(entry: entry),
                          ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _requestPayout,
                          icon: const Icon(Icons.account_balance_outlined),
                          label: const Text('Demander un virement'),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? Colors.white : Colors.transparent,
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? GabColors.primary : GabColors.muted,
          ),
        ),
      ),
    ),
  );
}

class _EarningsBentoCard extends StatelessWidget {
  const _EarningsBentoCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.caption,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: GabColors.outlineVariant.withValues(alpha: 0.4)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: GabColors.muted, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          caption,
          style: const TextStyle(color: GabColors.muted, fontSize: 10),
        ),
      ],
    ),
  );
}

/// Carte de mouvement de compte, derivee uniquement de ce que renvoie
/// `GET /mobile/courier/ledger/` — pas de pharmacie ni de code de course
/// (`GP-xxxx`) ici, contrairement a l'Historique, car l'endpoint ledger ne
/// les expose pas (voir doc du fichier `courier_api.dart`).
class _LedgerEntryCard extends StatelessWidget {
  const _LedgerEntryCard({required this.entry});
  final CourierLedgerEntry entry;

  static const _typeBadgeLabels = {
    'cod_commission': 'ESPÈCES',
    'electronic_earning': 'ÉLECTRONIQUE',
    'return_earning': 'RETOUR PATIENT',
    'courier_settlement': 'RÈGLEMENT',
    'platform_payout': 'VERSEMENT',
    'adjustment': 'AJUSTEMENT',
  };

  static const _typeBadgeColors = {
    'cod_commission': GabColors.warning,
    'electronic_earning': GabColors.routeBlue,
    'return_earning': GabColors.routeBlue,
    'courier_settlement': GabColors.warning,
    'platform_payout': GabColors.primary,
    'adjustment': GabColors.muted,
  };

  @override
  Widget build(BuildContext context) {
    final isCredit = entry.amountFcfa < 0;
    final badgeLabel = _typeBadgeLabels[entry.entryType] ?? entry.entryTypeLabel.toUpperCase();
    final badgeColor = _typeBadgeColors[entry.entryType] ?? GabColors.muted;
    final date = entry.createdAt;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GabColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.entryTypeLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  entry.reason.isNotEmpty ? entry.reason : 'Réf. ${entry.reference}',
                  style: const TextStyle(color: GabColors.muted, fontSize: 12),
                ),
                if (date != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${_historyDateLabel(date)} à ${_historyTimeLabel(date)}',
                    style: const TextStyle(color: GabColors.muted, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '−'}${formatFcfa(entry.amountFcfa.abs())} FCFA',
                style: TextStyle(
                  color: isCredit ? GabColors.primary : GabColors.danger,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CourierProfile extends StatefulWidget {
  const CourierProfile({
    required this.online,
    required this.onOnlineChanged,
    required this.onRefreshAvailability,
    super.key,
  });
  final bool online;
  final ValueChanged<bool> onOnlineChanged;
  final Future<void> Function() onRefreshAvailability;

  @override
  State<CourierProfile> createState() => _CourierProfileState();
}

class _CourierProfileState extends State<CourierProfile> {
  final _api = CourierApi.fromSession();
  AuthUser? _user;
  String _vehicleTypeLabel = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.fetchProfile(),
        _api.fetchAvailability(),
      ]);
      if (!mounted) return;
      setState(() {
        _user = results[0] as AuthUser;
        _vehicleTypeLabel = (results[1] as CourierAvailability).vehicleTypeLabel;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _HomeHeader(
        online: widget.online,
        onToggle: () => widget.onOnlineChanged(!widget.online),
        title: 'Mon Profil',
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _HomeErrorState(message: _error!, onRetry: _load)
            : _buildContent(context),
      ),
    ],
  );

  Widget _buildContent(BuildContext context) {
    final user = _user!;
    final vehicleLabel = _vehicleTypeLabel.isEmpty ? 'Non renseigné' : _vehicleTypeLabel;
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GabColors.primary,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          user.initials,
                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Material(
                        color: GabColors.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _showInfoDialog(
                            context,
                            'Photo de profil',
                            'Changement de photo indisponible en démonstration — sera activé une fois l’application connectée au stockage sécurisé de l’API.',
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.photo_camera, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  user.fullName.isEmpty ? user.email : user.fullName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  user.phone.isEmpty ? user.email : user.phone,
                  style: const TextStyle(color: GabColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _ProfileSection(
            title: 'Sécurité & Compte',
            rows: [
              _ProfileRow(
                icon: Icons.lock_outline,
                label: 'Changer mot de passe',
                onTap: () => Navigator.pushNamed(context, '/security'),
              ),
              _ProfileRow(
                icon: Icons.two_wheeler_outlined,
                label: 'Véhicule',
                subtitle: vehicleLabel,
                onTap: () => _showInfoDialog(
                  context,
                  'Véhicule',
                  'Type de véhicule enregistré : $vehicleLabel. Gab’Pharma ne suit pas de numéro '
                      'd’immatriculation dans l’application — la modification du véhicule affecté se '
                      'fait auprès du Staff Gab’Pharma, pas directement dans l’application.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ProfileSection(
            title: 'Opérations',
            rows: [
              _ProfileRow(
                icon: Icons.map_outlined,
                label: 'Zones et disponibilité',
                onTap: () async {
                  await Navigator.pushNamed(context, '/availability');
                  widget.onRefreshAvailability();
                  _load();
                },
              ),
              _ProfileRow(
                icon: Icons.badge_outlined,
                label: 'Documents',
                onTap: () => Navigator.pushNamed(context, '/documents'),
              ),
              _ProfileRow(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () => Navigator.pushNamed(context, '/notifications'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ProfileSection(
            title: 'Informations',
            rows: [
              _ProfileRow(
                icon: Icons.privacy_tip_outlined,
                label: 'Confidentialité',
                onTap: () => _showInfoDialog(
                  context,
                  'Confidentialité',
                  'Gab’Pharma collecte uniquement les données nécessaires à la gestion de vos '
                      'courses (position pendant une livraison active, historique, documents '
                      'administratifs). Ces données sont traitées conformément aux lois de '
                      'protection des données personnelles en vigueur au Gabon.',
                ),
              ),
              _ProfileRow(
                icon: Icons.support_agent,
                label: 'Support',
                onTap: () => Navigator.pushNamed(context, '/support'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                await AuthSession.instance.logout();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Déconnexion'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFDAD6),
                foregroundColor: const Color(0xFF93000A),
                elevation: 0,
                shape: const StadiumBorder(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Version 1.0.4',
            textAlign: TextAlign.center,
            style: TextStyle(color: GabColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.rows});
  final String title;
  final List<_ProfileRow> rows;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: GabColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 0.6,
            ),
          ),
        ),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Divider(height: 1, color: Color(0x33BEC9BD)),
            ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: rows[i].onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(color: Color(0xFFDCECE3), shape: BoxShape.circle),
                      child: Icon(rows[i].icon, color: GabColors.primary, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rows[i].label, style: const TextStyle(fontSize: 15)),
                          if (rows[i].subtitle != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                rows[i].subtitle!,
                                style: const TextStyle(color: GabColors.muted, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: GabColors.outlineVariant),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

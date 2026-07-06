import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'widgets.dart';

class CourierShell extends StatefulWidget {
  const CourierShell({super.key});
  @override
  State<CourierShell> createState() => _CourierShellState();
}

class _CourierShellState extends State<CourierShell> {
  int index = 0;
  bool online = true;

  @override
  Widget build(BuildContext context) {
    final pages = [
      CourierHome(
        online: online,
        onOnlineChanged: (value) => setState(() => online = value),
      ),
      const AvailableDeliveries(),
      const DeliveryHistory(),
      const EarningsScreen(),
      const CourierProfile(),
    ];
    return Scaffold(
      body: Column(
        children: [
          const DemoBanner(),
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

class CourierHome extends StatelessWidget {
  const CourierHome({
    required this.online,
    required this.onOnlineChanged,
    super.key,
  });
  final bool online;
  final ValueChanged<bool> onOnlineChanged;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour, Junior',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                      Text('Une course active vous attend'),
                    ],
                  ),
                ),
                Switch(value: online, onChanged: onOnlineChanged),
                Text(
                  online ? 'En ligne' : 'Hors ligne',
                  style: TextStyle(
                    color: online ? GabColors.primary : GabColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SectionTitle('Course active'),
            Card(
              color: GabColors.primary,
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, '/active-delivery'),
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatusPill('Affectée', color: Colors.white),
                      SizedBox(height: 18),
                      Text(
                        'Pharmacie du Centre',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Collecte à Libreville Centre',
                        style: TextStyle(color: Colors.white70),
                      ),
                      SizedBox(height: 18),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: Colors.white),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Destination : Akanda',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SectionTitle('Aujourd’hui'),
            const Row(
              children: [
                Expanded(child: _Metric('3', 'Terminées')),
                SizedBox(width: 12),
                Expanded(child: _Metric('9 600', 'FCFA générés')),
              ],
            ),
            const SectionTitle('Alertes'),
            Card(
              child: ListTile(
                onTap: () => Navigator.pushNamed(context, '/documents'),
                leading:
                    const Icon(Icons.badge_outlined, color: GabColors.warning),
                title: const Text('Document bientôt expiré'),
                subtitle: const Text(
                  'Déposez une nouvelle version avant le 20/07.',
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ],
        ),
      );
}

class _Metric extends StatelessWidget {
  const _Metric(this.value, this.label);
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              Text(label),
            ],
          ),
        ),
      );
}

class AvailableDeliveries extends StatelessWidget {
  const AvailableDeliveries({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Courses', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            const Text('Consultation uniquement · affectation par le Staff'),
            const SectionTitle('Compatibles avec vos zones'),
            for (final delivery in const [
              ('Centre → Akanda', '2 400 FCFA'),
              ('Owendo → Libreville', '3 100 FCFA'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    onTap: () =>
                        Navigator.pushNamed(context, '/available-detail'),
                    leading: const CircleAvatar(
                      backgroundColor: GabColors.softGreen,
                      child:
                          Icon(Icons.delivery_dining, color: GabColors.primary),
                    ),
                    title: Text(
                      delivery.$1,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text('Pharmacie partenaire · aujourd’hui'),
                    trailing: Text(delivery.$2),
                  ),
                ),
              ),
          ],
        ),
      );
}

class DeliveryHistory extends StatelessWidget {
  const DeliveryHistory({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Historique',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            for (final delivery in const [
              ('GP-L098', 'Livrée', '06/07/2026'),
              ('GP-L097', 'Livrée', '05/07/2026'),
              ('GP-L096', 'Annulée', '05/07/2026'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    title: Text(
                      'Course ${delivery.$1}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text('Libreville · ${delivery.$3}'),
                    trailing: StatusPill(
                      delivery.$2,
                      color: delivery.$2 == 'Annulée'
                          ? GabColors.danger
                          : GabColors.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Revenus', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 18),
            const Card(
              color: GabColors.primary,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Solde actuel',
                        style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 6),
                    Text(
                      '12 800 FCFA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'À reverser à Gab’Pharma',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SectionTitle('Écritures récentes'),
            const Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text('Course GP-L098'),
                    subtitle: Text('Espèces · part plateforme 40 %'),
                    trailing: Text('+1 600'),
                  ),
                  Divider(height: 1),
                  ListTile(
                    title: Text('Course GP-L097'),
                    subtitle: Text('Électronique · part livreur 40 %'),
                    trailing: Text('−1 200'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class CourierProfile extends StatelessWidget {
  const CourierProfile({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Mon profil',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 18),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: GabColors.primary,
                      child: Text('JM', style: TextStyle(color: Colors.white)),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Junior Moussavou',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text('Moto · GA-204-LB'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (final item in const [
              ('Zones et disponibilité', Icons.map_outlined, '/availability'),
              ('Documents', Icons.badge_outlined, '/documents'),
              ('Notifications', Icons.notifications_outlined, '/notifications'),
              ('Support', Icons.support_agent, '/support'),
              ('Profil et sécurité', Icons.security_outlined, '/security'),
            ])
              Card(
                child: ListTile(
                  onTap: () => Navigator.pushNamed(context, item.$3),
                  leading: Icon(item.$2),
                  title: Text(item.$1),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
            ),
          ],
        ),
      );
}

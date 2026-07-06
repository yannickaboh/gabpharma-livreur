import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'widgets.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  const ActiveDeliveryScreen({super.key});
  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  int step = 0;
  static const labels = ['Affectée', 'Collectée', 'En livraison', 'Livrée'];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Course GP-L104')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: StatusPill(
            labels[step],
            color: step == 2 ? GabColors.routeBlue : GabColors.primary,
          ),
        ),
        const SectionTitle('Itinéraire'),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.local_pharmacy, color: GabColors.primary),
                  title: Text('Pharmacie du Centre'),
                  subtitle: Text('Collecte · Libreville Centre'),
                ),
                Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.location_on, color: GabColors.routeBlue),
                  title: Text('Akanda'),
                  subtitle: Text('Adresse complète visible après collecte'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          onPressed: () => Navigator.pushNamed(context, '/map'),
          icon: const Icon(Icons.navigation_outlined),
          label: const Text('Ouvrir la navigation'),
        ),
        const SectionTitle('Action requise'),
        if (step == 2)
          const TextField(
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'Code de remise OTP',
              prefixIcon: Icon(Icons.password),
            ),
          ),
        FilledButton(
          onPressed: step == 3 ? null : () => setState(() => step++),
          child: Text(switch (step) {
            0 => 'Confirmer la collecte',
            1 => 'Démarrer la livraison',
            2 => 'Confirmer la remise',
            _ => 'Course terminée',
          }),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/incident'),
          icon: const Icon(Icons.report_problem_outlined),
          label: const Text('Signaler un incident'),
        ),
      ],
    ),
  );
}

class IncidentScreen extends StatelessWidget {
  const IncidentScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Signaler un incident')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const DropdownMenu(
          expandedInsets: EdgeInsets.zero,
          label: Text('Type'),
          dropdownMenuEntries: [
            DropdownMenuEntry(value: 'delay', label: 'Retard'),
            DropdownMenuEntry(value: 'address', label: 'Adresse introuvable'),
            DropdownMenuEntry(value: 'vehicle', label: 'Problème de véhicule'),
          ],
        ),
        const SizedBox(height: 14),
        const DropdownMenu(
          expandedInsets: EdgeInsets.zero,
          label: Text('Gravité'),
          dropdownMenuEntries: [
            DropdownMenuEntry(value: 'low', label: 'Faible'),
            DropdownMenuEntry(value: 'medium', label: 'Moyenne'),
            DropdownMenuEntry(value: 'high', label: 'Élevée'),
          ],
        ),
        const SizedBox(height: 14),
        const TextField(
          maxLines: 5,
          decoration: InputDecoration(labelText: 'Description'),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Envoyer au Staff'),
        ),
        const SizedBox(height: 10),
        const Text(
          'Le signalement n’annule pas automatiquement la course.',
          textAlign: TextAlign.center,
        ),
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

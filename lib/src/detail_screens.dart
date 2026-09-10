import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'core/api_client.dart';
import 'core/courier_api.dart';
import 'core/theme.dart';
import 'courier_shell.dart' show formatFcfa;

class AvailableCourseDetailScreen extends StatefulWidget {
  const AvailableCourseDetailScreen({required this.deliveryId, super.key});
  final int? deliveryId;

  @override
  State<AvailableCourseDetailScreen> createState() => _AvailableCourseDetailScreenState();
}

class _AvailableCourseDetailScreenState extends State<AvailableCourseDetailScreen> {
  final _api = CourierApi.fromSession();
  CourierDelivery? _delivery;
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
      final deliveries = await _api.fetchAvailableDeliveries();
      if (!mounted) return;
      final match = deliveries.where((d) => d.id == widget.deliveryId).toList();
      setState(() {
        _delivery = match.isEmpty ? null : match.first;
        _error = match.isEmpty
            ? "Cette course n'est plus disponible — elle a peut-être déjà été affectée à un autre livreur."
            : null;
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

  void _applyForCourse(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Candidature'),
        content: const Text(
          "La candidature en libre-service n'est pas encore disponible — "
          "l'affectation des courses reste manuelle, décidée par le Staff "
          "Gab'Pharma.",
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

  @override
  Widget build(BuildContext context) {
    final delivery = _delivery;
    return Scaffold(
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
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null || delivery == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline, size: 40, color: GabColors.muted),
                      const SizedBox(height: 12),
                      Text(
                        _error ?? 'Course introuvable.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: GabColors.muted),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
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
                              Text(
                                delivery.pharmacy.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: GabColors.primary,
                                ),
                              ),
                              Text(
                                delivery.pharmacy.address.isNotEmpty
                                    ? delivery.pharmacy.address
                                    : delivery.pharmacy.zoneLabel,
                                style: const TextStyle(color: GabColors.muted),
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: GabColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    delivery.zoneLabel,
                                    style: const TextStyle(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Frais de livraison',
                          style: TextStyle(color: GabColors.muted),
                        ),
                        Text('${formatFcfa(delivery.deliveryFeeFcfa)} FCFA'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: GabColors.outlineVariant),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Commission Plateforme',
                                style: TextStyle(color: GabColors.muted),
                              ),
                              Text(
                                '- ${formatFcfa(delivery.platformShareFcfa)} FCFA',
                                style: const TextStyle(color: GabColors.danger),
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
                        Text(
                          '${formatFcfa(delivery.courierShareFcfa)} FCFA',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: GabColors.primary,
                          ),
                        ),
                      ],
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
}

class ActiveDeliveryScreen extends StatefulWidget {
  const ActiveDeliveryScreen({super.key});
  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  static const _positionPingInterval = Duration(seconds: 45);
  static const _positionActiveStatuses = {'assigned', 'picked_up', 'in_transit'};

  final _api = CourierApi.fromSession();
  CourierDelivery? _delivery;
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;
  Timer? _positionTimer;

  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _recipientNameController = TextEditingController();
  String? _otpError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
    _recipientNameController.dispose();
    super.dispose();
  }

  /// Demarre ou arrete le ping de position selon le statut reel de la course
  /// (voir cadrage_suivi_temps_reel_livreur.md cote depot Django : jamais de
  /// position hors course active, jamais en arriere-plan pour ce premier jet).
  void _syncPositionTimer() {
    final shouldPing = _positionActiveStatuses.contains(_delivery?.status);
    if (shouldPing && _positionTimer == null) {
      _positionTimer = Timer.periodic(_positionPingInterval, (_) => _sendPositionPing());
      _sendPositionPing();
    } else if (!shouldPing && _positionTimer != null) {
      _positionTimer?.cancel();
      _positionTimer = null;
    }
  }

  Future<void> _sendPositionPing() async {
    final delivery = _delivery;
    if (delivery == null) return;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await _api.updatePosition(
        delivery.id,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      // Best-effort : la position n'est jamais critique pour la livraison
      // elle-meme, un echec (GPS coupe, pas de reseau...) doit rester silencieux.
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final active = await _api.fetchActiveDeliveries();
      if (!mounted) return;
      setState(() {
        _delivery = active.isEmpty ? null : active.first;
        _error = active.isEmpty ? 'Aucune course active pour le moment.' : null;
        _loading = false;
        if (_delivery?.recipientName != null) {
          _recipientNameController.text = _delivery!.recipientName!;
        }
      });
      _syncPositionTimer();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  void _callClient(BuildContext context) {
    final delivery = _delivery!;
    final name = delivery.recipientName ?? 'le patient';
    final phone = delivery.patientPhone;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appeler le patient'),
        content: Text(
          phone != null
              ? 'Appelez $name au $phone depuis votre téléphone.'
              : 'Aucun numéro de téléphone renseigné pour $name.',
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

  Future<void> _pickup() async {
    if (_actionLoading) return;
    setState(() => _actionLoading = true);
    try {
      final delivery = await _api.pickupDelivery(_delivery!.id);
      if (!mounted) return;
      setState(() {
        _delivery = delivery;
        _actionLoading = false;
      });
      _syncPositionTimer();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _actionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _start() async {
    if (_actionLoading) return;
    setState(() => _actionLoading = true);
    try {
      final delivery = await _api.startDelivery(_delivery!.id);
      if (!mounted) return;
      setState(() {
        _delivery = delivery;
        _actionLoading = false;
      });
      _syncPositionTimer();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _actionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _resendOtp() async {
    if (_actionLoading) return;
    setState(() => _actionLoading = true);
    try {
      final delivery = await _api.resendProofCode(_delivery!.id);
      if (!mounted) return;
      for (final controller in _otpControllers) {
        controller.clear();
      }
      _otpFocusNodes.first.requestFocus();
      setState(() {
        _delivery = delivery;
        _otpError = null;
        _actionLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nouveau code envoyé au patient.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _actionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _confirmDelivery() async {
    if (_actionLoading) return;
    final recipientName = _recipientNameController.text.trim();
    if (recipientName.isEmpty) {
      setState(() => _otpError = 'Le nom du destinataire est obligatoire.');
      return;
    }
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length != 6) {
      setState(() => _otpError = 'Saisissez les 6 chiffres du code.');
      return;
    }
    setState(() {
      _actionLoading = true;
      _otpError = null;
    });
    try {
      final delivery = await _api.completeDelivery(
        _delivery!.id,
        proofCode: code,
        recipientName: recipientName,
      );
      if (!mounted) return;
      setState(() {
        _delivery = delivery;
        _actionLoading = false;
      });
      _syncPositionTimer();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _actionLoading = false);
      if (error.code == 'invalid_proof_code') {
        setState(() => _otpError = error.message);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _reportPatientAbsence() async {
    final descriptionController = TextEditingController();
    bool contactAttemptsConfirmed = false;
    bool waitConfirmed = false;
    bool submitting = false;
    String? sheetError;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Client absent',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Cette déclaration engage un retour obligatoire de la commande '
                'à la pharmacie — confirmez les deux étapes ci-dessous avant de continuer.',
                style: TextStyle(color: GabColors.muted),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: contactAttemptsConfirmed,
                onChanged: (value) =>
                    setSheetState(() => contactAttemptsConfirmed = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text("J'ai appelé le patient au moins deux fois"),
              ),
              CheckboxListTile(
                value: waitConfirmed,
                onChanged: (value) => setSheetState(() => waitConfirmed = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text("J'ai attendu au moins dix minutes sur place"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Décrivez les tentatives de contact effectuées...',
                ),
              ),
              if (sheetError != null) ...[
                const SizedBox(height: 8),
                Text(sheetError!, style: const TextStyle(color: GabColors.danger)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          if (!contactAttemptsConfirmed || !waitConfirmed) {
                            setSheetState(
                              () => sheetError = 'Confirmez les deux étapes ci-dessus.',
                            );
                            return;
                          }
                          final description = descriptionController.text.trim();
                          if (description.isEmpty) {
                            setSheetState(
                              () => sheetError = 'La description est obligatoire.',
                            );
                            return;
                          }
                          setSheetState(() {
                            submitting = true;
                            sheetError = null;
                          });
                          try {
                            final result = await _api.reportPatientAbsence(
                              _delivery!.id,
                              contactAttemptsConfirmed: contactAttemptsConfirmed,
                              waitConfirmed: waitConfirmed,
                              description: description,
                            );
                            if (!mounted) return;
                            if (sheetContext.mounted) Navigator.pop(sheetContext);
                            setState(() => _delivery = result.delivery);
                            _syncPositionTimer();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Absence déclarée — retour à la pharmacie requis.',
                                ),
                              ),
                            );
                          } on ApiException catch (error) {
                            setSheetState(() {
                              submitting = false;
                              sheetError = error.message;
                            });
                          }
                        },
                  child: submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Confirmer l'absence du patient"),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
    descriptionController.dispose();
  }

  int _stepForStatus(String status) => switch (status) {
    'assigned' => 0,
    'picked_up' => 1,
    'in_transit' => 2,
    'returning' => 2,
    _ => 3,
  };

  String? _deadlineLabel(CourierDelivery delivery) {
    final deadline = delivery.deliveryDeadline;
    if (deadline == null) return null;
    final local = deadline.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return delivery.isLate ? 'En retard (limite $hh:$mm)' : 'Limite $hh:$mm';
  }

  Widget _statusPanel(CourierDelivery delivery) {
    switch (delivery.status) {
      case 'assigned':
        return _StepPanel(
          title: 'Course affectée',
          body: 'Rendez-vous à la pharmacie pour récupérer la commande.',
          buttonLabel: 'Confirmer la collecte',
          loading: _actionLoading,
          onPressed: _pickup,
        );
      case 'picked_up':
        return _StepPanel(
          title: 'Collecte effectuée',
          body: 'Démarrez la livraison vers le patient.',
          buttonLabel: 'Démarrer la livraison',
          loading: _actionLoading,
          onPressed: _start,
        );
      case 'in_transit':
        return Container(
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
                'Saisissez le code OTP reçu par le patient',
                textAlign: TextAlign.center,
                style: TextStyle(color: GabColors.muted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _recipientNameController,
                decoration: const InputDecoration(labelText: 'Nom du destinataire'),
                onChanged: (_) {
                  if (_otpError != null) setState(() => _otpError = null);
                },
              ),
              const SizedBox(height: 16),
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
                  onPressed: _actionLoading ? null : _confirmDelivery,
                  icon: const Icon(Icons.task_alt),
                  label: const Text('Valider la remise (OTP)'),
                ),
              ),
              TextButton.icon(
                onPressed: _actionLoading ? null : _resendOtp,
                icon: const Icon(Icons.refresh),
                label: const Text('Renvoyer OTP'),
              ),
            ],
          ),
        );
      case 'returning':
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: GabColors.warning.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              const Icon(Icons.assignment_return, color: GabColors.warning, size: 40),
              const SizedBox(height: 10),
              const Text(
                'Retour à la pharmacie en cours',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const SizedBox(height: 6),
              Text(
                'Absence du patient confirmée. Ramenez la commande à '
                '${delivery.pharmacy.name} — le retour sera validé par le Staff '
                "Gab'Pharma.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: GabColors.muted),
              ),
            ],
          ),
        );
      case 'delivered':
        return Container(
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
        );
      default:
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: GabColors.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Text(
            delivery.statusLabel,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final delivery = _delivery;
    if (_error != null || delivery == null) {
      return Scaffold(
        backgroundColor: GabColors.background,
        appBar: AppBar(
          backgroundColor: GabColors.background,
          elevation: 0,
          title: const Text(
            'Course en cours',
            style: TextStyle(color: GabColors.primary, fontWeight: FontWeight.w800),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 40, color: GabColors.muted),
                const SizedBox(height: 12),
                Text(
                  _error ?? 'Course introuvable.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: GabColors.muted),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final deadlineLabel = _deadlineLabel(delivery);
    return Scaffold(
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
                _DeliveryTimeline(step: _stepForStatus(delivery.status)),
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
                            Text(
                              delivery.recipientName ?? 'Patient',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (delivery.patientPhone != null)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone,
                                    size: 14,
                                    color: GabColors.muted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    delivery.patientPhone!,
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
                    if (deadlineLabel != null)
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
                          child: Text(
                            deadlineLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: delivery.isLate ? GabColors.danger : GabColors.ink,
                            ),
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
                                Text(
                                  delivery.pharmacy.name,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
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
                                Text(
                                  delivery.deliveryAddress?.isNotEmpty == true
                                      ? '${delivery.deliveryAddress}, ${delivery.zoneLabel}'
                                      : delivery.zoneLabel,
                                  style: const TextStyle(
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
          _statusPanel(delivery),
          if (delivery.actions.canReportAbsence) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _reportPatientAbsence,
              style: OutlinedButton.styleFrom(
                foregroundColor: GabColors.warning,
                side: BorderSide(color: GabColors.warning.withValues(alpha: 0.4)),
              ),
              icon: const Icon(Icons.person_off_outlined),
              label: const Text('Client absent'),
            ),
          ],
          if (delivery.actions.canReportIncident) ...[
            const SizedBox(height: 12),
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
        ],
      ),
    ),
  );
  }
}

class _StepPanel extends StatelessWidget {
  const _StepPanel({
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.loading,
    required this.onPressed,
  });

  final String title;
  final String body;
  final String buttonLabel;
  final bool loading;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: GabColors.outlineVariant.withValues(alpha: 0.4)),
    ),
    child: Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: GabColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(color: GabColors.muted),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: loading ? null : onPressed,
            child: Text(buttonLabel),
          ),
        ),
      ],
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
  final _api = CourierApi.fromSession();
  CourierDelivery? _delivery;
  bool _loading = true;
  String? _error;

  static const _types = [
    ('delay', 'Retard'),
    ('recipient_unreachable', 'Destinataire injoignable'),
    ('wrong_address', 'Adresse incorrecte'),
    ('vehicle', 'Problème de véhicule'),
    ('package', 'Colis endommagé ou incomplet'),
    ('other', 'Autre'),
  ];
  static const _severityCodes = ['low', 'medium', 'high'];
  static const _severityLabels = ['Faible', 'Moyenne', 'Critique'];
  static const _severityColors = [
    GabColors.primary,
    GabColors.warning,
    GabColors.danger,
  ];

  String? _selectedTypeCode;
  int _severity = 0;
  final _descriptionController = TextEditingController();
  _ReportState _reportState = _ReportState.idle;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final active = await _api.fetchActiveDeliveries();
      if (!mounted) return;
      setState(() {
        _delivery = active.isEmpty ? null : active.first;
        _error = active.isEmpty
            ? "Aucune course active. Le signalement d'incident nécessite une course en cours."
            : null;
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

  Future<void> _submit() async {
    if (_reportState != _ReportState.idle) return;
    final typeCode = _selectedTypeCode;
    if (typeCode == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Sélectionnez un type d'incident.")));
      return;
    }
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Décrivez brièvement le problème.')));
      return;
    }
    setState(() => _reportState = _ReportState.sending);
    try {
      await _api.reportIncident(
        _delivery!.id,
        incidentType: typeCode,
        severity: _severityCodes[_severity],
        description: description,
      );
      if (!mounted) return;
      _descriptionController.clear();
      setState(() {
        _reportState = _ReportState.sent;
        _selectedTypeCode = null;
        _severity = 0;
      });
      await _reloadDelivery();
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() => _reportState = _ReportState.idle);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _reportState = _ReportState.idle);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _reloadDelivery() async {
    try {
      final active = await _api.fetchActiveDeliveries();
      if (!mounted) return;
      setState(() => _delivery = active.isEmpty ? _delivery : active.first);
    } on ApiException {
      // Rafraîchissement best-effort : on garde l'état précédent si ça échoue.
    }
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

  static IconData _iconForType(String type) => switch (type) {
    'delay' => Icons.schedule,
    'recipient_unreachable' => Icons.phone_disabled,
    'patient_absent' => Icons.person_off,
    'wrong_address' => Icons.wrong_location,
    'vehicle' => Icons.emergency,
    'package' => Icons.inventory_2,
    _ => Icons.report_problem,
  };

  static Color _colorForSeverityLabel(String severityLabel) => switch (severityLabel) {
    'Faible' => GabColors.primary,
    'Élevée' => GabColors.danger,
    _ => GabColors.warning,
  };

  static String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    return 'Il y a ${diff.inDays} j';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final delivery = _delivery;
    if (_error != null || delivery == null) {
      return Scaffold(
        backgroundColor: GabColors.background,
        appBar: AppBar(
          backgroundColor: GabColors.background,
          elevation: 0,
          title: const Text(
            'Signaler un incident',
            style: TextStyle(color: GabColors.primary, fontWeight: FontWeight.w800),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 40, color: GabColors.muted),
                const SizedBox(height: 12),
                Text(
                  _error ?? 'Course introuvable.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: GabColors.muted),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final openIncidents = delivery.incidents.where((i) => i.status == 'open').toList();
    return Scaffold(
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
                    initialValue: _selectedTypeCode,
                    isExpanded: true,
                    hint: const Text('Sélectionner le type'),
                    items: _types
                        .map(
                          (type) => DropdownMenuItem(
                            value: type.$1,
                            child: Text(type.$2, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _selectedTypeCode = value),
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
                  child: Text(
                    '${openIncidents.length} actif${openIncidents.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: GabColors.danger,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (openIncidents.isEmpty)
              const Text(
                'Aucun incident actif sur cette course.',
                style: TextStyle(color: GabColors.muted),
              )
            else
              for (final incident in openIncidents) ...[
                _OpenIncidentCard(
                  icon: _iconForType(incident.incidentType),
                  iconColor: _colorForSeverityLabel(incident.severityLabel),
                  iconBackground: _colorForSeverityLabel(
                    incident.severityLabel,
                  ).withValues(alpha: 0.12),
                  borderColor: _colorForSeverityLabel(incident.severityLabel),
                  title: incident.incidentTypeLabel,
                  statusLabel: incident.statusLabel,
                  statusColor: GabColors.danger,
                  description: incident.description,
                  timeAgo: _timeAgo(incident.createdAt),
                  onDetails: () => _showIncidentDetails(
                    context,
                    incident.incidentTypeLabel,
                    '${incident.description}\n\n'
                    'Statut : ${incident.statusLabel} · ${_timeAgo(incident.createdAt)}',
                  ),
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
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

/// Carte et navigation (ecran 09), branchee sur la vraie course active
/// (Option A : `fetchActiveDeliveries()`, meme pattern que `IncidentScreen`
/// et `ActiveDeliveryScreen` — un seul livreur n'a qu'une course active en
/// MVP). Vrai SDK `google_maps_flutter` : marker pharmacie (coordonnees
/// reelles, §3.4 du contrat) + marker livreur (position reelle via
/// `geolocator`, meme mecanisme que le ping envoye pendant la course active).
/// Aucune coordonnee n'existe cote backend pour l'adresse de livraison
/// (texte libre uniquement) : pas de marker destination invente, l'adresse
/// reste affichee en texte dans le panneau patient. Idem pour le "temps
/// estime" du mockup original : aucune API de routage n'est branchee, retire
/// plutot que devine ; seule une distance a vol d'oiseau vers la pharmacie
/// est affichee, et seulement avant la collecte.
class NavigationMapScreen extends StatefulWidget {
  const NavigationMapScreen({super.key});

  @override
  State<NavigationMapScreen> createState() => _NavigationMapScreenState();
}

class _NavigationMapScreenState extends State<NavigationMapScreen> {
  final _api = CourierApi.fromSession();
  CourierDelivery? _delivery;
  bool _loading = true;
  String? _error;

  GoogleMapController? _mapController;
  Position? _courierPosition;
  StreamSubscription<Position>? _positionSub;
  bool _locationDenied = false;

  @override
  void initState() {
    super.initState();
    _load();
    _startPositionStream();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final active = await _api.fetchActiveDeliveries();
      if (!mounted) return;
      setState(() {
        _delivery = active.isEmpty ? null : active.first;
        _error = active.isEmpty ? 'Aucune course active pour le moment.' : null;
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

  /// Meme logique de permission que le ping de position de
  /// `ActiveDeliveryScreen` : echec silencieux (GPS coupe, permission
  /// refusee...) jamais bloquant, la carte reste utilisable sans le marker
  /// livreur ni le bouton "recentrer".
  Future<void> _startPositionStream() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationDenied = true);
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) setState(() => _locationDenied = true);
        return;
      }
      final initial = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) setState(() => _courierPosition = initial);
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((position) {
        if (!mounted) return;
        setState(() => _courierPosition = position);
      });
    } catch (_) {
      if (mounted) setState(() => _locationDenied = true);
    }
  }

  void _recenter() {
    final position = _courierPosition;
    if (position == null || _mapController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Position indisponible — vérifiez que la localisation est activée.',
          ),
        ),
      );
      return;
    }
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 16),
    );
  }

  void _callPatient() {
    final delivery = _delivery!;
    final name = delivery.recipientName ?? 'le patient';
    final phone = delivery.patientPhone;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appeler le patient'),
        content: Text(
          phone != null
              ? 'Appelez $name au $phone depuis votre téléphone.'
              : 'Aucun numéro de téléphone renseigné pour $name.',
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

  void _showDeliveryInfo() {
    final note = _delivery?.deliveryNote;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Note de livraison'),
        content: Text(
          note?.isNotEmpty == true
              ? note!
              : 'Aucune note de livraison renseignée pour cette course.',
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
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final delivery = _delivery;
    if (_error != null || delivery == null) {
      return Scaffold(
        backgroundColor: GabColors.background,
        appBar: AppBar(
          backgroundColor: GabColors.background,
          elevation: 0,
          title: const Text(
            'Navigation',
            style: TextStyle(color: GabColors.primary, fontWeight: FontWeight.w800),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 40, color: GabColors.muted),
                const SizedBox(height: 12),
                Text(
                  _error ?? 'Course introuvable.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: GabColors.muted),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final pharmacy = delivery.pharmacy;
    final hasPharmacyCoords = pharmacy.latitude != null && pharmacy.longitude != null;
    final courierPosition = _courierPosition;

    final markers = <Marker>{
      if (hasPharmacyCoords)
        Marker(
          markerId: const MarkerId('pharmacy'),
          position: LatLng(pharmacy.latitude!, pharmacy.longitude!),
          infoWindow: InfoWindow(title: pharmacy.name, snippet: pharmacy.address),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      if (courierPosition != null)
        Marker(
          markerId: const MarkerId('courier'),
          position: LatLng(courierPosition.latitude, courierPosition.longitude),
          infoWindow: const InfoWindow(title: 'Ma position'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
    };

    final initialTarget = courierPosition != null
        ? LatLng(courierPosition.latitude, courierPosition.longitude)
        : hasPharmacyCoords
        ? LatLng(pharmacy.latitude!, pharmacy.longitude!)
        : const LatLng(0.3901, 9.4544); // Libreville, dernier recours

    String? distanceLabel;
    if (delivery.status == 'assigned' && hasPharmacyCoords && courierPosition != null) {
      final meters = Geolocator.distanceBetween(
        courierPosition.latitude,
        courierPosition.longitude,
        pharmacy.latitude!,
        pharmacy.longitude!,
      );
      distanceLabel = meters >= 1000
          ? '${(meters / 1000).toStringAsFixed(1)} km'
          : '${meters.round()} m';
    }

    return Scaffold(
      backgroundColor: GabColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: initialTarget, zoom: 14),
              markers: markers,
              myLocationEnabled: !_locationDenied,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (controller) => _mapController = controller,
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
                      constraints: const BoxConstraints(maxWidth: 200),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: GabColors.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ZONE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: GabColors.muted,
                            ),
                          ),
                          Text(
                            delivery.zoneLabel,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis,
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
                              const Icon(Icons.straighten, color: GabColors.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Distance pharmacie',
                                      style: TextStyle(fontSize: 11, color: GabColors.muted),
                                    ),
                                    Text(
                                      distanceLabel ?? '—',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: GabColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 36, color: GabColors.outlineVariant),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.local_shipping_outlined, color: GabColors.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Statut',
                                      style: TextStyle(fontSize: 11, color: GabColors.muted),
                                    ),
                                    Text(
                                      delivery.statusLabel,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: GabColors.primary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
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
                                  Text(
                                    delivery.recipientName ?? 'Patient',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    delivery.deliveryAddress?.isNotEmpty == true
                                        ? '${delivery.deliveryAddress}, ${delivery.zoneLabel}'
                                        : delivery.zoneLabel,
                                    style: const TextStyle(color: GabColors.muted),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _showDeliveryInfo,
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
                                onPressed: _callPatient,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(56),
                                  shape: const StadiumBorder(),
                                  side: const BorderSide(color: GabColors.primary, width: 2),
                                ),
                                icon: const Icon(Icons.call_outlined),
                                label: const Text('Appeler'),
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
              onPressed: _recenter,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}

typedef _Zone = ({String code, String label});

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});
  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  // Les 4 zones réelles du backend (`ZONE_CHOICES`, `apps/accounts/forms.py`)
  // — aucune autre zone n'existe côté API, et aucune n'a de métadonnée
  // "demande"/nombre de pharmacies à afficher honnêtement.
  static const _zones = <_Zone>[
    (code: 'libreville', label: 'Libreville'),
    (code: 'owendo', label: 'Owendo'),
    (code: 'akanda', label: 'Akanda'),
    (code: 'bikele', label: 'Bikélé'),
  ];

  final _api = CourierApi.fromSession();
  bool _loading = true;
  String? _error;
  bool _online = false;
  bool _togglingOnline = false;
  // Zones réellement affectées côté backend (`coverage_zones`) — c'est ce
  // qui détermine le badge "vérifié" et le pill "Zone(s) active(s)".
  Set<String> _realZones = {};
  // Intention du livreur, éditable localement : ne modifie jamais
  // `_realZones` tant qu'aucun endpoint ne permet de sauvegarder un
  // changement de zone (`PATCH /mobile/courier/availability/` ne touche
  // que `is_available_for_delivery`, jamais `coverage_zones` — voir
  // `api_contrat_besoins.md` §13).
  final Set<String> _selectedZones = {};
  bool _updating = false;

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
      final availability = await _api.fetchAvailability();
      if (!mounted) return;
      setState(() {
        _online = availability.isAvailableForDelivery;
        _realZones = availability.coverageZoneCodes.toSet();
        _selectedZones
          ..clear()
          ..addAll(_realZones);
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

  Future<void> _setOnline(bool value) async {
    if (_togglingOnline) return;
    final previous = _online;
    setState(() {
      _online = value;
      _togglingOnline = true;
    });
    try {
      final availability = await _api.setAvailable(value);
      if (!mounted) return;
      setState(() {
        _online = availability.isAvailableForDelivery;
        _togglingOnline = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _online = previous;
        _togglingOnline = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  void _toggleZone(String code, bool checked) {
    setState(() {
      if (checked) {
        _selectedZones.add(code);
      } else if (_selectedZones.length > 1) {
        _selectedZones.remove(code);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous devez couvrir au moins une zone.')),
        );
      }
    });
  }

  Future<void> _updateZone() async {
    if (_updating) return;
    final unchanged =
        _selectedZones.length == _realZones.length && _selectedZones.containsAll(_realZones);
    if (unchanged) {
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

  String get _activeZonesLabel {
    final labels = _zones
        .where((zone) => _realZones.contains(zone.code))
        .map((zone) => zone.label)
        .toList();
    if (labels.isEmpty) return 'Aucune zone assignée';
    return labels.join(', ');
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
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline, size: 40, color: GabColors.muted),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: GabColors.muted),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
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
                      onChanged: _togglingOnline ? null : _setOnline,
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
                checked: _selectedZones.contains(zone.code),
                active: _realZones.contains(zone.code),
                onChanged: (value) => _toggleZone(zone.code, value),
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
                          Flexible(
                            child: Text(
                              'Zone(s) active(s) : $_activeZonesLabel',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
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
                  Text(zone.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  if (active)
                    const Text(
                      'Zone assignée',
                      style: TextStyle(color: GabColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
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

    marker(Offset(size.width * 0.42, size.height * 0.3), 'Libreville');
    marker(Offset(size.width * 0.78, size.height * 0.22), 'Akanda');
    marker(Offset(size.width * 0.7, size.height * 0.75), 'Owendo');
    marker(Offset(size.width * 0.9, size.height * 0.6), 'Bikélé');
  }

  @override
  bool shouldRepaint(covariant _ZoneMapPainter oldDelegate) => false;
}

/// Dossier de vérification (écran 14), branché sur `GET/POST
/// /mobile/courier/verification/...`. Aucun document « Assurance » —
/// décision actée le 28 août 2026 (`api_contrat_besoins.md` §3.1/§6.3),
/// `CourierDocument.Category` ne connaît que identité/permis. Les
/// emplacements requis (`required_slots`) dépendent à la fois du type de
/// pièce d'identité choisi et du véhicule déclaré côté Django — recto/verso
/// pour CNI/carte de séjour, une seule page pour un passeport, permis
/// seulement pour moto/voiture (rien pour vélo/à pied).
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});
  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _api = CourierApi.fromSession();
  final _picker = ImagePicker();
  CourierVerification? _verification;
  bool _loading = true;
  String? _error;
  String? _busyKey;

  static const _identityTypes = [
    ('cni', "Carte nationale d'identité"),
    ('residence_card', 'Carte de séjour'),
    ('passport', 'Passeport'),
  ];

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
      final verification = await _api.fetchVerification();
      if (!mounted) return;
      setState(() {
        _verification = verification;
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

  Future<void> _chooseIdentityType(String type) async {
    setState(() => _busyKey = 'identity-type');
    try {
      final verification = await _api.setIdentityDocumentType(type);
      if (!mounted) return;
      setState(() {
        _verification = verification;
        _busyKey = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _busyKey = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<ImageSource?> _askImageSource() => showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Prendre une photo'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choisir dans la galerie'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );

  Future<void> _pickAndUpload(String category, String side) async {
    final source = await _askImageSource();
    if (source == null || !mounted) return;
    XFile? picked;
    try {
      picked = await _picker.pickImage(source: source, imageQuality: 85);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'accéder à l'appareil photo ou à la galerie.")),
      );
      return;
    }
    if (picked == null || !mounted) return;
    final slotKey = '$category|$side';
    setState(() => _busyKey = slotKey);
    try {
      final bytes = await picked.readAsBytes();
      final extension = picked.name.split('.').last.toLowerCase();
      final contentType = switch (extension) {
        'png' => 'image/png',
        'jpg' || 'jpeg' => 'image/jpeg',
        _ => 'application/octet-stream',
      };
      final verification = await _api.uploadVerificationDocument(
        category: category,
        side: side,
        fileBytes: bytes,
        fileName: picked.name,
        contentType: contentType,
      );
      if (!mounted) return;
      setState(() {
        _verification = verification;
        _busyKey = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document envoyé. Il sera vérifié par le Staff Gab’Pharma.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _busyKey = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _submitDossier() async {
    setState(() => _busyKey = 'submit');
    try {
      final verification = await _api.submitVerificationDossier();
      if (!mounted) return;
      setState(() {
        _verification = verification;
        _busyKey = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dossier soumis. Le Staff Gab’Pharma va l’examiner.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _busyKey = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final verification = _verification;
    if (_error != null || verification == null) {
      return Scaffold(
        backgroundColor: GabColors.background,
        appBar: AppBar(
          backgroundColor: GabColors.background,
          elevation: 0,
          title: const Text(
            'Mes Documents',
            style: TextStyle(color: GabColors.primary, fontWeight: FontWeight.w800),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 40, color: GabColors.muted),
                const SizedBox(height: 12),
                Text(
                  _error ?? 'Dossier introuvable.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: GabColors.muted),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final locked = verification.status == 'pending_review' || verification.status == 'approved';
    final canSubmit = verification.isComplete && !locked && _busyKey == null;
    final (progressColor, progressIcon) = switch (verification.status) {
      'approved' => (GabColors.primary, Icons.verified_user),
      'pending_review' => (GabColors.routeBlue, Icons.schedule),
      'changes_requested' || 'rejected' => (GabColors.danger, Icons.error_outline),
      _ => (GabColors.muted, Icons.badge_outlined),
    };

    return Scaffold(
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
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
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
                                'Dossier livreur',
                                style: TextStyle(color: GabColors.muted, fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: 2),
                            ],
                          ),
                        ),
                        Icon(progressIcon, color: progressColor),
                      ],
                    ),
                    Text(
                      '${verification.statusLabel} · ${verification.progressPercent}%',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: verification.progressPercent / 100,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFD7E6DE),
                        valueColor: AlwaysStoppedAnimation(progressColor),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      switch (verification.status) {
                        'approved' => 'Votre dossier est validé.',
                        'pending_review' => "Votre dossier est en cours d'examen par le Staff Gab’Pharma.",
                        'changes_requested' =>
                          'Des modifications sont demandées — remplacez les documents refusés ci-dessous.',
                        _ => 'Complétez et soumettez vos documents pour commencer à recevoir des courses.',
                      },
                      style: const TextStyle(color: GabColors.muted),
                    ),
                    if (verification.note.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: GabColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          verification.note,
                          style: const TextStyle(color: GabColors.danger, fontSize: 13),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: GabColors.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Type de pièce d'identité",
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Détermine les documents à fournir ci-dessous.',
                      style: TextStyle(color: GabColors.muted, fontSize: 12),
                    ),
                    if (locked)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          verification.identityDocumentTypeLabel.isNotEmpty
                              ? verification.identityDocumentTypeLabel
                              : 'Non renseigné',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      )
                    else
                      RadioGroup<String>(
                        groupValue: verification.identityDocumentType.isEmpty
                            ? null
                            : verification.identityDocumentType,
                        onChanged: (v) {
                          if (_busyKey != null || v == null) return;
                          _chooseIdentityType(v);
                        },
                        child: Column(
                          children: [
                            for (final (value, label) in _identityTypes)
                              RadioListTile<String>(
                                value: value,
                                title: Text(label),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                activeColor: GabColors.primary,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (verification.requiredSlots.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "Choisissez votre type de pièce d'identité pour voir les documents à fournir.",
                    style: TextStyle(color: GabColors.muted),
                  ),
                )
              else
                for (final slot in verification.requiredSlots) ...[
                  _VerificationSlotCard(
                    slot: slot,
                    document: verification.documentFor(slot.category, slot.side),
                    busy: _busyKey == '${slot.category}|${slot.side}',
                    locked: locked,
                    onPreview: () => _previewDocument('${slot.categoryLabel} — ${slot.sideLabel}'),
                    onUpload: () => _pickAndUpload(slot.category, slot.side),
                  ),
                  const SizedBox(height: 14),
                ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: canSubmit ? _submitDossier : null,
                  icon: _busyKey == 'submit'
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(_busyKey == 'submit' ? 'Envoi...' : 'Soumettre mon dossier'),
                  style: FilledButton.styleFrom(shape: const StadiumBorder(), minimumSize: const Size.fromHeight(56)),
                ),
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
      ),
    );
  }
}

class _VerificationSlotCard extends StatelessWidget {
  const _VerificationSlotCard({
    required this.slot,
    required this.document,
    required this.busy,
    required this.locked,
    required this.onPreview,
    required this.onUpload,
  });

  final CourierVerificationSlot slot;
  final CourierVerificationDocument? document;
  final bool busy;
  final bool locked;
  final VoidCallback onPreview;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusText, statusIcon) = switch (document?.status) {
      'approved' => (GabColors.primary, 'Validé', Icons.check_circle),
      'pending' => (GabColors.routeBlue, 'En attente de vérification', Icons.schedule),
      'rejected' => (
        GabColors.danger,
        document!.rejectionReason.isNotEmpty ? document!.rejectionReason : 'Refusé',
        Icons.error,
      ),
      _ => (GabColors.muted, 'Aucun document envoyé', Icons.upload_file_outlined),
    };
    final rejected = document?.status == 'rejected';
    final hasFile = document?.hasFile ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: rejected ? GabColors.danger.withValues(alpha: 0.4) : GabColors.outlineVariant.withValues(alpha: 0.3),
          width: rejected ? 2 : 1,
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
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.badge_outlined, color: statusColor.withValues(alpha: 0.6)),
                  ),
                  Positioned(right: 2, bottom: 2, child: Icon(statusIcon, size: 16, color: statusColor)),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${slot.categoryLabel} — ${slot.sideLabel}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
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
                            statusText,
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (document?.hasPendingReplacement ?? false)
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          'Nouvelle version en attente de vérification',
                          style: TextStyle(color: GabColors.routeBlue, fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ),
              if (hasFile)
                IconButton(
                  onPressed: onPreview,
                  icon: const Icon(Icons.visibility_outlined, color: GabColors.muted),
                ),
            ],
          ),
          if (!locked) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: busy ? null : onUpload,
                icon: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_a_photo_outlined),
                label: Text(busy ? 'Envoi...' : (hasFile ? 'Remplacer le document' : 'Ajouter le document')),
                style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
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

/// Icone/tone -> rendu Flutter pour un [CourierNotification]. Le backend
/// n'envoie que 10 valeurs d'icone reelles (`_DELIVERY_STATUS_STYLE` +
/// `package_2`/`verified` cote `_courier_notifications`) et 4 tons
/// (amber/green/blue/red, defaut neutre) — mappees sur les couleurs deja
/// utilisees ailleurs dans l'app (`GabColors.warning`/`primary`/`routeBlue`/
/// `danger`) plutot que de reinventer une palette de notification.
const _notificationIcons = <String, IconData>{
  'package_2': Icons.inventory_2_outlined,
  'assignment_ind': Icons.assignment_ind,
  'inventory_2': Icons.inventory_2,
  'delivery_dining': Icons.delivery_dining,
  'assignment_return': Icons.assignment_return,
  'keyboard_return': Icons.keyboard_return,
  'task_alt': Icons.task_alt,
  'block': Icons.block,
  'verified': Icons.verified,
};

Color _notificationToneColor(String tone) => switch (tone) {
  'amber' => GabColors.warning,
  'green' => GabColors.primary,
  'blue' => GabColors.routeBlue,
  'red' => GabColors.danger,
  _ => GabColors.muted,
};

/// Regroupement par jour identique à celui déjà validé pour l'Historique
/// (`_historyDateLabel`, `courier_shell.dart`) — dupliqué ici car les deux
/// fichiers sont des librairies Dart distinctes (fonctions privées non
/// partageables via import).
String _notifDayLabel(DateTime timestamp) {
  final local = timestamp.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return "Aujourd'hui";
  if (diff == 1) return 'Hier';
  const months = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

String _notifTimeLabel(DateTime timestamp) {
  final local = timestamp.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

/// Seule catégorie de notification avec un écran de détail honnête à ce jour :
/// une course `awaiting_assignment` compatible ("Course #N disponible",
/// voir `_courier_notifications` côté Django) mène à `/available-detail`,
/// déjà capable de retrouver la course dans la liste des courses disponibles.
/// Les autres notifications `delivery` (changement de statut, incident résolu)
/// n'ont aucune route de détail générique par id côté app (`/active-delivery`
/// ne représente que LA course active actuelle, pas un id arbitraire) — pas
/// de lien "Voir les détails" pour elles plutôt qu'une navigation trompeuse.
bool _isAvailableCourseNotification(CourierNotification item) =>
    item.targetType == 'delivery' &&
    item.targetId != null &&
    item.title.startsWith('Course #') &&
    item.title.endsWith('disponible');

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _api = CourierApi.fromSession();
  List<CourierNotification> _items = const [];
  bool _loading = true;
  String? _error;

  /// Etat "lu" purement local : le flux `/mobile/notifications/` est agrege
  /// a la volee cote serveur (`persistence: "aggregated"`, `unread_count`
  /// toujours `null`, aucun id stable par entree) — rien a synchroniser,
  /// reinitialise a chaque rechargement comme le reste de l'ecran.
  final Set<int> _read = {};

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
      final items = await _api.fetchNotifications();
      if (!mounted) return;
      setState(() {
        _items = items;
        _read.clear();
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

  void _markRead(int index) {
    if (_read.contains(index)) return;
    setState(() => _read.add(index));
  }

  void _markAllRead() {
    setState(() => _read.addAll(List.generate(_items.length, (i) => i)));
  }

  void _openDetail(int index, CourierNotification item) {
    _markRead(index);
    Navigator.pushNamed(context, '/available-detail', arguments: {'deliveryId': item.targetId});
  }

  @override
  Widget build(BuildContext context) {
    final groups = <String>[];
    for (final item in _items) {
      final group = _notifDayLabel(item.timestamp);
      if (!groups.contains(group)) groups.add(group);
    }
    return Scaffold(
      backgroundColor: GabColors.background,
      appBar: AppBar(
        backgroundColor: GabColors.background,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.notifications_outlined, color: GabColors.primary, size: 26),
            SizedBox(width: 10),
            Text(
              'Notifications',
              style: TextStyle(color: GabColors.primary, fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        titleSpacing: 0,
        actions: [
          if (_items.isNotEmpty)
            TextButton.icon(
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all, size: 18, color: GabColors.primary),
              label: const Text('TOUT LIRE'),
              style: TextButton.styleFrom(foregroundColor: GabColors.primary),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, size: 40, color: GabColors.muted),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: GabColors.muted)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              )
            : _items.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_off_outlined, size: 40, color: GabColors.muted),
                      const SizedBox(height: 12),
                      const Text(
                        'Aucune notification pour le moment.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: GabColors.muted),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    for (final group in groups) ...[
                      _sectionLabel(group.toUpperCase()),
                      const SizedBox(height: 12),
                      for (final entry in _items.asMap().entries)
                        if (_notifDayLabel(entry.value.timestamp) == group) ...[
                          _NotificationCard(
                            item: entry.value,
                            read: _read.contains(entry.key),
                            onTap: () => _markRead(entry.key),
                            onDetail: _isAvailableCourseNotification(entry.value)
                                ? () => _openDetail(entry.key, entry.value)
                                : null,
                          ),
                          const SizedBox(height: 12),
                        ],
                      const SizedBox(height: 4),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: GabColors.muted,
      ),
    ),
  );
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.read,
    required this.onTap,
    this.onDetail,
  });
  final CourierNotification item;
  final bool read;
  final VoidCallback onTap;
  final VoidCallback? onDetail;

  @override
  Widget build(BuildContext context) {
    final color = _notificationToneColor(item.tone);
    final icon = _notificationIcons[item.icon] ?? Icons.notifications;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: read ? const Color(0xFFE2F1E9) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: read ? null : Border(left: BorderSide(color: color, width: 4)),
            boxShadow: read
                ? null
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color),
                  ),
                  if (!read)
                    Positioned(
                      top: -1,
                      right: -1,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: GabColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _notifTimeLabel(item.timestamp),
                          style: const TextStyle(color: GabColors.muted, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: const TextStyle(color: GabColors.muted, fontSize: 13, height: 1.35),
                    ),
                    if (onDetail != null) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: onDetail,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Voir les détails',
                              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            Icon(Icons.chevron_right, size: 16, color: color),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _TicketStatus { enCours, retard, termine }

class _Ticket {
  _Ticket({
    required this.id,
    required this.title,
    required this.status,
    required this.time,
  });
  final String id;
  final String title;
  _TicketStatus status;
  String time;
}

class _SupportCategory {
  const _SupportCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  static const _categories = [
    _SupportCategory('Livraison', Icons.delivery_dining),
    _SupportCategory('Compte', Icons.account_circle_outlined),
    _SupportCategory('Paiement', Icons.payments_outlined),
  ];

  final _tickets = <_Ticket>[
    _Ticket(id: '#GP-84291', title: 'Problème de validation client', status: _TicketStatus.enCours, time: 'Il y a 15 min'),
    _Ticket(id: '#GP-84110', title: 'Retard sur la zone Akanda', status: _TicketStatus.retard, time: 'Hier, 18:30'),
    _Ticket(id: '#GP-83902', title: 'Erreur de paiement commission', status: _TicketStatus.enCours, time: '2 oct. 2023'),
    _Ticket(id: '#GP-83100', title: 'Mise à jour RIB refusée', status: _TicketStatus.termine, time: 'Résolu le 28 sept.'),
  ];

  final _searchController = TextEditingController();
  String _query = '';
  int _nextTicketNumber = 84350;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_Ticket> get _filtered {
    if (_query.trim().isEmpty) return _tickets;
    final q = _query.toLowerCase();
    return _tickets.where((t) => t.title.toLowerCase().contains(q) || t.id.toLowerCase().contains(q)).toList();
  }

  void _openTicket(_Ticket ticket) {
    Navigator.pushNamed(
      context,
      '/support-thread',
      arguments: {
        'id': ticket.id,
        'subject': ticket.title,
        'status': ticket.status == _TicketStatus.retard ? 'Retard' : 'En cours',
      },
    );
  }

  Future<void> _createTicket([String? presetCategory]) async {
    final descriptionController = TextEditingController();
    var category = presetCategory ?? _categories.first.label;
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(sheetContext).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nouveau ticket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                children: [
                  for (final c in _categories)
                    ChoiceChip(
                      label: Text(c.label),
                      selected: category == c.label,
                      onSelected: (_) => setSheetState(() => category = c.label),
                      selectedColor: GabColors.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: category == c.label ? GabColors.primary : GabColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Décrivez votre problème...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext, true),
                  child: const Text('Envoyer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (submitted != true || !mounted) return;
    setState(() {
      _tickets.insert(
        0,
        _Ticket(
          id: '#GP-$_nextTicketNumber',
          title: 'Ticket $category — nouvelle demande',
          status: _TicketStatus.enCours,
          time: 'À l’instant',
        ),
      );
      _nextTicketNumber++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ticket envoyé. Un agent du support va vous répondre.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _tickets.where((t) => t.status != _TicketStatus.termine).length;
    return Scaffold(
      backgroundColor: GabColors.background,
      appBar: AppBar(
        backgroundColor: GabColors.background,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.support_agent, color: GabColors.primary, size: 26),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                "Support Gab'Pharma",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: GabColors.primary, fontWeight: FontWeight.w800, fontSize: 17),
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
                color: const Color(0xFFA8F4B9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: GabColors.primary),
                  SizedBox(width: 6),
                  Text('EN LIGNE', style: TextStyle(color: Color(0xFF287243), fontWeight: FontWeight.w800, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createTicket(),
        backgroundColor: GabColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Créer un ticket'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const Text('Nouvelle demande', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final c in _categories) ...[
                  Expanded(
                    child: _CategoryButton(category: c, onTap: () => _createTicket(c.label)),
                  ),
                  if (c != _categories.last) const SizedBox(width: 12),
                ],
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFDCECE3),
                borderRadius: BorderRadius.circular(999),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  hintText: 'Rechercher un ticket...',
                  prefixIcon: Icon(Icons.search, color: GabColors.muted),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mes tickets ouverts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: GabColors.primary, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    '$activeCount Actifs',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Aucun ticket ne correspond à « $_query ».',
                    style: const TextStyle(color: GabColors.muted),
                  ),
                ),
              )
            else
              for (final ticket in _filtered) ...[
                _TicketCard(ticket: ticket, onTap: ticket.status == _TicketStatus.termine ? null : () => _openTicket(ticket)),
                const SizedBox(height: 14),
              ],
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({required this.category, required this.onTap});
  final _SupportCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFE2F1E9),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: Color(0xFFA8F4B9), shape: BoxShape.circle),
              child: Icon(category.icon, color: const Color(0xFF287243)),
            ),
            const SizedBox(height: 8),
            Text(category.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    ),
  );
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, required this.onTap});
  final _Ticket ticket;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final resolved = ticket.status == _TicketStatus.termine;
    final (borderColor, badgeBg, badgeFg, label) = switch (ticket.status) {
      _TicketStatus.enCours => (GabColors.primary, GabColors.routeBlue.withValues(alpha: 0.12), GabColors.routeBlue, 'En cours'),
      _TicketStatus.retard => (GabColors.warning, GabColors.warning.withValues(alpha: 0.15), GabColors.warning, 'Retard'),
      _TicketStatus.termine => (GabColors.outlineVariant, GabColors.primary.withValues(alpha: 0.12), GabColors.primary, 'Terminé'),
    };

    return Material(
      color: resolved ? const Color(0xFFCEDED5).withValues(alpha: 0.4) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: resolved
                ? Border.all(color: GabColors.outlineVariant)
                : Border(left: BorderSide(color: borderColor, width: 4)),
          ),
          child: Opacity(
            opacity: resolved ? 0.7 : 1,
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
                          Text(ticket.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text('ID: ${ticket.id}', style: const TextStyle(color: GabColors.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(10)),
                      child: Text(label, style: TextStyle(color: badgeFg, fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(resolved ? Icons.check_circle_outline : Icons.schedule, size: 16, color: GabColors.muted),
                        const SizedBox(width: 6),
                        Text(ticket.time, style: const TextStyle(color: GabColors.muted, fontSize: 12)),
                      ],
                    ),
                    if (!resolved) const Icon(Icons.chevron_right, color: GabColors.primary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  _ChatMessage({
    required this.fromStaff,
    required this.time,
    this.text,
    this.attachmentLabel,
    this.read = true,
  });
  final bool fromStaff;
  final String time;
  final String? text;
  final String? attachmentLabel;
  final bool read;
}

class SupportThreadScreen extends StatefulWidget {
  const SupportThreadScreen({
    this.ticketId = '#GP-1024',
    this.ticketSubject = 'Problème paiement',
    this.statusLabel = 'En cours',
    super.key,
  });
  final String ticketId;
  final String ticketSubject;
  final String statusLabel;

  @override
  State<SupportThreadScreen> createState() => _SupportThreadScreenState();
}

class _SupportThreadScreenState extends State<SupportThreadScreen> {
  late final _messages = <_ChatMessage>[
    _ChatMessage(
      fromStaff: true,
      time: '09:42',
      text:
          "Bonjour, je suis Sarah du support technique. J'ai bien reçu votre "
          'signalement « ${widget.ticketSubject} » (Ticket ${widget.ticketId}). '
          'Pouvez-vous me donner un peu plus de détails ?',
    ),
    _ChatMessage(
      fromStaff: false,
      time: '09:45',
      text:
          'Bonjour Sarah. Le problème est survenu ce matin pendant ma tournée '
          "à Libreville. Je vous envoie une capture d'écran pour référence.",
    ),
    _ChatMessage(
      fromStaff: true,
      time: '09:48',
      text:
          'Merci, je vérifie cela dans notre système. Une capture au moment du '
          'problème nous aiderait à accélérer la résolution.',
    ),
    _ChatMessage(
      fromStaff: false,
      time: '09:50',
      attachmentLabel: 'Capture_${widget.ticketId.replaceAll('#', '')}.jpg',
    ),
  ];

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  bool _composing = false;
  bool _sentNotice = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _jumpToEnd() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToEnd());
    // Keyboard show/hide animations resize the viewport after this frame,
    // so correct the offset again once those settle.
    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) _jumpToEnd();
    });
  }

  void _send([String? preset]) {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty) return;
    final now = TimeOfDay.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    setState(() {
      _messages.add(_ChatMessage(fromStaff: false, time: time, text: text, read: false));
      _controller.clear();
      _composing = false;
    });
    _scrollToEnd();
    if (!_sentNotice) {
      _sentNotice = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message envoyé. Un agent vous répondra dès que possible.')),
      );
    }
  }

  void _attach() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pièce jointe'),
        content: const Text(
          'Envoi de fichiers indisponible en démonstration — sera activé une '
          "fois l'application connectée au stockage sécurisé de l'API.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.statusLabel == 'Retard' ? GabColors.warning : GabColors.routeBlue;
    return Scaffold(
      backgroundColor: GabColors.background,
      appBar: AppBar(
        backgroundColor: GabColors.background,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ticket ${widget.ticketId}',
              style: const TextStyle(color: GabColors.primary, fontWeight: FontWeight.w800, fontSize: 17),
            ),
            Text(widget.ticketSubject, style: const TextStyle(color: GabColors.muted, fontSize: 12)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFA8F4B9), borderRadius: BorderRadius.circular(999)),
              child: const Text('EN LIGNE', style: TextStyle(color: Color(0xFF287243), fontWeight: FontWeight.w800, fontSize: 11)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: statusColor.withValues(alpha: 0.08),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text('Statut : ${widget.statusLabel}', style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 13)),
                    ],
                  ),
                  const Text('Dernière activité : Il y a 2 min', style: TextStyle(color: GabColors.muted, fontSize: 11)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFDCECE3), borderRadius: BorderRadius.circular(999)),
                      child: const Text("Aujourd'hui", style: TextStyle(color: GabColors.muted, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (final m in _messages) ...[
                    _ChatBubble(message: m),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            if (_composing)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    _QuickReplyChip(label: "Merci pour l'aide", onTap: () => _controller.text = "Merci pour l'aide"),
                    const SizedBox(width: 8),
                    _QuickReplyChip(label: "C'est envoyé", onTap: () => _controller.text = "C'est envoyé"),
                  ],
                ),
              ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: _attach,
                      icon: const Icon(Icons.attach_file, color: GabColors.primary),
                    ),
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: const Color(0xFFE2F1E9), borderRadius: BorderRadius.circular(24)),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          minLines: 1,
                          maxLines: 4,
                          onChanged: (v) => setState(() => _composing = _focusNode.hasFocus),
                          onTap: () => setState(() => _composing = true),
                          decoration: const InputDecoration(
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                            hintText: 'Écrivez votre message...',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: GabColors.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _send(),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.send, color: Colors.white, size: 20),
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
    );
  }
}

class _QuickReplyChip extends StatelessWidget {
  const _QuickReplyChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(999),
    child: InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: GabColors.outlineVariant),
        ),
        child: Text(label, style: const TextStyle(color: GabColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    ),
  );
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final staff = message.fromStaff;
    return Align(
      alignment: staff ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Column(
          crossAxisAlignment: staff ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            if (staff) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFFA8F4B9),
                    child: Icon(Icons.support_agent, size: 16, color: Color(0xFF287243)),
                  ),
                  const SizedBox(width: 8),
                  const Text('Support Gab’Pharma', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 6),
            ],
            if (message.attachmentLabel != null)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: staff ? Colors.white : GabColors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(staff ? 4 : 18),
                    bottomRight: Radius.circular(staff ? 18 : 4),
                  ),
                  border: staff ? Border.all(color: GabColors.outlineVariant) : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 180,
                      height: 130,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCECE3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.image_outlined, color: GabColors.muted, size: 32),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 8, 6, 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message.attachmentLabel!,
                            style: TextStyle(
                              color: staff ? GabColors.ink : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            message.read ? Icons.done_all : Icons.check,
                            size: 14,
                            color: staff ? GabColors.muted : Colors.white70,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: staff ? Colors.white : GabColors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(staff ? 4 : 18),
                    bottomRight: Radius.circular(staff ? 18 : 4),
                  ),
                  border: staff ? Border.all(color: GabColors.outlineVariant) : null,
                  boxShadow: staff
                      ? null
                      : [BoxShadow(color: GabColors.primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      message.text ?? '',
                      style: TextStyle(color: staff ? GabColors.ink : Colors.white, height: 1.4, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.time,
                          style: TextStyle(
                            color: staff ? GabColors.muted : Colors.white.withValues(alpha: 0.8),
                            fontSize: 10,
                          ),
                        ),
                        if (!staff) ...[
                          const SizedBox(width: 4),
                          Icon(message.read ? Icons.done_all : Icons.check, size: 13, color: Colors.white.withValues(alpha: 0.9)),
                        ],
                      ],
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

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mot de passe mis à jour pour cette session de démonstration.')),
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
        'Changer mot de passe',
        style: TextStyle(color: GabColors.primary, fontWeight: FontWeight.w800, fontSize: 17),
      ),
    ),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _currentController,
              obscureText: _obscureCurrent,
              decoration: InputDecoration(
                labelText: 'Mot de passe actuel',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Mot de passe actuel requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newController,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: 'Nouveau mot de passe',
                prefixIcon: const Icon(Icons.lock_reset_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              validator: (v) {
                if (v == null || v.length < 8 || !RegExp(r'\d').hasMatch(v)) {
                  return 'Au moins 8 caractères et 1 chiffre.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirmer le nouveau mot de passe',
                prefixIcon: const Icon(Icons.lock_reset_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) => v != _newController.text ? 'Les mots de passe ne correspondent pas.' : null,
            ),
            const SizedBox(height: 8),
            const Text(
              'Astuce : au moins 8 caractères et 1 chiffre, comme à la connexion.',
              style: TextStyle(color: GabColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Mettre à jour'),
            ),
          ],
        ),
      ),
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

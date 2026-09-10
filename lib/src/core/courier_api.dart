import 'api_client.dart';
import 'auth_session.dart';

class Pharmacy {
  const Pharmacy({
    required this.id,
    required this.name,
    required this.zoneLabel,
    required this.address,
    required this.phone,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String name;
  final String zoneLabel;
  final String address;
  final String phone;
  final double? latitude;
  final double? longitude;

  factory Pharmacy.fromJson(Map<String, dynamic> json) => Pharmacy(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    zoneLabel: json['zone_label'] as String? ?? '',
    address: json['address'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );
}

class DeliveryActions {
  const DeliveryActions({
    required this.canPickup,
    required this.canStart,
    required this.canResendProofCode,
    required this.canComplete,
    required this.canReportAbsence,
    required this.canReportIncident,
  });

  final bool canPickup;
  final bool canStart;
  final bool canResendProofCode;
  final bool canComplete;
  final bool canReportAbsence;
  final bool canReportIncident;

  static const _none = DeliveryActions(
    canPickup: false,
    canStart: false,
    canResendProofCode: false,
    canComplete: false,
    canReportAbsence: false,
    canReportIncident: false,
  );

  factory DeliveryActions.fromJson(Map<String, dynamic>? json) {
    if (json == null) return _none;
    return DeliveryActions(
      canPickup: json['can_pickup'] as bool? ?? false,
      canStart: json['can_start'] as bool? ?? false,
      canResendProofCode: json['can_resend_proof_code'] as bool? ?? false,
      canComplete: json['can_complete'] as bool? ?? false,
      canReportAbsence: json['can_report_absence'] as bool? ?? false,
      canReportIncident: json['can_report_incident'] as bool? ?? false,
    );
  }
}

/// Incident lie a une course (`DeliveryIncident` cote Django) : statut binaire
/// ouvert/resolu, taxonomie de 7 types dont `patient_absent` qui n'est plus
/// soumis depuis cet ecran (parcours dedie, voir [CourierApi.reportPatientAbsence]).
class DeliveryIncident {
  const DeliveryIncident({
    required this.id,
    required this.incidentType,
    required this.incidentTypeLabel,
    required this.severityLabel,
    required this.status,
    required this.statusLabel,
    required this.description,
    this.createdAt,
  });

  final int id;
  final String incidentType;
  final String incidentTypeLabel;
  final String severityLabel;
  final String status;
  final String statusLabel;
  final String description;
  final DateTime? createdAt;

  factory DeliveryIncident.fromJson(Map<String, dynamic> json) => DeliveryIncident(
    id: json['id'] as int,
    incidentType: json['incident_type'] as String? ?? '',
    incidentTypeLabel: json['incident_type_label'] as String? ?? '',
    severityLabel: json['severity_label'] as String? ?? '',
    status: json['status'] as String? ?? '',
    statusLabel: json['status_label'] as String? ?? '',
    description: json['description'] as String? ?? '',
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
  );
}

class CourierDelivery {
  const CourierDelivery({
    required this.id,
    required this.status,
    required this.statusLabel,
    required this.zoneLabel,
    required this.deliveryFeeFcfa,
    required this.courierShareFcfa,
    required this.platformShareFcfa,
    required this.pharmacy,
    required this.actions,
    required this.incidents,
    this.recipientName,
    this.patientPhone,
    this.deliveryAddress,
    this.deliveryDeadline,
    this.isLate = false,
    this.orderReference,
    this.orderCreatedAt,
    this.deliveredAt,
    this.returnedAt,
    this.deliveryNote,
  });

  final int id;
  final String status;
  final String statusLabel;
  final String zoneLabel;
  final int deliveryFeeFcfa;
  final int courierShareFcfa;
  final int platformShareFcfa;
  final Pharmacy pharmacy;
  final DeliveryActions actions;
  final List<DeliveryIncident> incidents;
  final String? recipientName;
  final String? patientPhone;
  final String? deliveryAddress;
  final DateTime? deliveryDeadline;
  final bool isLate;
  final String? orderReference;
  final DateTime? orderCreatedAt;
  final DateTime? deliveredAt;
  final DateTime? returnedAt;
  final String? deliveryNote;

  /// Meilleure date disponible pour une course clôturée : la remise, sinon
  /// le retour à la pharmacie, sinon la création de la commande (le backend
  /// n'expose pas de date de clôture pour `cancelled`, aucune donnée mieux
  /// datée n'existe pour ce cas).
  DateTime? get historyDate => deliveredAt ?? returnedAt ?? orderCreatedAt;

  factory CourierDelivery.fromJson(Map<String, dynamic> json) {
    final order = json['order'] as Map<String, dynamic>?;
    final patient = order?['patient'] as Map<String, dynamic>?;
    final deadline = json['delivery_deadline'] as String?;
    final orderCreatedAt = order?['created_at'] as String?;
    final deliveredAt = json['delivered_at'] as String?;
    final returnedAt = json['returned_at'] as String?;
    return CourierDelivery(
      id: json['id'] as int,
      status: json['status'] as String? ?? '',
      statusLabel: json['status_label'] as String? ?? '',
      zoneLabel: json['zone_label'] as String? ?? '',
      deliveryFeeFcfa: json['delivery_fee_fcfa'] as int? ?? 0,
      courierShareFcfa: json['courier_share_fcfa'] as int? ?? 0,
      platformShareFcfa: json['platform_share_fcfa'] as int? ?? 0,
      pharmacy: Pharmacy.fromJson(json['pharmacy'] as Map<String, dynamic>),
      actions: DeliveryActions.fromJson(json['actions'] as Map<String, dynamic>?),
      incidents: ((json['incidents'] as List?) ?? [])
          .map((e) => DeliveryIncident.fromJson(e as Map<String, dynamic>))
          .toList(),
      recipientName: patient?['name'] as String?,
      patientPhone: patient?['phone'] as String?,
      deliveryAddress: order?['delivery_address'] as String?,
      deliveryDeadline: deadline != null ? DateTime.tryParse(deadline) : null,
      isLate: json['is_late'] as bool? ?? false,
      orderReference: order?['reference'] as String?,
      orderCreatedAt: orderCreatedAt != null ? DateTime.tryParse(orderCreatedAt) : null,
      deliveredAt: deliveredAt != null ? DateTime.tryParse(deliveredAt) : null,
      returnedAt: returnedAt != null ? DateTime.tryParse(returnedAt) : null,
      deliveryNote: json['delivery_note'] as String?,
    );
  }
}

/// Ecriture du ledger livreur (`CourierLedgerEntry` cote Django) : le signe
/// de `amountFcfa` suit la convention backend — positif = du a Gab'Pharma
/// (le livreur a deja encaisse en especes et doit reverser la commission),
/// negatif = du par Gab'Pharma (paiement electronique ou indemnite de
/// retour, a verser au livreur). Aucune donnee pharmacie/code de course
/// n'est exposee par cet endpoint (contrairement a `CourierDelivery`) : seul
/// `reason` (texte libre cote backend) mentionne la livraison concernee.
class CourierLedgerEntry {
  const CourierLedgerEntry({
    required this.id,
    required this.entryType,
    required this.entryTypeLabel,
    required this.amountFcfa,
    required this.reference,
    required this.reason,
    this.deliveryId,
    this.createdAt,
  });

  final int id;
  final String entryType;
  final String entryTypeLabel;
  final int amountFcfa;
  final String reference;
  final String reason;
  final int? deliveryId;
  final DateTime? createdAt;

  factory CourierLedgerEntry.fromJson(Map<String, dynamic> json) => CourierLedgerEntry(
    id: json['id'] as int,
    entryType: json['entry_type'] as String? ?? '',
    entryTypeLabel: json['entry_type_label'] as String? ?? '',
    amountFcfa: json['amount_fcfa'] as int? ?? 0,
    reference: json['reference'] as String? ?? '',
    reason: json['reason'] as String? ?? '',
    deliveryId: json['delivery_id'] as int?,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
  );
}

/// Solde courant + jusqu'a 50 dernieres ecritures (`GET
/// /mobile/courier/ledger/`, non pagine cote backend). Aucun agregat par
/// periode ni repartition especes/electronique n'existe cote API — recalcul
/// entierement cote Flutter (decision produit "Option A", voir
/// `api_contrat_besoins.md` §3.3).
class CourierLedger {
  const CourierLedger({required this.balanceFcfa, required this.entries});
  final int balanceFcfa;
  final List<CourierLedgerEntry> entries;

  factory CourierLedger.fromJson(Map<String, dynamic> json) => CourierLedger(
    balanceFcfa: json['balance_fcfa'] as int? ?? 0,
    entries: ((json['entries'] as List?) ?? [])
        .map((e) => CourierLedgerEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// Emplacement requis du dossier de vérification (écran 14) — dépend à la
/// fois du type de pièce d'identité choisi et du véhicule déclaré
/// (`required_document_slots()` côté Django) : un passeport ne demande
/// qu'une seule page, une CNI/carte de séjour recto+verso ; un permis n'est
/// requis que pour moto/voiture (rien pour vélo/à pied).
class CourierVerificationSlot {
  const CourierVerificationSlot({
    required this.category,
    required this.categoryLabel,
    required this.side,
    required this.sideLabel,
    required this.isComplete,
  });

  final String category;
  final String categoryLabel;
  final String side;
  final String sideLabel;
  final bool isComplete;

  factory CourierVerificationSlot.fromJson(Map<String, dynamic> json) => CourierVerificationSlot(
    category: json['category'] as String? ?? '',
    categoryLabel: json['category_label'] as String? ?? '',
    side: json['side'] as String? ?? '',
    sideLabel: json['side_label'] as String? ?? '',
    isComplete: json['is_complete'] as bool? ?? false,
  );
}

/// Document réellement déposé pour un emplacement. `hasFile`/
/// `hasPendingReplacement` distincts : un document déjà approuvé peut avoir
/// une nouvelle version en attente de revue sans que l'ancienne (valide)
/// soit écrasée avant décision du Staff.
class CourierVerificationDocument {
  const CourierVerificationDocument({
    required this.id,
    required this.category,
    required this.side,
    required this.status,
    required this.statusLabel,
    required this.rejectionReason,
    required this.hasFile,
    required this.hasPendingReplacement,
    this.expiresAt,
    this.submittedAt,
    this.reviewedAt,
  });

  final int id;
  final String category;
  final String side;
  final String status;
  final String statusLabel;
  final String rejectionReason;
  final bool hasFile;
  final bool hasPendingReplacement;
  final DateTime? expiresAt;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  factory CourierVerificationDocument.fromJson(Map<String, dynamic> json) => CourierVerificationDocument(
    id: json['id'] as int,
    category: json['category'] as String? ?? '',
    side: json['side'] as String? ?? '',
    status: json['status'] as String? ?? '',
    statusLabel: json['status_label'] as String? ?? '',
    rejectionReason: json['rejection_reason'] as String? ?? '',
    hasFile: json['has_file'] as bool? ?? false,
    hasPendingReplacement: json['has_pending_replacement'] as bool? ?? false,
    expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'] as String) : null,
    submittedAt: json['submitted_at'] != null ? DateTime.tryParse(json['submitted_at'] as String) : null,
    reviewedAt: json['reviewed_at'] != null ? DateTime.tryParse(json['reviewed_at'] as String) : null,
  );
}

/// Dossier de vérification livreur (écran 14). Pas de document « Assurance »
/// (décision actée, aucune catégorie backend pour lui — voir
/// `api_contrat_besoins.md` §3.1/§6.3).
class CourierVerification {
  const CourierVerification({
    required this.identityDocumentType,
    required this.identityDocumentTypeLabel,
    required this.status,
    required this.statusLabel,
    required this.note,
    required this.isComplete,
    required this.progressPercent,
    required this.requiredSlots,
    required this.documents,
    this.submittedAt,
    this.reviewedAt,
  });

  final String identityDocumentType;
  final String identityDocumentTypeLabel;
  final String status;
  final String statusLabel;
  final String note;
  final bool isComplete;
  final int progressPercent;
  final List<CourierVerificationSlot> requiredSlots;
  final List<CourierVerificationDocument> documents;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  CourierVerificationDocument? documentFor(String category, String side) {
    for (final doc in documents) {
      if (doc.category == category && doc.side == side) return doc;
    }
    return null;
  }

  factory CourierVerification.fromJson(Map<String, dynamic> json) => CourierVerification(
    identityDocumentType: json['identity_document_type'] as String? ?? '',
    identityDocumentTypeLabel: json['identity_document_type_label'] as String? ?? '',
    status: json['status'] as String? ?? '',
    statusLabel: json['status_label'] as String? ?? '',
    note: json['note'] as String? ?? '',
    isComplete: json['is_complete'] as bool? ?? false,
    progressPercent: json['progress_percent'] as int? ?? 0,
    requiredSlots: ((json['required_slots'] as List?) ?? [])
        .map((e) => CourierVerificationSlot.fromJson(e as Map<String, dynamic>))
        .toList(),
    documents: ((json['documents'] as List?) ?? [])
        .map((e) => CourierVerificationDocument.fromJson(e as Map<String, dynamic>))
        .toList(),
    submittedAt: json['submitted_at'] != null ? DateTime.tryParse(json['submitted_at'] as String) : null,
    reviewedAt: json['reviewed_at'] != null ? DateTime.tryParse(json['reviewed_at'] as String) : null,
  );
}

/// Evenement du flux `GET /mobile/notifications/` (`_courier_notifications`
/// cote Django) : agrege a la volee sur 3 sources reelles (course
/// `awaiting_assignment` compatible disponible, changement de statut d'une
/// course affectee, incident resolu) — jamais persiste cote serveur
/// (`persistence: "aggregated"`, `unread_count` toujours `null` dans la
/// reponse), donc aucun id unique par notification et aucun etat lu/non lu
/// cote backend : la lecture reste entierement locale a l'app.
class CourierNotification {
  const CourierNotification({
    required this.icon,
    required this.tone,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.targetType,
    this.targetId,
  });

  final String icon;
  final String tone;
  final String title;
  final String description;
  final DateTime timestamp;
  final String targetType;
  final int? targetId;

  factory CourierNotification.fromJson(Map<String, dynamic> json) => CourierNotification(
    icon: json['icon'] as String? ?? 'notifications',
    tone: json['tone'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    targetType: json['target_type'] as String? ?? '',
    targetId: json['target_id'] as int?,
  );
}

class PatientAbsenceResult {
  const PatientAbsenceResult({required this.delivery, required this.incident});
  final CourierDelivery delivery;
  final DeliveryIncident incident;
}

class CourierAvailability {
  const CourierAvailability({
    required this.isAvailableForDelivery,
    required this.coverageZoneCodes,
    required this.coverageZoneLabels,
    required this.vehicleTypeLabel,
  });

  final bool isAvailableForDelivery;
  final List<String> coverageZoneCodes;
  final List<String> coverageZoneLabels;
  final String vehicleTypeLabel;

  factory CourierAvailability.fromJson(Map<String, dynamic> json) {
    final zones = ((json['coverage_zones'] as List?) ?? [])
        .map((z) => z as Map<String, dynamic>)
        .toList();
    return CourierAvailability(
      isAvailableForDelivery: json['is_available_for_delivery'] as bool? ?? false,
      coverageZoneCodes: zones.map((z) => z['code'] as String? ?? '').toList(),
      coverageZoneLabels: zones.map((z) => z['label'] as String? ?? '').toList(),
      vehicleTypeLabel: json['vehicle_type_label'] as String? ?? '',
    );
  }
}

class CourierSummary {
  const CourierSummary({
    required this.availability,
    required this.availableCount,
    required this.activeCount,
    required this.completedCount,
    required this.balanceFcfa,
  });

  final CourierAvailability availability;
  final int availableCount;
  final int activeCount;
  final int completedCount;
  final int balanceFcfa;

  factory CourierSummary.fromJson(Map<String, dynamic> json) => CourierSummary(
    availability: CourierAvailability.fromJson(json['availability'] as Map<String, dynamic>),
    availableCount: (json['counts'] as Map<String, dynamic>)['available'] as int? ?? 0,
    activeCount: (json['counts'] as Map<String, dynamic>)['active'] as int? ?? 0,
    completedCount: (json['counts'] as Map<String, dynamic>)['completed'] as int? ?? 0,
    balanceFcfa: (json['earnings'] as Map<String, dynamic>)['balance_fcfa'] as int? ?? 0,
  );
}

/// Parcours livreur cote API reelle : resume, disponibilite, courses
/// disponibles. Reutilise le jeton deja stocke par [AuthSession].
class CourierApi {
  CourierApi(this._client);

  final ApiClient _client;

  factory CourierApi.fromSession() => CourierApi(AuthSession.instance.client);

  Future<CourierSummary> fetchSummary() async {
    final json = await _client.getJson('/mobile/courier/summary/');
    return CourierSummary.fromJson(json);
  }

  Future<List<CourierNotification>> fetchNotifications() async {
    final json = await _client.getJson('/mobile/notifications/');
    return ((json['notifications'] as List?) ?? [])
        .map((e) => CourierNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CourierAvailability> fetchAvailability() async {
    final json = await _client.getJson('/mobile/courier/availability/');
    return CourierAvailability.fromJson(json);
  }

  Future<CourierAvailability> setAvailable(bool value) async {
    final json = await _client.patchJson('/mobile/courier/availability/', {
      'is_available_for_delivery': value,
    });
    return CourierAvailability.fromJson(json);
  }

  Future<CourierLedger> fetchLedger() async {
    final json = await _client.getJson('/mobile/courier/ledger/');
    return CourierLedger.fromJson(json);
  }

  Future<CourierVerification> fetchVerification() async {
    final json = await _client.getJson('/mobile/courier/verification/');
    return CourierVerification.fromJson(json);
  }

  Future<CourierVerification> setIdentityDocumentType(String identityDocumentType) async {
    final json = await _client.postJson('/mobile/courier/verification/identity-type/', {
      'identity_document_type': identityDocumentType,
    });
    return CourierVerification.fromJson(json);
  }

  Future<CourierVerification> uploadVerificationDocument({
    required String category,
    required String side,
    required List<int> fileBytes,
    required String fileName,
    required String contentType,
  }) async {
    final json = await _client.postMultipart(
      '/mobile/courier/verification/documents/',
      fields: {'category': category, 'side': side},
      fileFieldName: 'file',
      fileBytes: fileBytes,
      fileName: fileName,
      contentType: contentType,
    );
    return CourierVerification.fromJson(json);
  }

  Future<CourierVerification> submitVerificationDossier() async {
    final json = await _client.postJson('/mobile/courier/verification/submit/');
    return CourierVerification.fromJson(json);
  }

  /// Historique complet du livreur (`delivered`/`returned`/`cancelled`),
  /// paginé côté serveur (20/page) — accumule toutes les pages : un livreur
  /// n'a réalistement qu'un historique de quelques dizaines/centaines de
  /// courses, pas des milliers, donc le tout tient sans "Charger plus".
  Future<List<CourierDelivery>> fetchDeliveryHistory() async {
    final all = <CourierDelivery>[];
    String path = '/mobile/courier/deliveries/history/';
    while (true) {
      final json = await _client.getJson(path);
      final results = (json['results'] as List?) ?? [];
      all.addAll(results.map((e) => CourierDelivery.fromJson(e as Map<String, dynamic>)));
      final next = json['next'] as String?;
      if (next == null) break;
      final page = Uri.parse(next).queryParameters['page'];
      if (page == null) break;
      path = '/mobile/courier/deliveries/history/?page=$page';
    }
    return all;
  }

  Future<List<CourierDelivery>> fetchAvailableDeliveries() async {
    final json = await _client.getJson('/mobile/courier/deliveries/available/');
    return ((json['deliveries'] as List?) ?? [])
        .map((e) => CourierDelivery.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CourierDelivery>> fetchActiveDeliveries() async {
    final json = await _client.getJson('/mobile/courier/deliveries/active/');
    return ((json['deliveries'] as List?) ?? [])
        .map((e) => CourierDelivery.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CourierDelivery> pickupDelivery(int id) async {
    final json = await _client.postJson('/mobile/courier/deliveries/$id/pickup/');
    return CourierDelivery.fromJson(json);
  }

  Future<CourierDelivery> startDelivery(int id) async {
    final json = await _client.postJson('/mobile/courier/deliveries/$id/start/');
    return CourierDelivery.fromJson(json);
  }

  Future<CourierDelivery> resendProofCode(int id) async {
    final json = await _client.postJson('/mobile/courier/deliveries/$id/resend-proof/');
    return CourierDelivery.fromJson(json);
  }

  Future<CourierDelivery> completeDelivery(
    int id, {
    required String proofCode,
    required String recipientName,
  }) async {
    final json = await _client.postJson('/mobile/courier/deliveries/$id/complete/', {
      'proof_code': proofCode,
      'recipient_name': recipientName,
    });
    return CourierDelivery.fromJson(json);
  }

  /// Parcours dedie "Client absent" (`.../patient-absence/`), distinct du
  /// signalement d'incident generique : exige la double confirmation
  /// (deux appels + dix minutes d'attente) et fait transiter la course vers
  /// `returning` plutot que de simplement journaliser un incident.
  Future<PatientAbsenceResult> reportPatientAbsence(
    int id, {
    required bool contactAttemptsConfirmed,
    required bool waitConfirmed,
    required String description,
  }) async {
    final json = await _client.postJson('/mobile/courier/deliveries/$id/patient-absence/', {
      'contact_attempts_confirmed': contactAttemptsConfirmed,
      'wait_confirmed': waitConfirmed,
      'description': description,
    });
    return PatientAbsenceResult(
      delivery: CourierDelivery.fromJson(json['delivery'] as Map<String, dynamic>),
      incident: DeliveryIncident.fromJson(json['incident'] as Map<String, dynamic>),
    );
  }

  Future<DeliveryIncident> reportIncident(
    int id, {
    required String incidentType,
    required String severity,
    required String description,
  }) async {
    final json = await _client.postJson('/mobile/courier/deliveries/$id/incidents/', {
      'incident_type': incidentType,
      'severity': severity,
      'description': description,
    });
    return DeliveryIncident.fromJson(json);
  }

  /// Ping de position ponctuel envoye pendant une course en cours
  /// (assigned/picked_up/in_transit uniquement, rejete par le backend sinon).
  /// Arrondi a 6 decimales : le GPS renvoie souvent plus de precision que
  /// n'en accepte le DecimalField cote Django (max_digits=9, decimal_places=6).
  Future<void> updatePosition(int id, {required double latitude, required double longitude}) {
    return _client.postJson('/mobile/courier/deliveries/$id/position/', {
      'latitude': double.parse(latitude.toStringAsFixed(6)),
      'longitude': double.parse(longitude.toStringAsFixed(6)),
    });
  }
}

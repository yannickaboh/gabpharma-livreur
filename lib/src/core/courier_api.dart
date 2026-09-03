import 'api_client.dart';
import 'auth_session.dart';

class Pharmacy {
  const Pharmacy({
    required this.id,
    required this.name,
    required this.zoneLabel,
    required this.address,
    required this.phone,
  });

  final int id;
  final String name;
  final String zoneLabel;
  final String address;
  final String phone;

  factory Pharmacy.fromJson(Map<String, dynamic> json) => Pharmacy(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    zoneLabel: json['zone_label'] as String? ?? '',
    address: json['address'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
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
    this.recipientName,
  });

  final int id;
  final String status;
  final String statusLabel;
  final String zoneLabel;
  final int deliveryFeeFcfa;
  final int courierShareFcfa;
  final int platformShareFcfa;
  final Pharmacy pharmacy;
  final String? recipientName;

  factory CourierDelivery.fromJson(Map<String, dynamic> json) => CourierDelivery(
    id: json['id'] as int,
    status: json['status'] as String? ?? '',
    statusLabel: json['status_label'] as String? ?? '',
    zoneLabel: json['zone_label'] as String? ?? '',
    deliveryFeeFcfa: json['delivery_fee_fcfa'] as int? ?? 0,
    courierShareFcfa: json['courier_share_fcfa'] as int? ?? 0,
    platformShareFcfa: json['platform_share_fcfa'] as int? ?? 0,
    pharmacy: Pharmacy.fromJson(json['pharmacy'] as Map<String, dynamic>),
    recipientName: (json['order'] as Map<String, dynamic>?)?['patient'] != null
        ? ((json['order'] as Map<String, dynamic>)['patient'] as Map<String, dynamic>)['name'] as String?
        : null,
  );
}

class CourierAvailability {
  const CourierAvailability({
    required this.isAvailableForDelivery,
    required this.coverageZoneLabels,
    required this.vehicleTypeLabel,
  });

  final bool isAvailableForDelivery;
  final List<String> coverageZoneLabels;
  final String vehicleTypeLabel;

  factory CourierAvailability.fromJson(Map<String, dynamic> json) => CourierAvailability(
    isAvailableForDelivery: json['is_available_for_delivery'] as bool? ?? false,
    coverageZoneLabels: ((json['coverage_zones'] as List?) ?? [])
        .map((z) => (z as Map<String, dynamic>)['label'] as String? ?? '')
        .toList(),
    vehicleTypeLabel: json['vehicle_type_label'] as String? ?? '',
  );
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

  Future<CourierAvailability> setAvailable(bool value) async {
    final json = await _client.patchJson('/mobile/courier/availability/', {
      'is_available_for_delivery': value,
    });
    return CourierAvailability.fromJson(json);
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
}

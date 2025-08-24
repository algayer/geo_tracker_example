import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'geo_tracker_method_channel.dart';

/// DTO: status de permissões
class PermissionsStatus {
  final bool fine;
  final bool coarse;
  final bool rationale;

  const PermissionsStatus({
    required this.fine,
    required this.coarse,
    required this.rationale,
  });

  bool get anyGranted => fine || coarse;
}

/// DTO: amostra de localização
class LocationSample {
  final double lat;
  final double lng;
  final double accuracy; // metros
  final int ts; // epoch ms
  final double? speedMps;
  final double? bearing;

  const LocationSample({
    required this.lat,
    required this.lng,
    required this.accuracy,
    required this.ts,
    this.speedMps,
    this.bearing,
  });

  factory LocationSample.fromMap(Map<String, dynamic> m) => LocationSample(
        lat: (m['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (m['lng'] as num?)?.toDouble() ?? 0.0,
        accuracy: (m['accuracy'] as num?)?.toDouble() ?? 0.0,
        ts: (m['ts'] as num?)?.toInt() ?? 0,
        speedMps: (m['speed'] as num?)?.toDouble(),
        bearing: (m['bearing'] as num?)?.toDouble(),
      );
}

/// DTO: entrada para um destino no cálculo em lote
class DestPointInput {
  final String? id;
  final double lat;
  final double lng;

  const DestPointInput({this.id, required this.lat, required this.lng});

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'lat': lat,
        'lng': lng,
      };
}

/// DTO: resultado (único) distância + ETA
class DistanceEta {
  final double meters;
  final double etaSeconds;
  final double speedMps;
  final String speedSource;

  const DistanceEta({
    required this.meters,
    required this.etaSeconds,
    required this.speedMps,
    required this.speedSource,
  });

  factory DistanceEta.fromMap(Map<String, dynamic> m) => DistanceEta(
        meters: (m['meters'] as num?)?.toDouble() ?? 0.0,
        etaSeconds: (m['etaSeconds'] as num?)?.toDouble() ?? double.nan,
        speedMps: (m['speedMps'] as num?)?.toDouble() ?? 0.0,
        speedSource: (m['speedSource'] ?? '').toString(),
      );
}

/// DTO: uma linha do resultado em lote
class DistanceEtaRow {
  final int index;
  final String? id;
  final double lat;
  final double lng;
  final double meters;
  final double etaSeconds;

  const DistanceEtaRow({
    required this.index,
    this.id,
    required this.lat,
    required this.lng,
    required this.meters,
    required this.etaSeconds,
  });

  factory DistanceEtaRow.fromMap(Map<String, dynamic> m) => DistanceEtaRow(
        index: (m['index'] as num?)?.toInt() ?? 0,
        id: m['id']?.toString(),
        lat: (m['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (m['lng'] as num?)?.toDouble() ?? 0.0,
        meters: (m['meters'] as num?)?.toDouble() ?? 0.0,
        etaSeconds: (m['etaSeconds'] as num?)?.toDouble() ?? double.nan,
      );
}

/// DTO: resultado em lote distância + ETA
class DistancesEta {
  final double fromLat;
  final double fromLng;
  final String profile;
  final double speedMps;
  final String speedSource;
  final List<DistanceEtaRow> rows;

  const DistancesEta({
    required this.fromLat,
    required this.fromLng,
    required this.profile,
    required this.speedMps,
    required this.speedSource,
    required this.rows,
  });

  factory DistancesEta.fromMap(Map<String, dynamic> m) {
    final rows = (m['rows'] as List? ?? const [])
        .map((e) => DistanceEtaRow.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    final from = Map<String, dynamic>.from(m['from'] as Map? ?? const {});
    return DistancesEta(
      fromLat: (from['lat'] as num?)?.toDouble() ?? 0.0,
      fromLng: (from['lng'] as num?)?.toDouble() ?? 0.0,
      profile: (m['profile'] ?? '').toString(),
      speedMps: (m['speedMps'] as num?)?.toDouble() ?? 0.0,
      speedSource: (m['speedSource'] ?? '').toString(),
      rows: rows,
    );
  }
}

/// Contrato base da plataforma.
abstract class GeoTrackerPlatform extends PlatformInterface {
  GeoTrackerPlatform() : super(token: _token);

  static final Object _token = Object();

  static GeoTrackerPlatform _instance = MethodChannelGeoTracker();

  /// Instância padrão
  static GeoTrackerPlatform get instance => _instance;

  /// Substituição para testes/outros targets
  static set instance(GeoTrackerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // --------- Métodos do contrato ---------

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  /// Checa permissões de localização (FINE/COARSE).
  Future<PermissionsStatus> checkPermissions() {
    throw UnimplementedError('checkPermissions() has not been implemented.');
  }

  /// Dispara o diálogo do Android para solicitar permissões.
  Future<bool> requestPermissions() {
    throw UnimplementedError('requestPermissions() has not been implemented.');
  }

  /// Última ou atual localização (pode lançar PlatformException "NO_PERMISSION").
  Future<LocationSample> getLastKnownOrCurrent({int timeoutMs = 3000}) {
    throw UnimplementedError('getLastKnownOrCurrent() has not been implemented.');
  }

  /// Distância (metros) entre {from} e {to} via Haversine.
  Future<double> computeDistanceMeters({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    throw UnimplementedError('computeDistanceMeters() has not been implemented.');
  }

  /// Distância + ETA para **um** destino.
  Future<DistanceEta> computeDistanceEta({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    String profile = 'drive_city',
    double? customSpeedMps,
    int timeoutMs = 3000,
  }) {
    throw UnimplementedError('computeDistanceEta() has not been implemented.');
  }

  /// Distância + ETA para **vários** destinos.
  Future<DistancesEta> computeDistancesEta({
    required double fromLat,
    required double fromLng,
    required List<DestPointInput> to,
    String profile = 'drive_city',
    double? customSpeedMps,
    int timeoutMs = 3000,
  }) {
    throw UnimplementedError('computeDistancesEta() has not been implemented.');
  }
}

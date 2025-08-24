import 'geo_tracker_platform_interface.dart';

class GeoTracker {
  /// Versão da plataforma.
  Future<String?> getPlatformVersion() {
    return GeoTrackerPlatform.instance.getPlatformVersion();
  }

  /// Checar permissões (FINE/COARSE).
  Future<PermissionsStatus> checkPermissions() {
    return GeoTrackerPlatform.instance.checkPermissions();
  }

  /// Solicitar permissões (depois use [checkPermissions] para confirmar).
  Future<bool> requestPermissions() {
    return GeoTrackerPlatform.instance.requestPermissions();
  }

  /// Última ou atual localização (timeout default: 3000ms).
  Future<LocationSample> getLastKnownOrCurrent({int timeoutMs = 3000}) {
    return GeoTrackerPlatform.instance.getLastKnownOrCurrent(timeoutMs: timeoutMs);
  }

  /// Distância em metros entre dois pontos.
  Future<double> computeDistanceMeters({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    return GeoTrackerPlatform.instance.computeDistanceMeters(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );
  }

  /// Distância + ETA (em segundos) para **um** destino.
  /// Perfis suportados no Android: walk | bike | drive_city | drive_fast | current | custom.
  Future<DistanceEta> computeDistanceEta({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    String profile = 'drive_city',
    double? customSpeedMps,
    int timeoutMs = 3000,
  }) {
    return GeoTrackerPlatform.instance.computeDistanceEta(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
      profile: profile,
      customSpeedMps: customSpeedMps,
      timeoutMs: timeoutMs,
    );
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
    return GeoTrackerPlatform.instance.computeDistancesEta(
      fromLat: fromLat,
      fromLng: fromLng,
      to: to,
      profile: profile,
      customSpeedMps: customSpeedMps,
      timeoutMs: timeoutMs,
    );
  }

  /// Utilitário local: ETA (s) = distância / velocidade.
  /// Por padrão 40 km/h (≈ 11.11 m/s).
  int estimateEtaSeconds(double distanceMeters, {double speedMps = 11.11}) {
    if (speedMps <= 0) return 0;
    return (distanceMeters / speedMps).round();
  }
}

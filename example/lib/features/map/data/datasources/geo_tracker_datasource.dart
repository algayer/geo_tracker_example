import 'package:latlong2/latlong.dart' as ll;
import '../../../../core/channels/geo_tracker_channel.dart';
import '../../../map/domain/entities/location_sample_entity.dart';
import '../../../map/domain/entities/distance_eta_entity.dart';

class GeoTrackerDataSource {
  final GeoTrackerChannel channel;

  GeoTrackerDataSource(this.channel);

  /// Retorna true se já há permissão (fine ou coarse) ou se o request foi disparado.
  Future<bool> ensureLocationPermission() async {
    final status = await channel.checkPermissions();
    final fine = status['fine'] == true;
    final coarse = status['coarse'] == true;
    if (fine || coarse) return true;
    return channel.requestPermissions();
  }

  /// Localização atual (ou último fix válido) via plugin.
  Future<LocationSampleEntity> getCurrentLocation({int timeoutMs = 3000}) async {
    final map = await channel.getLastKnownOrCurrent(timeoutMs: timeoutMs);

    // Parsing defensivo
    final num? lat = map['lat'] as num?;
    final num? lng = map['lng'] as num?;
    if (lat == null || lng == null) {
      throw FormatException('Payload inválido: lat/lng ausentes');
    }

    return LocationSampleEntity(
      lat: lat.toDouble(),
      lng: lng.toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      timestampMillis: (map['ts'] as num?)?.toInt(),
      speedMps: (map['speed'] as num?)?.toDouble(),
      bearing: (map['bearing'] as num?)?.toDouble(),
    );
  }

  /// Distância simples (metros) entre dois pontos.
  Future<double> computeDistanceMeters(ll.LatLng from, ll.LatLng to) {
    return channel.computeDistanceMeters(
      fromLat: from.latitude,
      fromLng: from.longitude,
      toLat: to.latitude,
      toLng: to.longitude,
    );
  }

  /// (Opcional) Versão raw, sem LatLng.
  Future<double> computeDistanceMetersRaw({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    return channel.computeDistanceMeters(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );
  }

  /// Distância + ETA (segundos) usando perfil fixo "drive_city".
  Future<DistanceEtaEntity> computeDistanceEta(
    ll.LatLng from,
    ll.LatLng to, {
    int timeoutMs = 3000,
  }) async {
    final map = await channel.computeDistanceEta(
      fromLat: from.latitude,
      fromLng: from.longitude,
      toLat: to.latitude,
      toLng: to.longitude,
      profile: 'drive_city',
      timeoutMs: timeoutMs,
    );

    final num? meters = map['meters'] as num?;
    if (meters == null) {
      throw FormatException('Payload inválido: meters ausente');
    }

    return DistanceEtaEntity(
      meters: meters.toDouble(),
      etaSeconds: (map['etaSeconds'] as num?)?.toDouble() ?? double.nan,
    );
  }
}

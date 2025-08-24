import 'package:flutter/services.dart';

class GeoTrackerChannel {
  static const MethodChannel _ch = MethodChannel('geo_tracker');

  // -------- Permissões --------

  /// Checa permissões (fine/coarse).
  Future<Map<String, dynamic>> checkPermissions() async {
    final map =
        await _ch.invokeMapMethod<String, dynamic>('checkPermissions') ?? const {};
    return map;
  }

  /// Solicita permissões.
  Future<bool> requestPermissions() async {
    final map =
        await _ch.invokeMapMethod<String, dynamic>('requestPermissions') ?? const {};
    return map['requested'] == true;
  }

  // -------- Localização --------

  /// Última ou atual localização.
  Future<Map<String, dynamic>> getLastKnownOrCurrent({int timeoutMs = 3000}) async {
    final map =
        await _ch.invokeMapMethod<String, dynamic>('getLastKnownOrCurrent', {
      'timeoutMs': timeoutMs,
    }) ?? const {};
    return map;
  }

  // -------- Distância --------

  /// Distância (m) via Haversine.
  Future<double> computeDistanceMeters({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final map =
        await _ch.invokeMapMethod<String, dynamic>('computeDistanceMeters', {
      'from': {'lat': fromLat, 'lng': fromLng},
      'to': {'lat': toLat, 'lng': toLng},
    }) ?? const {};
    final num? meters = map['meters'] as num?;
    return meters?.toDouble() ?? 0.0;
  }

  // -------- Distância + ETA --------

  /// Distância + ETA (s) entre dois pontos.
  /// [profile]: walk | bike | drive_city | drive_fast | current | custom.
  /// Se usar 'custom', informe [customSpeedMps] (> 0).
  Future<Map<String, dynamic>> computeDistanceEta({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    String profile = 'drive_city',
    double? customSpeedMps,
    int timeoutMs = 3000,
  }) async {
    final args = <String, dynamic>{
      'from': {'lat': fromLat, 'lng': fromLng},
      'to': {'lat': toLat, 'lng': toLng},
      'profile': profile,
      'timeoutMs': timeoutMs,
    };
    if (customSpeedMps != null) args['customSpeedMps'] = customSpeedMps;

    final map =
        await _ch.invokeMapMethod<String, dynamic>('computeDistanceEta', args) ??
            const {};
    return map;
  }

  /// Distância + ETA (s) para *vários* destinos.
  /// Ex.: to = [{'id':'A','lat':-23.5,'lng':-46.6}, ...]
  Future<Map<String, dynamic>> computeDistancesEta({
    required double fromLat,
    required double fromLng,
    required List<Map<String, dynamic>> to,
    String profile = 'drive_city',
    double? customSpeedMps,
    int timeoutMs = 3000,
  }) async {
    final args = <String, dynamic>{
      'from': {'lat': fromLat, 'lng': fromLng},
      'to': to,
      'profile': profile,
      'timeoutMs': timeoutMs,
    };
    if (customSpeedMps != null) args['customSpeedMps'] = customSpeedMps;

    final map = await _ch.invokeMapMethod<String, dynamic>(
          'computeDistancesEta',
          args,
        ) ??
        const {};
    return map;
  }
}

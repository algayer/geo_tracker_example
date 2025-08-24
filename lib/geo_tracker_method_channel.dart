import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'geo_tracker_platform_interface.dart';

/// Implementação de [GeoTrackerPlatform] via MethodChannel "geo_tracker".
class MethodChannelGeoTracker extends GeoTrackerPlatform {
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel('geo_tracker');

  // ---------------- Básico ----------------

  @override
  Future<String?> getPlatformVersion() async {
    return methodChannel.invokeMethod<String>('getPlatformVersion');
  }

  @override
  Future<PermissionsStatus> checkPermissions() async {
    final map = await methodChannel.invokeMapMethod<String, dynamic>('checkPermissions') ?? const {};
    return PermissionsStatus(
      fine: map['fine'] == true,
      coarse: map['coarse'] == true,
      rationale: map['rationale'] == true,
    );
  }

  @override
  Future<bool> requestPermissions() async {
    final map = await methodChannel.invokeMapMethod<String, dynamic>('requestPermissions') ?? const {};
    return map['requested'] == true;
  }

  @override
  Future<LocationSample> getLastKnownOrCurrent({int timeoutMs = 3000}) async {
    final map = await methodChannel.invokeMapMethod<String, dynamic>(
      'getLastKnownOrCurrent',
      {'timeoutMs': timeoutMs},
    ) ?? const {};
    return LocationSample.fromMap(map);
  }

  // ---------------- Distância ----------------

  @override
  Future<double> computeDistanceMeters({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final map = await methodChannel.invokeMapMethod<String, dynamic>(
      'computeDistanceMeters',
      {
        'from': {'lat': fromLat, 'lng': fromLng},
        'to': {'lat': toLat, 'lng': toLng},
      },
    ) ?? const {};
    return (map['meters'] as num?)?.toDouble() ?? 0.0;
  }

  // ---------------- Distância + ETA ----------------

  @override
  Future<DistanceEta> computeDistanceEta({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    String profile = 'drive_city', // walk | bike | drive_city | drive_fast | current | custom
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

    final map = await methodChannel.invokeMapMethod<String, dynamic>(
      'computeDistanceEta',
      args,
    ) ?? const {};

    return DistanceEta.fromMap(map);
  }

  @override
  Future<DistancesEta> computeDistancesEta({
    required double fromLat,
    required double fromLng,
    required List<DestPointInput> to,
    String profile = 'drive_city',
    double? customSpeedMps,
    int timeoutMs = 3000,
  }) async {
    final args = <String, dynamic>{
      'from': {'lat': fromLat, 'lng': fromLng},
      'to': to.map((e) => e.toMap()).toList(),
      'profile': profile,
      'timeoutMs': timeoutMs,
    };
    if (customSpeedMps != null) args['customSpeedMps'] = customSpeedMps;

    final map = await methodChannel.invokeMapMethod<String, dynamic>(
      'computeDistancesEta',
      args,
    ) ?? const {};

    return DistancesEta.fromMap(map);
  }
}

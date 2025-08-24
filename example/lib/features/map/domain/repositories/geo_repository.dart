import 'package:latlong2/latlong.dart' as ll;
import '../entities/location_sample_entity.dart';
import '../entities/distance_eta_entity.dart';

abstract class GeoRepository {
  Future<bool> ensurePermission();
  Future<LocationSampleEntity> getCurrentLocation({int timeoutMs = 3000});
  Future<double> computeDistanceMeters(ll.LatLng from, ll.LatLng to);
  Future<DistanceEtaEntity> computeDistanceEta(ll.LatLng from, ll.LatLng to);
  Future<List<ll.LatLng>> getRoute(ll.LatLng origin, ll.LatLng destination);
}

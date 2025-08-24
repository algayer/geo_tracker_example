import 'package:latlong2/latlong.dart' as ll;
import '../../domain/entities/location_sample_entity.dart';
import '../../domain/entities/distance_eta_entity.dart'; // 👈 novo
import '../../domain/repositories/geo_repository.dart';
import '../datasources/geo_tracker_datasource.dart';
import '../datasources/route_service.dart';

class GeoRepositoryImpl implements GeoRepository {
  final GeoTrackerDataSource ds;
  final RouteService routeService;

  GeoRepositoryImpl({required this.ds, required this.routeService});

  @override
  Future<bool> ensurePermission() => ds.ensureLocationPermission();

  @override
  Future<LocationSampleEntity> getCurrentLocation({int timeoutMs = 3000}) =>
      ds.getCurrentLocation(timeoutMs: timeoutMs);

  @override
  Future<double> computeDistanceMeters(ll.LatLng from, ll.LatLng to) =>
      ds.computeDistanceMeters(from, to);

  @override
  Future<DistanceEtaEntity> computeDistanceEta(ll.LatLng from, ll.LatLng to) =>
      ds.computeDistanceEta(from, to);

  @override
  Future<List<ll.LatLng>> getRoute(ll.LatLng origin, ll.LatLng destination) =>
      routeService.buildRoute(origin, destination);
}

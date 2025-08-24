import 'package:latlong2/latlong.dart' as ll;
import '../repositories/geo_repository.dart';

class ComputeDistanceUseCase {
  final GeoRepository repo;
  ComputeDistanceUseCase(this.repo);

  Future<double> call(ll.LatLng origin, ll.LatLng destination) {
    return repo.computeDistanceMeters(origin, destination);
  }
}

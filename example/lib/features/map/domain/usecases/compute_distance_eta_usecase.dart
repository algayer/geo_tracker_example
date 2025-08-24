import 'package:latlong2/latlong.dart' as ll;
import '../entities/distance_eta_entity.dart';
import '../repositories/geo_repository.dart';

class ComputeDistanceEtaUseCase {
  final GeoRepository repo;
  ComputeDistanceEtaUseCase(this.repo);

  Future<DistanceEtaEntity> call(ll.LatLng origin, ll.LatLng destination) {
    return repo.computeDistanceEta(origin, destination);
  }
}

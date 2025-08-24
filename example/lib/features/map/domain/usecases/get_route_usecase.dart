import 'package:latlong2/latlong.dart' as ll;
import '../repositories/geo_repository.dart';

class GetRouteUseCase {
  final GeoRepository repo;
  GetRouteUseCase(this.repo);

  Future<List<ll.LatLng>> call(ll.LatLng origin, ll.LatLng destination) {
    return repo.getRoute(origin, destination);
  }
}

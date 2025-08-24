import 'package:latlong2/latlong.dart' as ll;

/// Serviço de rota "mock": gera uma polilinha reta entre origem e destino.
abstract class RouteService {
  Future<List<ll.LatLng>> buildRoute(
    ll.LatLng origin,
    ll.LatLng destination, {
    int samples = 24, // default
  });
}

class FakeRouteService implements RouteService {
  @override
  Future<List<ll.LatLng>> buildRoute(
    ll.LatLng origin,
    ll.LatLng destination, {
    int samples = 24,
  }) async {
    // garante pelo menos 1 segmento e evita divisão por zero
    final n = samples <= 0 ? 1 : samples;

    if (origin == destination) {
      return [origin];
    }

    final pts = List<ll.LatLng>.generate(n + 1, (i) {
      final t = i / n;
      final lat = origin.latitude + (destination.latitude - origin.latitude) * t;
      final lng = origin.longitude + (destination.longitude - origin.longitude) * t;
      return ll.LatLng(lat, lng);
    });

    return pts;
  }
}

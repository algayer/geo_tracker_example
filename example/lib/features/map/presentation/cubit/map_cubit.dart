import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geo_tracker_example/features/map/domain/entities/distance_eta_entity.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../domain/usecases/get_current_location_usecase.dart';
import '../../domain/usecases/get_route_usecase.dart';
import '../../domain/usecases/compute_distance_eta_usecase.dart';
import 'map_state.dart';

class MapCubit extends Cubit<MapState> {
  final GetCurrentLocationUseCase getCurrentLocation;
  final GetRouteUseCase getRoute;
  final ComputeDistanceEtaUseCase computeDistanceEta;

  MapCubit({
    required this.getCurrentLocation,
    required this.getRoute,
    required this.computeDistanceEta,
  }) : super(const MapState());

  // Timeouts padrão
  static const int _tInitMs = 4000;
  static const int _tRecomputeMs = 3000;

  // Mock de destino
  final ll.LatLng mockDestination =
      const ll.LatLng(-29.70470892010712, -52.43658486085902);

  // Sequenciador para evitar race conditions entre chamadas concorrentes
  int _seq = 0;

  Future<void> init() async {
    final seq = ++_seq;
    _safeEmit(state.copyWith(isLoading: true, clearError: true));
    try {
      final loc = await getCurrentLocation(timeoutMs: _tInitMs);
      final origin = ll.LatLng(loc.lat, loc.lng);

      // roda em paralelo: rota + dist/eta
      final results = await Future.wait([
        getRoute(origin, mockDestination),
        computeDistanceEta(origin, mockDestination),
      ]);

      if (!_isCurrent(seq)) return;

      final poly = results[0] as List<ll.LatLng>;
      final res = results[1] as DistanceEtaEntity;

      final meters = res.meters.isFinite ? res.meters : null;
      final eta = res.etaSeconds.isFinite ? res.etaSeconds : null;

      _safeEmit(state.copyWith(
        isLoading: false,
        current: origin,
        destination: mockDestination,
        polyline: poly,
        distanceMeters: meters,
        etaSeconds: eta,
      ));
    } catch (e) {
      if (!_isCurrent(seq)) return;
      _safeEmit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  /// Recalcula distância/ETA (e opcionalmente refaz origem e rota).
  Future<void> recomputeDistance({bool refreshOrigin = false}) async {
    final seq = ++_seq;

    var origin = state.current;
    final dest = state.destination;
    if (dest == null) return;

    _safeEmit(state.copyWith(isRecomputing: true, clearError: true));

    try {
      if (refreshOrigin || origin == null) {
        final loc = await getCurrentLocation(timeoutMs: _tRecomputeMs);
        origin = ll.LatLng(loc.lat, loc.lng);
      }

      // rota + dist/eta
      final results = await Future.wait([
        getRoute(origin, dest),
        computeDistanceEta(origin, dest),
      ]);

      if (!_isCurrent(seq)) return;

      final poly = results[0] as List<ll.LatLng>;
      final res = results[1] as DistanceEtaEntity;

      final meters = res.meters.isFinite ? res.meters : null;
      final eta = res.etaSeconds.isFinite ? res.etaSeconds : null;

      _safeEmit(state.copyWith(
        isRecomputing: false,
        current: origin,
        polyline: poly,
        distanceMeters: meters,
        etaSeconds: eta,
      ));
    } catch (e) {
      if (!_isCurrent(seq)) return;
      _safeEmit(state.copyWith(isRecomputing: false, error: e.toString()));
    }
  }

  /// Permite trocar destino dinamicamente.
  Future<void> setDestination(ll.LatLng destination, {bool recompute = true}) async {
    _safeEmit(state.copyWith(destination: destination));
    if (recompute) {
      await recomputeDistance(refreshOrigin: false);
    }
  }

  // ---- helpers ----

  bool _isCurrent(int seq) => seq == _seq;

  void _safeEmit(MapState newState) {
    if (!isClosed) emit(newState);
  }
}

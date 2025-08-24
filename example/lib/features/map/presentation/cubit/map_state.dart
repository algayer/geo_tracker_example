import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart' as ll;

class MapState extends Equatable {
  final bool isLoading;
  final bool isRecomputing;
  final String? error;
  final ll.LatLng? current; // Posição atual/origem.
  final ll.LatLng? destination; // Destino mock.
  final List<ll.LatLng> polyline; // Rota a desenhar no mapa
  final double? distanceMeters;
  final double? etaSeconds;

  const MapState({
    this.isLoading = false,
    this.isRecomputing = false,
    this.error,
    this.current,
    this.destination,
    this.polyline = const [],
    this.distanceMeters,
    this.etaSeconds,
  });

  MapState copyWith({
    bool? isLoading,
    bool? isRecomputing,
    String? error,
    ll.LatLng? current,
    ll.LatLng? destination,
    List<ll.LatLng>? polyline,
    double? distanceMeters,
    double? etaSeconds,
    bool clearError = false,
  }) {
    return MapState(
      isLoading: isLoading ?? this.isLoading,
      isRecomputing: isRecomputing ?? this.isRecomputing,
      error: clearError ? null : (error ?? this.error),
      current: current ?? this.current,
      destination: destination ?? this.destination,
      polyline: polyline ?? this.polyline,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      etaSeconds: etaSeconds ?? this.etaSeconds,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, isRecomputing, error, current, destination, polyline, distanceMeters, etaSeconds];
}

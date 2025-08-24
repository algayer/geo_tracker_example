import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' as fb;

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:intl/intl.dart';

import 'package:geo_tracker_example/features/map/presentation/cubit/map_cubit.dart';
import 'package:geo_tracker_example/features/map/presentation/cubit/map_state.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Controller do flutter_map (OSM)
  final MapController _map = MapController();

  // Sinaliza quando o mapa terminou de inicializar (onMapReady)
  bool _mapReady = false;

  // Bounds pendentes para aplicar assim que o mapa estiver pronto
  LatLngBounds? _pendingBounds;

  @override
  void initState() {
    super.initState();
    // busca localização, rota e distância/ETA
    fb.BlocProvider.of<MapCubit>(context).init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rota para o Mock (OSM)')),
      body: fb.BlocConsumer<MapCubit, MapState>(
        // Reage a mudanças de origem/destino/rota para ajustar câmera
        listenWhen: (prev, curr) =>
            prev.current != curr.current ||
            prev.destination != curr.destination ||
            prev.polyline != curr.polyline,
        listener: (context, state) {
          final cur = state.current;
          final dest = state.destination;
          if (cur != null && dest != null && state.polyline.isNotEmpty) {
            final bounds = LatLngBounds.fromPoints([cur, dest]);
            if (_mapReady) {
              _map.fitCamera(
                CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
              );
            } else {
              _pendingBounds = bounds;
            }
          }
        },
        // UI principal
        builder: (context, state) {
          if (state.isLoading) return const Center(child: CircularProgressIndicator());

          if (state.error != null) {
            // Erro com ação de retry
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Erro: ${state.error}'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => fb.BlocProvider.of<MapCubit>(context).init(),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          if (state.current == null) {
            return const Center(child: Text('Sem localização ainda.'));
          }

          final ll.LatLng current = state.current!;
          final ll.LatLng? dest = state.destination;
          final List<ll.LatLng> routePts = state.polyline;

          return Stack(
            children: [
              // -------- Mapa (OSM) --------
              FlutterMap(
                mapController: _map,
                options: MapOptions(
                  initialCenter: current,
                  initialZoom: 15,
                  onMapReady: () {
                    _mapReady = true;
                    final b = _pendingBounds;
                    if (b != null) {
                      _map.fitCamera(
                        CameraFit.bounds(bounds: b, padding: const EdgeInsets.all(60)),
                      );
                      _pendingBounds = null;
                    }
                  },
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                ),
                children: [
                  // Tiles do OpenStreetMap
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.geo_tracker_example',
                    minZoom: 1,
                    maxZoom: 19,
                  ),
                  // Polilinha da rota mock
                  if (routePts.isNotEmpty)
                    PolylineLayer(polylines: [Polyline(points: routePts, strokeWidth: 6)]),
                  // Marcadores de origem/destino
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: current,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.my_location, color: Colors.blue),
                      ),
                      if (dest != null)
                        Marker(
                          point: dest,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.flag, color: Colors.red),
                        ),
                    ],
                  ),
                  // Atribuição OSM
                  const RichAttributionWidget(
                    attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
                  ),
                ],
              ),

              // -------- Botão "Recalcular" (overlay no topo) --------
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ElevatedButton.icon(
                      onPressed: state.isRecomputing
                          ? null
                          : () async {
                              final cubit = fb.BlocProvider.of<MapCubit>(context);
                              await cubit.recomputeDistance(refreshOrigin: true);
                              if (!mounted) return;
                              final s = cubit.state;
                              if (s.distanceMeters != null || s.etaSeconds != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Atualizado — '
                                      'distancia: ${s.distanceMeters != null ? _fmtDistance(s.distanceMeters!) : '-'}, '
                                      'tempo estimado: ${s.etaSeconds != null ? _fmtEta(s.etaSeconds!) : '-'}',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                      icon: state.isRecomputing
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(state.isRecomputing ? 'Recalculando…' : 'Recalcular'),
                    ),
                  ),
                ),
              ),

              // -------- Card com distância e ETA --------
              if (state.distanceMeters != null || state.etaSeconds != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (state.distanceMeters != null)
                            Text('Distância: ${_fmtDistance(state.distanceMeters!)}'),
                          if (state.etaSeconds != null)
                            Text('Tempo estimado: ${_fmtEta(state.etaSeconds!)}'),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ---------- Helpers de formatação ----------

  // Distância:
  // - < 1000 m  → "NNN m"
  // - < 10 km   → "X,XX km" (2 decimais)
  // - < 100 km  → "XX,X km" (1 decimal)
  // - >= 100 km → "XXX km" (0 decimais)
  String _fmtDistance(double meters) {
    if (!meters.isFinite || meters < 0) return '—';
    if (meters < 1000) return '${meters.round()} m';

    final km = meters / 1000.0;

    int decimals;
    if (km < 10) {
      decimals = 2;
    } else if (km < 100) {
      decimals = 1;
    } else {
      decimals = 0;
    }

    final pattern = decimals == 0 ? '#,##0' : '#,##0.${'0' * decimals}';
    final nf = NumberFormat(pattern, 'pt_BR');
    return '${nf.format(km)} km';
  }

  // ETA amigável: "Hh Mm", "Mm Ss" ou "Ss"
  String _fmtEta(double seconds) {
    if (seconds.isNaN || !seconds.isFinite || seconds <= 0) return '—';
    final s = seconds.round();
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${sec}s';
    return '${sec}s';
  }
}

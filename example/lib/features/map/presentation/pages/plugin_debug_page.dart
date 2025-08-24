import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:geo_tracker_example/core/channels/geo_tracker_channel.dart';

class PluginDebugSimplePage extends StatefulWidget {
  const PluginDebugSimplePage({super.key});

  @override
  State<PluginDebugSimplePage> createState() => _PluginDebugSimplePageState();
}

class _PluginDebugSimplePageState extends State<PluginDebugSimplePage> {
  final _logs = <String>[];
  final _scroll = ScrollController();

  GeoTrackerChannel get _channel => Modular.get<GeoTrackerChannel>();

  // guarda última posição obtida
  double? _curLat;
  double? _curLng;

  // destino mock (ajuste se quiser) -29.689943007555843, -52.4551334349335
  static const double _destLat = -29.689943007555843;
  static const double _destLng = -52.4551334349335;

  @override
  void initState() {
    super.initState();
    _addLog('Tela pronta. Use os botões abaixo para acionar o plugin.');
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // --- helpers ---
  String _ts() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    final ms = now.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  void _addLog(String msg) {
    // ignore: avoid_print
    print('[PluginDebug] $msg');
    setState(() => _logs.add('${_ts()} — $msg'));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // --- ações dos botões ---

  Future<void> _onCheckPermissions() async {
    _addLog('checkPermissions()…');
    try {
      final st = await _channel.checkPermissions();
      _addLog('checkPermissions → $st');
    } catch (e) {
      _addLog('ERRO checkPermissions: $e');
    }
  }

  Future<void> _onRequestPermissions() async {
    _addLog('requestPermissions()…');
    try {
      final ok = await _channel.requestPermissions();
      _addLog('requestPermissions → $ok');
    } catch (e) {
      _addLog('ERRO requestPermissions: $e');
    }
  }

  Future<void> _onGetLocation() async {
    _addLog('getLastKnownOrCurrent(timeout=4000)…');
    try {
      final map = await _channel.getLastKnownOrCurrent(timeoutMs: 4000);
      final lat = (map['lat'] as num?)?.toDouble();
      final lng = (map['lng'] as num?)?.toDouble();
      final acc = (map['accuracy'] as num?)?.toDouble();
      final ts = (map['ts'] as num?)?.toInt();
      final speed = (map['speed'] as num?)?.toDouble();
      final bearing = (map['bearing'] as num?)?.toDouble();

      if (lat != null && lng != null) {
        _curLat = lat;
        _curLng = lng;
        _addLog(
          'LOC → lat=$lat, lng=$lng, acc=${acc ?? '—'}m, ts=${ts ?? '—'}, '
          'speed=${speed ?? '—'}m/s, bearing=${bearing ?? '—'}°',
        );
      } else {
        _addLog('LOC → resposta sem lat/lng: $map');
      }
    } on PlatformException catch (e) {
      _addLog('ERRO LOC [${e.code}] ${e.message} ${e.details ?? ''}');
    } catch (e) {
      _addLog('ERRO LOC: $e');
    }
  }

  Future<void> _onComputeDistance() async {
    if (_curLat == null || _curLng == null) {
      _addLog('DIST → sem localização atual; use "Obter localização" antes.');
      return;
    }
    _addLog('computeDistanceMeters(from=($_curLat,$_curLng) to=($_destLat,$_destLng))…');
    try {
      final meters = await _channel.computeDistanceMeters(
        fromLat: _curLat!,
        fromLng: _curLng!,
        toLat: _destLat,
        toLng: _destLng,
      );
      _addLog('DIST → ${meters.toStringAsFixed(1)} m');
    } on PlatformException catch (e) {
      _addLog('ERRO DIST [${e.code}] ${e.message} ${e.details ?? ''}');
    } catch (e) {
      _addLog('ERRO DIST: $e');
    }
  }

  Future<void> _onCopyLogs() async {
    final ctx = context; // capture p/ evitar use_build_context_synchronously
    final text = _logs.join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!ctx.mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Logs copiados')));
    _addLog('Logs copiados para clipboard (${_logs.length} linhas).');
  }

  void _onClearLogs() {
    setState(() => _logs.clear());
    _addLog('— logs limpos —');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug – Geo Plugin')),
      body: Column(
        children: [
          // LOGS (topo)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.88),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _logs.isEmpty
                      ? const Center(
                          child: Text(
                            'Logs aparecerão aqui…',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          controller: _scroll,
                          itemCount: _logs.length,
                          itemBuilder: (_, i) => Text(
                            _logs[i],
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),

          // BOTÕES (base)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _onCheckPermissions,
                    icon: const Icon(Icons.privacy_tip_outlined),
                    label: const Text('Checar permissões'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _onRequestPermissions,
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Pedir permissões'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _onGetLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Obter localização'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _onComputeDistance,
                    icon: const Icon(Icons.straighten),
                    label: const Text('Calcular distância'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _onCopyLogs,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar logs'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _onClearLogs,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Limpar logs'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

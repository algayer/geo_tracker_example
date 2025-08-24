# geo\_tracker (plugin) + exemplo

Plugin **Android** para captura de localização com **FusedLocationProvider**, cálculo de **distância (Haversine)** e **tempo estimado (ETA)**.
O app de demonstração fica em **`example/`** e é usado para testar o plugin na prática (mapa com OSM + BLoC + botão “Recalcular”).

## O que tem

* **Permissões**: check/request (ACCESS\_FINE/COARSE).
* **Localização atual**:

  * tenta **cache recente** de `lastLocation` (≤ 5s),
  * se não houver, faz **single-shot** de alta precisão (com `timeoutMs`).
* **Distância** entre dois pontos (metros).
* **Distância + ETA** com perfis:

  * `walk`, `bike`, `drive_city` (default), `drive_fast`, `current` (usa speed do fix), `custom`.
  * também há versão **em lote** para vários destinos.
* **Exemplo (example/)**:

  * `flutter_map + OpenStreetMap` (sem subdomínios),
  * rota mock (reta),
  * BLoC (Cubit),
  * botão **Recalcular** força novo fix e atualiza distância/ETA.

## Estrutura

```
.
├─ lib/                  # API Dart (MethodChannel)
├─ android/              # Implementação nativa (Kotlin)
└─ example/              # App que testa o plugin (use este para rodar)
```

## Como usar no app

```dart
import 'package:geo_tracker/geo_tracker.dart';

final geo = GeoTracker();

// 1) Permissões
final p = await geo.checkPermissions();
if (!p.anyGranted) {
  await geo.requestPermissions();
}

// 2) Fix atual (timeout configurável)
final loc = await geo.getLastKnownOrCurrent(timeoutMs: 3000);

// 3) Distância simples (m)
final meters = await geo.computeDistanceMeters(
  fromLat: loc.lat,
  fromLng: loc.lng,
  toLat: -23.6,
  toLng: -46.7,
);

// 4) Distância + ETA (s) com perfil
final res = await geo.computeDistanceEta(
  fromLat: loc.lat,
  fromLng: loc.lng,
  toLat: -23.6,
  toLng: -46.7,
  profile: 'drive_city', // walk | bike | drive_city | drive_fast | current | custom
  // customSpeedMps: 12.5, // se profile == custom
  timeoutMs: 3000,
);

// res.meters, res.etaSeconds, res.speedMps, res.speedSource
```

**Em lote (vários destinos):**

```dart
final batch = await geo.computeDistancesEta(
  fromLat: loc.lat,
  fromLng: loc.lng,
  to: [
    DestPointInput(id: 'A', lat: -23.6, lng: -46.7),
    DestPointInput(id: 'B', lat: -23.7, lng: -46.6),
  ],
  profile: 'drive_city',
);
for (final row in batch.rows) {
  print('${row.id}: ${row.meters} m — ${row.etaSeconds} s');
}
```

## Como o plugin decide o fix

1. **Cache** (`lastLocation`) recente (espera até \~**500ms** e aceita fix com idade ≤ **5s**).
2. Se não houver, usa **getCurrentLocation(PRIORITY\_HIGH\_ACCURACY)** com `timeoutMs`.
3. Se localização do SO estiver OFF e não houver cache → erro `LOCATION_SETTINGS_DISABLED`.

## Dicionário rápido de erros (Flutter `PlatformException.code`)

* `NO_PERMISSION`: faltam permissões.
* `LOCATION_SETTINGS_DISABLED`: localização do dispositivo desativada/insuficiente.
* `TIMEOUT`: sem fix a tempo.
* `BAD_ARGS` / `INTERNAL_ERROR`: validações/erros internos.

## Notas do app de exemplo

* **Mapa**: `flutter_map` com tiles do OSM em `https://tile.openstreetmap.org/{z}/{x}/{y}.png`.
  (Sem subdomínios, prática recomendada atualmente.)
* **Formatação**:

  * Distância: `m` ou `km` com casas decimais dinâmicas.
  * ETA: `Hh Mm`, `Mm Ss` ou `Ss`.
* **Recalcular**:

  * Força novo fix,
  * Regera rota mock,
  * Recalcula distância + ETA (perfil **drive\_city**).

## Limitações

* Suporte **apenas Android** (sem iOS/web).
* Sem tracking contínuo/background (apenas leitura pontual).
* Rota é **mock** (reta). Integrações reais (OSRM/Valhalla/Directions) podem substituir facilmente.
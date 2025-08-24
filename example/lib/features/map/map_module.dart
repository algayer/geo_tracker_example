import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:geo_tracker_example/features/map/presentation/pages/plugin_debug_page.dart';

import '../../core/channels/geo_tracker_channel.dart';
import 'data/datasources/geo_tracker_datasource.dart';
import 'data/datasources/route_service.dart';
import 'data/repositories/geo_repository_impl.dart';
import 'domain/repositories/geo_repository.dart';
import 'domain/usecases/get_current_location_usecase.dart';
import 'domain/usecases/get_route_usecase.dart';
import 'domain/usecases/compute_distance_eta_usecase.dart'; // ⬅️ trocado
import 'presentation/cubit/map_cubit.dart';
import 'presentation/pages/map_page.dart';

class MapModule extends Module {
  @override
  void binds(i) {
    // Channel
    i.addLazySingleton<GeoTrackerChannel>(GeoTrackerChannel.new);

    // DataSource & Services
    i.addLazySingleton<GeoTrackerDataSource>(() => GeoTrackerDataSource(i()));
    i.addLazySingleton<RouteService>(FakeRouteService.new);

    // Repo
    i.addLazySingleton<GeoRepository>(() => GeoRepositoryImpl(ds: i(), routeService: i()));

    // Usecases
    i.addLazySingleton<GetCurrentLocationUseCase>(() => GetCurrentLocationUseCase(i()));
    i.addLazySingleton<GetRouteUseCase>(() => GetRouteUseCase(i()));
    i.addLazySingleton<ComputeDistanceEtaUseCase>(() => ComputeDistanceEtaUseCase(i())); // ⬅️ novo

    // Cubit
    i.add<MapCubit>(() => MapCubit(
          getCurrentLocation: i(),
          getRoute: i(),
          computeDistanceEta: i(),
        ));
  }

  @override
  void routes(r) {
    r.child(
      '/',
      child: (context) => BlocProvider.value(
        value: Modular.get<MapCubit>(),
        child: const MapPage(),
      ),
    );

    // r.child(
    //   '/debug',
    //   child: (context) => const PluginDebugSimplePage(),
    // );
  }
}

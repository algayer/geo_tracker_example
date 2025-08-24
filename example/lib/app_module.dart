import 'package:flutter_modular/flutter_modular.dart';
import 'features/map/map_module.dart';

class AppModule extends Module {
  @override
  List<Module> get imports => [];

  @override
  void routes(r) {
    r.module('/', module: MapModule());
  }
}

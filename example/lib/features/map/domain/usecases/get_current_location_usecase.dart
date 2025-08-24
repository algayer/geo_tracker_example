import '../entities/location_sample_entity.dart';
import '../repositories/geo_repository.dart';

class GetCurrentLocationUseCase {
  final GeoRepository repo;
  GetCurrentLocationUseCase(this.repo);

  Future<LocationSampleEntity> call({int timeoutMs = 3000}) async {
    await repo.ensurePermission();
    return repo.getCurrentLocation(timeoutMs: timeoutMs);
  }
}

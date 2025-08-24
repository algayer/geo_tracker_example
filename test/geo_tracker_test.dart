import 'package:flutter_test/flutter_test.dart';
import 'package:geo_tracker/geo_tracker.dart';
import 'package:geo_tracker/geo_tracker_platform_interface.dart';
import 'package:geo_tracker/geo_tracker_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGeoTrackerPlatform
    with MockPlatformInterfaceMixin
    implements GeoTrackerPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final GeoTrackerPlatform initialPlatform = GeoTrackerPlatform.instance;

  test('$MethodChannelGeoTracker is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelGeoTracker>());
  });

  test('getPlatformVersion', () async {
    GeoTracker geoTrackerPlugin = GeoTracker();
    MockGeoTrackerPlatform fakePlatform = MockGeoTrackerPlatform();
    GeoTrackerPlatform.instance = fakePlatform;

    expect(await geoTrackerPlugin.getPlatformVersion(), '42');
  });
}

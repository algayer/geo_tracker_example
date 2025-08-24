import 'package:equatable/equatable.dart';

class LocationSampleEntity extends Equatable {
  final double lat;
  final double lng;
  final double? accuracy;        // metros
  final int? timestampMillis;    // epoch ms
  final double? speedMps;        // m/s
  final double? bearing;         // 0–360°

  const LocationSampleEntity({
    required this.lat,
    required this.lng,
    this.accuracy,
    this.timestampMillis,
    this.speedMps,
    this.bearing,
  });

  // Conveniências
  double? get speedKmh => (speedMps == null) ? null : speedMps! * 3.6;
  DateTime? get timestamp => (timestampMillis == null) ? null : DateTime.fromMillisecondsSinceEpoch(timestampMillis!);

  LocationSampleEntity copyWith({
    double? lat,
    double? lng,
    double? accuracy,
    int? timestampMillis,
    double? speedMps,
    double? bearing,
  }) {
    return LocationSampleEntity(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      accuracy: accuracy ?? this.accuracy,
      timestampMillis: timestampMillis ?? this.timestampMillis,
      speedMps: speedMps ?? this.speedMps,
      bearing: bearing ?? this.bearing,
    );
  }

  Map<String, dynamic> toMap() => {
        'lat': lat,
        'lng': lng,
        'accuracy': accuracy,
        'ts': timestampMillis,
        'speed': speedMps,
        'bearing': bearing,
      };

  factory LocationSampleEntity.fromMap(Map<String, dynamic> m) => LocationSampleEntity(
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
        accuracy: (m['accuracy'] as num?)?.toDouble(),
        timestampMillis: (m['ts'] as num?)?.toInt(),
        speedMps: (m['speed'] as num?)?.toDouble(),
        bearing: (m['bearing'] as num?)?.toDouble(),
      );

  @override
  List<Object?> get props => [lat, lng, accuracy, timestampMillis, speedMps, bearing];
}

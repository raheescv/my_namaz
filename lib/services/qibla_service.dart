import 'dart:math' as math;

import '../utils/constants.dart';

class QiblaService {
  QiblaService._();

  /// Returns initial bearing in degrees (0=N, 90=E) from (lat,lon) to the Kaaba.
  static double bearingFromTo(double lat, double lon) {
    final phi1 = _rad(lat);
    final phi2 = _rad(K.kaabaLat);
    final dl = _rad(K.kaabaLon - lon);
    final y = math.sin(dl) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(dl);
    final theta = math.atan2(y, x);
    return (_deg(theta) + 360) % 360;
  }

  /// Great-circle distance in km.
  static double distanceKm(double lat, double lon) {
    final phi1 = _rad(lat);
    final phi2 = _rad(K.kaabaLat);
    final dphi = _rad(K.kaabaLat - lat);
    final dl = _rad(K.kaabaLon - lon);
    final a = math.sin(dphi / 2) * math.sin(dphi / 2) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(dl / 2) *
            math.sin(dl / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return K.earthRadiusKm * c;
  }

  static double _rad(double d) => d * math.pi / 180;
  static double _deg(double r) => r * 180 / math.pi;
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../services/qibla_service.dart';
import '../widgets/compass_dial.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});
  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  StreamSubscription<CompassEvent>? _compassSub;
  double _heading = 0;
  double? _qibla;
  double? _distanceKm;
  Position? _position;
  String? _city;
  String? _error;
  bool _loading = true;
  bool _alignedHaptic = false;

  bool get _hasCompass =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final ok = await _ensureLocation();
      if (!ok) return;
      final pos = await Geolocator.getCurrentPosition();
      _position = pos;
      _qibla = QiblaService.bearingFromTo(pos.latitude, pos.longitude);
      _distanceKm = QiblaService.distanceKm(pos.latitude, pos.longitude);

      try {
        final placemarks =
            await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          _city = [p.locality, p.administrativeArea, p.country]
              .where((s) => s != null && s.isNotEmpty)
              .join(', ');
        }
      } catch (_) {}

      if (_hasCompass) {
        _compassSub = FlutterCompass.events?.listen((event) {
          if (event.heading == null) return;
          final h = (event.heading! + 360) % 360;
          if (_qibla != null) {
            final diff = (h - _qibla!).abs();
            final aligned = diff < 5 || diff > 355;
            if (aligned && !_alignedHaptic) {
              HapticFeedback.mediumImpact();
              _alignedHaptic = true;
            } else if (!aligned && _alignedHaptic) {
              _alignedHaptic = false;
            }
          }
          if (mounted) setState(() => _heading = h);
        });
      }
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<bool> _ensureLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      _error = 'Location services are disabled. Enable them in settings.';
      setState(() => _loading = false);
      return false;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      _error = 'Location permission denied. Open settings to grant access.';
      setState(() => _loading = false);
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Qibla')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView(theme)
              : _content(theme),
    );
  }

  Widget _errorView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_outlined,
                size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                await Geolocator.openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _init();
              },
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(ThemeData theme) {
    final aligned = _hasCompass &&
        _qibla != null &&
        ((_heading - _qibla!).abs() < 5 ||
            (_heading - _qibla!).abs() > 355);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(height: 8),
            if (!_hasCompass)
              _platformNotice(theme)
            else if (aligned)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        color: theme.colorScheme.primary, size: 18),
                    const SizedBox(width: 6),
                    Text('You are facing the Qibla',
                        style: TextStyle(color: theme.colorScheme.primary)),
                  ],
                ),
              )
            else
              const SizedBox(height: 32),
            CompassDial(
              heading: _hasCompass ? _heading : 0,
              qiblaBearing: _qibla ?? 0,
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_hasCompass) ...[
                      _row(theme, 'Current heading',
                          '${_heading.toStringAsFixed(0)}°'),
                      const Divider(height: 16),
                    ],
                    _row(theme, 'Qibla direction',
                        '${(_qibla ?? 0).toStringAsFixed(0)}° from North'),
                    const Divider(height: 16),
                    _row(theme, 'Distance to Mecca',
                        '${(_distanceKm ?? 0).toStringAsFixed(0)} km'),
                    const Divider(height: 16),
                    _row(theme, 'Your location',
                        _city ??
                            '${_position?.latitude.toStringAsFixed(2)}, ${_position?.longitude.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _platformNotice(ThemeData theme) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline,
                size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Live compass needs a phone. Showing static bearing.',
                style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );

  Widget _row(ThemeData theme, String label, String value) => Row(
        children: [
          Expanded(
              child: Text(label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant))),
          Text(value,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      );
}

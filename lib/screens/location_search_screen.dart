import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';

import '../providers/prayer_times_provider.dart';
import '../theme/colors.dart';

class _Result {
  final String label;
  final double latitude;
  final double longitude;
  const _Result({
    required this.label,
    required this.latitude,
    required this.longitude,
  });
}

class LocationSearchScreen extends ConsumerStatefulWidget {
  const LocationSearchScreen({super.key});
  @override
  ConsumerState<LocationSearchScreen> createState() =>
      _LocationSearchScreenState();
}

class _LocationSearchScreenState
    extends ConsumerState<LocationSearchScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<_Result> _results = [];
  bool _searching = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();
    if (q.length < 2) {
      setState(() {
        _results = [];
        _error = null;
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q));
  }

  Future<void> _search(String query) async {
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final locs = await locationFromAddress(query);
      // Reverse-geocode each candidate so we can show a friendly label.
      final results = <_Result>[];
      for (final l in locs.take(8)) {
        String label = query;
        try {
          final marks =
              await placemarkFromCoordinates(l.latitude, l.longitude);
          if (marks.isNotEmpty) {
            final p = marks.first;
            label = [p.locality, p.administrativeArea, p.country]
                .where((s) => s != null && s.isNotEmpty)
                .join(', ');
            if (label.isEmpty) label = query;
          }
        } catch (_) {}
        results.add(_Result(
            label: label, latitude: l.latitude, longitude: l.longitude));
      }
      if (mounted) {
        setState(() {
          _results = results;
          _searching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searching = false;
          _error = 'No matches';
          _results = [];
        });
      }
    }
  }

  Future<void> _pick(_Result r) async {
    await ref.read(locationProvider.notifier).setManualLocation(
          latitude: r.latitude,
          longitude: r.longitude,
          city: r.label,
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Choose city')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search for a city…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _ctrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _ctrl.clear();
                          _onChanged('');
                        },
                      ),
              ),
              onChanged: (v) {
                _onChanged(v);
                setState(() {}); // refresh the clear button
              },
            ),
          ),
          Expanded(child: _body(theme)),
        ],
      ),
    );
  }

  Widget _body(ThemeData theme) {
    if (_searching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_results.isEmpty && _ctrl.text.trim().length >= 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(_error ?? 'No matches',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.public,
                  size: 56, color: AppColors.primaryGreen),
              const SizedBox(height: 12),
              Text('Type a city name to search',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(
                  'Example: "Malappuram" or "Mecca"',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _results.length,
      separatorBuilder: (_, __) => Divider(
          height: 1,
          color: theme.colorScheme.outlineVariant
              .withValues(alpha: 0.4)),
      itemBuilder: (_, i) {
        final r = _results[i];
        return ListTile(
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on_outlined,
                color: AppColors.primaryGreen, size: 20),
          ),
          title: Text(r.label,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${r.latitude.toStringAsFixed(2)}°, ${r.longitude.toStringAsFixed(2)}°',
            style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _pick(r),
        );
      },
    );
  }
}

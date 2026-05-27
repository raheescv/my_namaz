import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/prayer_dao.dart';
import 'services/data_wipe.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('FLUTTER ERROR: ${details.exception}\n${details.stack}');
      };

      runApp(const ProviderScope(child: MyNamazApp()));

      // Seed sample data ONLY if the user has never explicitly wiped.
      // ignore: unawaited_futures
      () async {
        try {
          if (await DataWipe.wasWiped()) return;
          await PrayerDao().seedIfEmpty();
        } catch (e, st) {
          debugPrint('Seed failed: $e\n$st');
        }
      }();
    },
    (error, stack) {
      debugPrint('UNCAUGHT: $error\n$stack');
    },
  );
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('FLUTTER ERROR: ${details.exception}\n${details.stack}');
      };

      runApp(const ProviderScope(child: MyNamazApp()));
    },
    (error, stack) {
      debugPrint('UNCAUGHT: $error\n$stack');
    },
  );
}

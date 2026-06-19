import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';

class AppErrorHandler {
  static Future<void> initialize() async {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      log('Flutter Error: ${details.exceptionAsString()}',
          error: details.exception, stackTrace: details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      log('Platform Error: $error', error: error, stackTrace: stack);
      return true;
    };
    runZonedGuarded(() {}, (error, stack) {
      log('Zone Error: $error', error: error, stackTrace: stack);
    });
  }
}

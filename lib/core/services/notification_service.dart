import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Wrapper minimalista sobre la Notifications API del navegador.
/// En plataformas no-web hace no-op.
class WebNotificationService {
  static bool get isSupported {
    if (!kIsWeb) return false;
    try {
      return globalContext.has('Notification');
    } catch (_) {
      return false;
    }
  }

  static String get permission {
    if (!isSupported) return 'unsupported';
    try {
      return web.Notification.permission;
    } catch (_) {
      return 'unsupported';
    }
  }

  /// Pide permiso (debe llamarse en respuesta a un user gesture).
  /// Devuelve true si queda granted.
  static Future<bool> requestPermission() async {
    if (!isSupported) return false;
    try {
      final current = permission;
      if (current == 'granted') return true;
      if (current == 'denied') return false;
      final result =
          await web.Notification.requestPermission().toDart;
      return result.toDart == 'granted';
    } catch (_) {
      return false;
    }
  }

  /// Muestra una notificación si tenemos permiso y el documento NO
  /// está visible (para no molestar cuando el usuario ya ve la app).
  static void show(String title, {String? body}) {
    if (!isSupported) return;
    try {
      if (permission != 'granted') return;
      if (web.document.visibilityState == 'visible') return;
      web.Notification(
        title,
        web.NotificationOptions(body: body ?? ''),
      );
    } catch (_) {
      // ignorar errores
    }
  }
}

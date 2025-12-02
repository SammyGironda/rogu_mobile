import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AppConfig {
  // Base URL para las llamadas HTTP (ajusta según entorno)
  static String apiBaseUrl = 'http://localhost:3000/api';

  // Inicializador: detecta plataforma para usar el host correcto en dev.
  static Future<void> init() async {
    // En Android emulator, "localhost" apunta al dispositivo. Se usa 10.0.2.2
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid) {
          apiBaseUrl = 'http://10.0.2.2:3000/api';
        } else if (Platform.isIOS) {
          // iOS simulator puede usar localhost
          apiBaseUrl = 'http://localhost:3000/api';
        } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          apiBaseUrl = 'http://localhost:3000/api';
        }
      } catch (_) {
        // Si Platform no está disponible (alguna plataforma no soportada), mantener por defecto
      }
    } else {
      // En Web, normalmente se consume por CORS desde la misma red.
      // Mantener valor por defecto a menos que se configure reverse-proxy.
      apiBaseUrl = apiBaseUrl; // noop
    }
  }
}

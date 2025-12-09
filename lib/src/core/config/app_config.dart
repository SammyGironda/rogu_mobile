import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AppConfig {
  // Permite override en build: flutter run --dart-define=API_BASE_URL=http://IP:3000/api
  static const String _envBase =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  // Base URL por defecto
  static String apiBaseUrl = 'http://localhost:3000/api';

  // Inicializador: detecta plataforma o usa override por dart-define.
  static Future<void> init() async {
    if (_envBase.isNotEmpty) {
      apiBaseUrl = _envBase;
      return;
    }

    // En Android emulator, "localhost" apunta al dispositivo. Se usa 10.0.2.2
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid) {
          apiBaseUrl = 'http://10.0.2.2:3000/api';
        } else if (Platform.isIOS) {
          apiBaseUrl = 'http://localhost:3000/api';
        } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          apiBaseUrl = 'http://localhost:3000/api';
        }
      } catch (_) {
        // Si Platform no está disponible, mantener por defecto
      }
    }
  }
}

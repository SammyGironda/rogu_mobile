class AppConfig {
  // Base URL para las llamadas HTTP (ajusta según entorno)
  static String apiBaseUrl = 'http://localhost:3000/api';

  // Inicializador mínimo; aquí podrías extender para leer .env o similar.
  static Future<void> init() async {
    // TODO: cargar configuración dinámica si se requiere.
    return;
  }
}

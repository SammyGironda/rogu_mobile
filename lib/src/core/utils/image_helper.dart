import '../config/app_config.dart';

/// Normaliza rutas de imágenes para que funcionen con backend local/S3.
/// - Si ya es URL absoluta, se devuelve tal cual.
/// - Si es relativa y tiene /api, se elimina ese prefijo.
/// - Si empieza con /uploads o /avatars, se antepone el server URL (sin /api).
/// - Caso contrario, se concatena al server URL.
String resolveImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;

  // base sin /api ni barra final
  final base = AppConfig.apiBaseUrl
      .replaceAll(RegExp(r'/api/?$'), '')
      .replaceAll(RegExp(r'/$'), '');

  var normalized = path.startsWith('/') ? path : '/$path';
  if (normalized.startsWith('/api/')) {
    normalized = normalized.replaceFirst('/api', '');
  }
  if (normalized.startsWith('/avatars/')) {
    normalized = '/uploads$normalized';
  }

  return '$base$normalized';
}

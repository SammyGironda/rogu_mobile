import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../utils/storage_helper.dart';

/// Cliente HTTP base con interceptores, manejo de token y headers comunes
class ApiClient {
  final String baseUrl;
  final http.Client _httpClient;

  ApiClient({String? baseUrl, http.Client? httpClient})
    : baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
      _httpClient = httpClient ?? http.Client();

  /// Headers base con autenticación si existe token
  Future<Map<String, String>> _getHeaders({
    Map<String, String>? additionalHeaders,
    bool skipAuth = false,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Agregar token si existe y no se desea omitir
    if (!skipAuth) {
      final token = await StorageHelper.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    // Merge con headers adicionales
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// GET request
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    bool skipAuth = false,
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    final requestHeaders = await _getHeaders(
      additionalHeaders: headers,
      skipAuth: skipAuth,
    );

    return _httpClient.get(uri, headers: requestHeaders);
  }

  /// POST request
  Future<http.Response> post(
    String endpoint, {
    Object? body,
    Map<String, String>? headers,
    bool skipAuth = false,
  }) async {
    final uri = _buildUri(endpoint);
    final requestHeaders = await _getHeaders(
      additionalHeaders: headers,
      skipAuth: skipAuth,
    );

    return _httpClient.post(
      uri,
      headers: requestHeaders,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// PUT request
  Future<http.Response> put(
    String endpoint, {
    Object? body,
    Map<String, String>? headers,
    bool skipAuth = false,
  }) async {
    final uri = _buildUri(endpoint);
    final requestHeaders = await _getHeaders(
      additionalHeaders: headers,
      skipAuth: skipAuth,
    );

    return _httpClient.put(
      uri,
      headers: requestHeaders,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// PATCH request
  Future<http.Response> patch(
    String endpoint, {
    Object? body,
    Map<String, String>? headers,
    bool skipAuth = false,
  }) async {
    final uri = _buildUri(endpoint);
    final requestHeaders = await _getHeaders(
      additionalHeaders: headers,
      skipAuth: skipAuth,
    );

    return _httpClient.patch(
      uri,
      headers: requestHeaders,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// DELETE request
  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
    bool skipAuth = false,
  }) async {
    final uri = _buildUri(endpoint);
    final requestHeaders = await _getHeaders(
      additionalHeaders: headers,
      skipAuth: skipAuth,
    );

    return _httpClient.delete(uri, headers: requestHeaders);
  }

  /// Construye URI con query params
  Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final url = '$baseUrl$path';

    if (queryParams != null && queryParams.isNotEmpty) {
      return Uri.parse(url).replace(queryParameters: queryParams);
    }

    return Uri.parse(url);
  }

  /// Cierra el cliente HTTP
  void close() {
    _httpClient.close();
  }
}

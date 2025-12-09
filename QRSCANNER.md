# 📱 Guía de Implementación: Sistema de Escaneo QR

Esta guía te ayudará a replicar la funcionalidad de escaneo QR en otro proyecto Flutter, manteniendo la misma lógica y base de datos.

---

## 📋 Tabla de Contenidos
1. [Dependencias necesarias](#dependencias-necesarias)
2. [Estructura de archivos](#estructura-de-archivos)
3. [Modelos de datos](#modelos-de-datos)
4. [Servicios API](#servicios-api)
5. [Pantalla de escaneo](#pantalla-de-escaneo)
6. [Integración con navegación](#integración-con-navegación)
7. [Flujo completo](#flujo-completo)

---

## 1️⃣ Dependencias Necesarias

### `pubspec.yaml`
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Para escaneo de QR
  mobile_scanner: ^4.0.0
  
  # Para peticiones HTTP
  http: ^1.1.0
  
  # Para manejo de estado (opcional, puedes usar Provider u otro)
  flutter_riverpod: ^2.4.0
```

**Instalar:**
```bash
flutter pub get
```

---

## 2️⃣ Estructura de Archivos

Crea esta estructura en tu proyecto:

```
lib/
├── models/
│   └── reserva.dart              # Modelos de Reserva, Cliente, ScanResult
├── services/
│   └── qr_api_service.dart       # Servicio para APIs de QR
├── apis/
│   └── qr/
│       └── qr_api.dart           # API endpoints (alternativa moderna)
├── repositories/
│   └── qr_repository.dart        # Capa de abstracción de datos
└── screens/
    └── qr_scanner_screen.dart    # Pantalla principal de escaneo
```

---

## 3️⃣ Modelos de Datos

### `lib/models/reserva.dart`

```dart
// Modelo Cliente (persona que escanea)
class Cliente {
  final String id;              // ⭐ ID único del cliente
  final String nombre;
  final String documento;       // ⭐ Documento de identidad
  final String qrCode;
  final bool escaneado;
  final String? horaEscaneo;

  Cliente({
    required this.id,
    required this.nombre,
    required this.documento,
    required this.qrCode,
    this.escaneado = false,
    this.horaEscaneo,
  });

  Cliente copyWith({
    String? id,
    String? nombre,
    String? documento,
    String? qrCode,
    bool? escaneado,
    String? horaEscaneo,
  }) {
    return Cliente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      documento: documento ?? this.documento,
      qrCode: qrCode ?? this.qrCode,
      escaneado: escaneado ?? this.escaneado,
      horaEscaneo: horaEscaneo ?? this.horaEscaneo,
    );
  }

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      documento: json['documento'] ?? '',
      qrCode: json['qrCode'] ?? '',
      escaneado: json['escaneado'] ?? false,
      horaEscaneo: json['horaEscaneo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'documento': documento,
      'qrCode': qrCode,
      'escaneado': escaneado,
      'horaEscaneo': horaEscaneo,
    };
  }
}

// Modelo Reserva
class Reserva {
  final String id;
  final String nombreReserva;      // ⭐ Nombre descriptivo de la reserva
  final String fecha;               // Formato ISO: yyyy-MM-dd
  final String hora;                // Formato: HH:mm
  final String cancha;              // ⭐ Nombre de la cancha
  final int? sedeId;                // ⭐ ID de la sede (opcional)
  final List<Cliente> clientes;
  final String estado;              // ⭐ 'pendiente' | 'en_proceso' | 'completada'
  final int totalPersonas;

  const Reserva({
    required this.id,
    required this.nombreReserva,
    required this.fecha,
    required this.hora,
    required this.cancha,
    this.sedeId,
    required this.clientes,
    required this.estado,
    required this.totalPersonas,
  });

  Reserva copyWith({
    String? id,
    String? nombreReserva,
    String? fecha,
    String? hora,
    String? cancha,
    int? sedeId,
    List<Cliente>? clientes,
    String? estado,
    int? totalPersonas,
  }) {
    return Reserva(
      id: id ?? this.id,
      nombreReserva: nombreReserva ?? this.nombreReserva,
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      cancha: cancha ?? this.cancha,
      sedeId: sedeId ?? this.sedeId,
      clientes: clientes ?? this.clientes,
      estado: estado ?? this.estado,
      totalPersonas: totalPersonas ?? this.totalPersonas,
    );
  }

  factory Reserva.fromJson(Map<String, dynamic> json) {
    return Reserva(
      id: json['id'].toString(),
      nombreReserva: json['nombreReserva'] ?? json['nombre'] ?? '',
      fecha: json['fecha'] ?? '',
      hora: json['hora'] ?? '',
      cancha: json['cancha'] ?? json['nombreCancha'] ?? '',
      sedeId: json['sedeId'] as int?,
      clientes: (json['clientes'] as List?)
              ?.map((c) => Cliente.fromJson(c))
              .toList() ??
          [],
      estado: json['estado'] ?? 'pendiente',
      totalPersonas: json['totalPersonas'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombreReserva': nombreReserva,
      'fecha': fecha,
      'hora': hora,
      'cancha': cancha,
      'sedeId': sedeId,
      'clientes': clientes.map((c) => c.toJson()).toList(),
      'estado': estado,
      'totalPersonas': totalPersonas,
    };
  }
}

// Enum para tipo de escaneo
enum ScanType { success, warning, error }

// Resultado del escaneo
class ScanResult {
  final bool success;
  final String message;
  final ScanType type;
  final Cliente? cliente;

  ScanResult({
    required this.success,
    required this.message,
    required this.type,
    this.cliente,
  });
}
```

---

## 4️⃣ Servicios API

### `lib/services/qr_api_service.dart`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class QrApiService {
  final String baseUrl;
  final String? authToken;

  QrApiService({required this.baseUrl, this.authToken});

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  // 1. Obtener pase de acceso por reserva
  Future<Map<String, dynamic>> getPasePorReserva(int idReserva) async {
    final uri = Uri.parse('$baseUrl/pases-acceso/reserva/$idReserva');
    final res = await http.get(uri, headers: _headers());
    
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Error ${res.statusCode} al obtener pase');
  }

  // 2. Asegurar que el operador trabaja en la sede
  Future<void> ensureTrabaja(int idPersonaOpe, int idSede) async {
    // Verificar si ya existe
    final uriGet = Uri.parse('$baseUrl/trabaja/$idPersonaOpe/$idSede');
    final resGet = await http.get(uriGet, headers: _headers());
    
    if (resGet.statusCode == 200) {
      return; // Ya existe la relación
    }
    
    // Crear nueva relación
    final uriPost = Uri.parse('$baseUrl/trabaja');
    final body = jsonEncode({
      'idPersonaOpe': idPersonaOpe,
      'idSede': idSede,
    });
    final resPost = await http.post(uriPost, headers: _headers(), body: body);
    
    if (resPost.statusCode >= 200 && resPost.statusCode < 300) {
      return;
    }
    throw Exception('Error ${resPost.statusCode} al crear trabaja');
  }

  // 3. Crear registro de control
  Future<void> crearControla({
    required int idPersonaOpe,
    required int idReserva,
    required int idPaseAcceso,
    required String accion,
    required String resultado,
  }) async {
    final uri = Uri.parse('$baseUrl/controla');
    final body = jsonEncode({
      'idPersonaOpe': idPersonaOpe,
      'idReserva': idReserva,
      'idPaseAcceso': idPaseAcceso,
      'accion': accion,
      'resultado': resultado,
    });
    
    final res = await http.post(uri, headers: _headers(), body: body);
    
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw Exception('Error ${res.statusCode} al crear controla');
  }

  // 4. Finalizar pase de acceso (actualizar usos)
  Future<void> finalizarPaseAccesoUsos({
    required int idPaseAcceso,
    required int vecesUsado,
    required String estado,
  }) async {
    final uri = Uri.parse('$baseUrl/pases-acceso/$idPaseAcceso');
    final body = jsonEncode({
      'vecesUsado': vecesUsado,
      'estado': estado,
    });
    
    final res = await http.patch(uri, headers: _headers(), body: body);
    
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw Exception('Error ${res.statusCode} al actualizar pase');
  }
}
```

---

## 5️⃣ Pantalla de Escaneo

### `lib/screens/qr_scanner_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/reserva.dart';
import '../services/qr_api_service.dart';

class QRScannerScreen extends StatefulWidget {
  static const String routeName = '/qr-scanner';
  
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  Reserva? currentReserva;
  int? idPaseAcceso;
  int? idPersonaOpe;      // ID del operador/controlador
  int? idSede;            // ID de la sede
  bool scanning = true;
  
  final TextEditingController _qrController = TextEditingController();
  final List<ScanResult> scanHistory = [];
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Recibir argumentos de navegación
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    if (rawArgs is Map) {
      final args = Map<String, dynamic>.from(rawArgs);
      currentReserva ??= args['reserva'] as Reserva?;
      idPaseAcceso ??= args['idPaseAcceso'] as int?;
      idPersonaOpe ??= args['idPersonaOpe'] as int?;
      idSede ??= args['idSede'] as int?;
    }
  }

  // Procesar el escaneo de un código QR
  void _processScan(String qrCode) {
    if (currentReserva == null || qrCode.trim().isEmpty) return;

    // Buscar el cliente por su código QR
    final idx = currentReserva!.clientes.indexWhere((c) => c.qrCode == qrCode);
    
    ScanResult result;
    
    if (idx == -1) {
      // QR no pertenece a esta reserva
      result = ScanResult(
        success: false,
        message: 'QR no pertenece a esta reserva',
        type: ScanType.error,
      );
      _showSnackBar('QR no pertenece a esta reserva');
    } else {
      final cliente = currentReserva!.clientes[idx];
      
      if (cliente.escaneado) {
        // QR ya fue escaneado previamente
        result = ScanResult(
          success: false,
          message: 'QR ya registrado',
          type: ScanType.warning,
          cliente: cliente,
        );
        _showSnackBar('QR ya registrado');
      } else {
        // Registrar hora de escaneo
        final now = DateTime.now();
        final hora = '${now.hour.toString().padLeft(2, '0')}:'
                     '${now.minute.toString().padLeft(2, '0')}:'
                     '${now.second.toString().padLeft(2, '0')}';
        
        // Actualizar cliente como escaneado
        final updated = List<Cliente>.from(currentReserva!.clientes);
        updated[idx] = cliente.copyWith(escaneado: true, horaEscaneo: hora);
        
        setState(() {
          currentReserva = currentReserva!.copyWith(clientes: updated);
        });
        
        result = ScanResult(
          success: true,
          message: 'Ingreso autorizado',
          type: ScanType.success,
          cliente: updated[idx],
        );
        _showSnackBar('Ingreso autorizado');
      }
    }
    
    // Agregar al historial
    setState(() {
      scanHistory.insert(0, result);
      _qrController.clear();
    });
  }

  // Finalizar el proceso de escaneo
  Future<void> _finalizarIngreso() async {
    final total = currentReserva?.totalPersonas ?? 0;
    final scanned = currentReserva?.clientes.where((c) => c.escaneado).length ?? 0;
    
    if (total == 0 || scanned < total) {
      _showSnackBar('Aún faltan personas por escanear');
      return;
    }
    
    try {
      final api = QrApiService(
        baseUrl: 'http://TU_SERVIDOR:3000/api',
        // authToken: 'tu_token_aqui', // Si usas autenticación
      );
      
      // 1. Asegurar relación trabaja (operador-sede)
      if (idPersonaOpe != null && idSede != null) {
        await api.ensureTrabaja(idPersonaOpe!, idSede!);
      }
      
      // 2. Actualizar pase de acceso
      if (idPaseAcceso != null) {
        await api.finalizarPaseAccesoUsos(
          idPaseAcceso: idPaseAcceso!,
          vecesUsado: total,
          estado: 'USADO',
        );
      }
      
      // 3. Crear registro de control (auditoría)
      if (idPersonaOpe != null && idPaseAcceso != null && currentReserva != null) {
        await api.crearControla(
          idPersonaOpe: idPersonaOpe!,
          idReserva: int.parse(currentReserva!.id),
          idPaseAcceso: idPaseAcceso!,
          accion: 'entrada',
          resultado: 'COMPLETADO_$total',
        );
      }
      
      _showSnackBar('Ingreso completado y registrado');
      if (mounted) Navigator.pop(context, currentReserva);
    } catch (e) {
      _showSnackBar('Error al finalizar: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = currentReserva?.totalPersonas ?? 0;
    final scanned = currentReserva?.clientes.where((c) => c.escaneado).length ?? 0;
    final pending = total - scanned;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escaneo de QR'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resumen de escaneos
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Personas pendientes'),
                          Text(
                            '$pending de $total',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Escaneados'),
                          Text(
                            '$scanned',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Barra de progreso
              LinearProgressIndicator(
                value: total == 0 ? 0 : scanned / total,
                minHeight: 12,
              ),
              
              const SizedBox(height: 16),
              
              // Visor de cámara
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Visor de Cámara'),
                          Chip(
                            label: Text(scanning ? 'Activo' : 'Detenido'),
                            backgroundColor: scanning ? Colors.green : Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Escáner QR
                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: MobileScanner(
                          controller: MobileScannerController(
                            facing: CameraFacing.back,
                            torchEnabled: false,
                          ),
                          onDetect: (capture) {
                            if (!scanning) return;
                            
                            final barcodes = capture.barcodes;
                            if (barcodes.isEmpty) return;
                            
                            final raw = barcodes.first.rawValue ?? '';
                            if (raw.isEmpty) return;
                            
                            _processScan(raw);
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Input manual
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _qrController,
                              enabled: scanning,
                              decoration: const InputDecoration(
                                hintText: 'Ingresa el código QR manualmente...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: (!scanning || _qrController.text.trim().isEmpty)
                                ? null
                                : () => _processScan(_qrController.text),
                            child: const Text('Escanear'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Historial de escaneos
              if (scanHistory.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Historial de Escaneos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...scanHistory.map((r) {
                          Color color;
                          switch (r.type) {
                            case ScanType.success:
                              color = Colors.green.shade100;
                              break;
                            case ScanType.warning:
                              color = Colors.orange.shade100;
                              break;
                            case ScanType.error:
                              color = Colors.red.shade100;
                              break;
                          }
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    r.cliente != null
                                        ? '${r.cliente!.nombre} - ${r.message}'
                                        : r.message,
                                  ),
                                ),
                                if (r.cliente?.horaEscaneo != null)
                                  Text(r.cliente!.horaEscaneo!),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => scanning = !scanning),
                      child: Text(scanning ? 'Detener' : 'Reanudar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _finalizarIngreso,
                      child: const Text('Finalizar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 6️⃣ Integración con Navegación

### En tu `main.dart` o archivo de rutas:

```dart
import 'package:flutter/material.dart';
import 'screens/qr_scanner_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi App',
      routes: {
        QRScannerScreen.routeName: (context) => const QRScannerScreen(),
        // ... otras rutas
      },
    );
  }
}
```

### Navegar a la pantalla de escaneo:

```dart
// Desde cualquier parte de tu app
Navigator.pushNamed(
  context,
  QRScannerScreen.routeName,
  arguments: {
    'reserva': miReserva,           // Objeto Reserva
    'idPaseAcceso': 123,            // ID del pase de acceso
    'idPersonaOpe': 456,            // ID del operador
    'idSede': 789,                  // ID de la sede
  },
);
```

---

## 7️⃣ Flujo Completo

### Diagrama de flujo:

```
1. Usuario abre pantalla de escaneo
   ↓
2. Recibe reserva con lista de clientes y sus QR codes
   ↓
3. Escanea QR (con cámara o manualmente)
   ↓
4. Valida si el QR pertenece a la reserva
   ↓
5a. ❌ NO pertenece → Muestra error
5b. ✅ Pertenece pero ya escaneado → Muestra advertencia
5c. ✅ Pertenece y no escaneado → Marca como escaneado
   ↓
6. Registra hora de escaneo
   ↓
7. Actualiza contador (pendientes/escaneados)
   ↓
8. Agrega al historial de escaneos
   ↓
9. Usuario presiona "Finalizar" cuando todos están escaneados
   ↓
10. API Calls:
    a) ensureTrabaja() - Registra operador en sede
    b) finalizarPaseAccesoUsos() - Actualiza pase
    c) crearControla() - Registra auditoría
   ↓
11. Regresa a pantalla anterior con resultados
```

---

## 🔧 Endpoints de API Necesarios

Tu backend debe tener estos endpoints:

```
GET    /api/pases-acceso/reserva/:idReserva
GET    /api/trabaja/:idPersonaOpe/:idSede
POST   /api/trabaja
POST   /api/controla
PATCH  /api/pases-acceso/:idPaseAcceso
```

---

## 🎨 Personalización

### Cambiar colores:
```dart
// En tu tema
primaryColor: Colors.blue,
cardColor: Colors.grey[100],
```

### Cambiar URL del servidor:
```dart
final api = QrApiService(
  baseUrl: 'https://tu-servidor.com/api',
  authToken: 'tu_token',
);
```

### Agregar validaciones personalizadas:
```dart
void _processScan(String qrCode) {
## 📱 Permisos de Cámara

### Android (`android/app/src/main/AndroidManifest.xml`):

**IMPORTANTE:** Agregar el permiso **ANTES** del tag `<application>`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- ⭐ Camera permission for QR scanning -->
    <uses-permission android:name="android.permission.CAMERA" />
    
    <application
        android:label="tu_app"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <!-- ... resto de la configuración ... -->
    </application>
</manifest>
```

### iOS (`ios/Runner/Info.plist`):

Agregar dentro del tag `<dict>`:

```xml
<key>NSCameraUsageDescription</key>
<string>Necesitamos acceso a la cámara para escanear códigos QR</string>
```

**Ubicación completa en Info.plist:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- ... otras configuraciones ... -->
    
    <!-- ⭐ Camera permission -->
    <key>NSCameraUsageDescription</key>
    <string>Necesitamos acceso a la cámara para escanear códigos QR</string>
    
    <!-- ... resto de configuraciones ... -->
---

## 🎯 Ejemplo de Datos Mock (Para Testing)

Si necesitas datos de prueba sin backend:

```dart
// En tu pantalla o controlador
final reservaMock = Reserva(
  id: '1',
### Problema: Error al llamar API
**Solución:** Verificar que el `baseUrl` sea correcto y que el servidor esté corriendo.

### Problema: MobileScanner no funciona en emulador
**Solución:** 
- En Android Studio: Configurar cámara virtual en AVD Manager
- Usar dispositivo físico para mejor experiencia
- Usar modo manual (TextField) para testing en emulador

### Problema: Escaneos duplicados
**Solución:** Implementar control de tiempo entre escaneos (ver sección "Control de Versiones del Escáner")

### Problema: "Permission denied" en Android
**Solución:** 
1. Verificar que el permiso esté en AndroidManifest.xml
2. Reinstalar la app después de agregar permisos
3. Verificar permisos manualmente en: Configuración > Apps > Tu App > Permisos

### Problema: Hot reload no funciona con MobileScanner
**Solución:** Hacer hot restart completo (Shift + R en terminal de Flutter)
  hora: '18:00',
  cancha: 'Cancha Principal',
  sedeId: 1,
  estado: 'pendiente',
  totalPersonas: 3,
  clientes: [
    Cliente(
      id: '1',
      nombre: 'Juan Pérez',
      documento: '12345678',
      qrCode: 'QR001-JUAN',
      escaneado: false,
    ),
    Cliente(
      id: '2',
      nombre: 'María García',
      documento: '87654321',
      qrCode: 'QR002-MARIA',
## 📚 Recursos Adicionales

- [Documentación mobile_scanner](https://pub.dev/packages/mobile_scanner)
- [HTTP package](https://pub.dev/packages/http)
- [Flutter Navigation](https://docs.flutter.dev/cookbook/navigation)
- [Flutter Riverpod](https://riverpod.dev/) (si usas state management)

---

## 💡 Notas Importantes

### ⚠️ **Consideraciones de Seguridad**
- **NO** hardcodear tokens o credenciales en el código
- Usar variables de entorno para URLs de producción
- Validar todos los datos del backend antes de usarlos
- Implementar timeout en las peticiones HTTP

### 🎯 **Mejores Prácticas**
1. **Logging:** Implementar logs para debugging sin afectar producción
2. **Error Handling:** Manejo robusto de errores de red y permisos
3. **UX:** Mostrar loading states durante operaciones de red
4. **Offline Mode:** Considerar qué hacer si no hay conexión
5. **Testing:** Probar con datos mock antes de conectar al backend

### 🔐 **Gestión de Estados**
```dart
// Ejemplo con estado de carga
bool _isLoading = false;

Future<void> _finalizarIngreso() async {
  setState(() => _isLoading = true);
  
  try {
    // ... operaciones API ...
  } catch (e) {
    // ... manejo de errores ...
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

### 📊 **Métricas Útiles**
- Tiempo promedio de escaneo por persona
- Tasa de éxito vs errores
- Cantidad de escaneos duplicados detectados
- Tiempo total del proceso de ingreso

---

## 🎨 Personalización Avanzada

### Colores del Tema (ejemplo con tu proyecto actual):
```dart
// AppColors personalizados
class AppColors {
  static const primary500 = Color(0xFF1E40AF);
  static const primary700 = Color(0xFF1E3A8A);
  static const secondary = Color(0xFF10B981);
  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const card = Color(0xFF1F2937);
  static const muted = Color(0xFF6B7280);
}
```

### Animaciones para mejor UX:
```dart
// Animación de éxito al escanear
void _showSuccessAnimation() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 64),
          SizedBox(height: 16),
          Text('¡Escaneo exitoso!'),
        ],
      ),
    ),
  );
  
  Future.delayed(Duration(milliseconds: 800), () {
    Navigator.pop(context);
  });
}
```

---

**¡Listo!** Con esta guía completa puedes implementar el sistema de escaneo QR en cualquier proyecto Flutter manteniendo la misma lógica y base de datos. 🚀

**Versión:** 1.0  
**Última actualización:** Diciembre 2025  
**Autor:** Basado en ROGU Mobile Project
  ],
);

// Navegar con datos mock
Navigator.pushNamed(
  context,
  QRScannerScreen.routeName,
  arguments: {
    'reserva': reservaMock,
    'idPaseAcceso': 123,
    'idPersonaOpe': 1,
    'idSede': 1,
  },
);
```

---

## 🔄 Control de Versiones del Escáner

Para evitar escaneos duplicados cuando la cámara detecta el mismo QR múltiples veces:

```dart
class _QRScannerScreenState extends State<QRScannerScreen> {
  // ... otros campos ...
  
  String? _lastScannedCode;
  DateTime? _lastScanTime;
  
  void _processScan(String qrCode) {
    if (currentReserva == null || qrCode.trim().isEmpty) return;
    
    // ⭐ Evitar escaneos duplicados en menos de 2 segundos
    final now = DateTime.now();
    if (_lastScannedCode == qrCode && 
        _lastScanTime != null && 
        now.difference(_lastScanTime!).inSeconds < 2) {
      return; // Ignorar escaneo duplicado
    }
    
    _lastScannedCode = qrCode;
    _lastScanTime = now;
    
    // ... resto del código de procesamiento ...
  }
}
```

---

## 🐛 Troubleshooting
## ✅ Checklist de Implementación

- [ ] Instalar dependencias (`mobile_scanner`, `http`)
- [ ] Crear modelos (`Reserva`, `Cliente`, `ScanResult`)
- [ ] Crear servicio API (`QrApiService`)
- [ ] Crear pantalla de escaneo (`QRScannerScreen`)
- [ ] Configurar rutas en `main.dart`
- [ ] Configurar permisos de cámara (Android/iOS)
- [ ] Probar navegación con argumentos
- [ ] Probar escaneo con cámara
- [ ] Probar escaneo manual
- [ ] Probar finalización y llamadas API
- [ ] Manejar errores de red
- [ ] Agregar loading states

---

## 📱 Permisos de Cámara

### Android (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### iOS (`ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>Necesitamos acceso a la cámara para escanear códigos QR</string>
```

---

## 🐛 Troubleshooting

### Problema: La cámara no inicia
**Solución:** Verificar permisos y que `mobile_scanner` esté correctamente instalado.

### Problema: Los QR no se escanean
**Solución:** Asegurar que el QR code esté bien formado y visible.

### Problema: Error al llamar API
**Solución:** Verificar que el `baseUrl` sea correcto y que el servidor esté corriendo.

---

## 📚 Recursos Adicionales

- [Documentación mobile_scanner](https://pub.dev/packages/mobile_scanner)
- [HTTP package](https://pub.dev/packages/http)
- [Flutter Navigation](https://docs.flutter.dev/cookbook/navigation)

---

**¡Listo!** Con esta guía puedes implementar el sistema de escaneo QR en cualquier proyecto Flutter manteniendo la misma lógica y base de datos. 🚀

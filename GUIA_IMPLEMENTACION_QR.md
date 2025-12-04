# 📱 Sistema de Escaneo QR - ROGU Mobile

## ✅ Implementación Completada

Esta guía documenta el sistema de escaneo QR implementado en el proyecto ROGU Mobile, adaptado a la arquitectura existente.

---

## 📁 Estructura Implementada

```
lib/src/
├── data/
│   ├── models/
│   │   └── reserva.dart                    ✅ NUEVO - Modelos Reserva, Cliente, ScanResult
│   └── repositories/
│       └── qr_repository.dart              ✅ ACTUALIZADO - Métodos de escaneo
├── apis/
│   └── qr/
│       └── qr_api.dart                     ✅ ACTUALIZADO - Endpoints completos
└── presentation/
    └── screens/
        └── qr/
            └── qr_scanner_screen.dart      ✅ ACTUALIZADO - Pantalla completa
```

---

## 🎯 Archivos Modificados

### 1. `pubspec.yaml`
```yaml
dependencies:
  mobile_scanner: ^4.0.0  # ✅ Agregado para escaneo QR
```

### 2. `lib/src/data/models/reserva.dart` ✅ NUEVO
Modelos principales:
- **`Cliente`**: Representa a una persona que escanea su QR
- **`Reserva`**: Información completa de la reserva con lista de clientes
- **`ScanResult`**: Resultado del proceso de escaneo
- **`ScanType`**: Enum para tipos de escaneo (success, warning, error)

### 3. `lib/src/apis/qr/qr_api.dart` ✅ ACTUALIZADO
Nuevos métodos agregados:
- `ensureTrabaja()` - Registra operador en sede
- `crearControla()` - Crea registro de auditoría
- `finalizarPaseAccesoUsos()` - Actualiza estado del pase

### 4. `lib/src/data/repositories/qr_repository.dart` ✅ ACTUALIZADO
Métodos agregados para encapsular la lógica de negocio:
- `ensureTrabaja()`
- `crearControla()`
- `finalizarPaseAccesoUsos()`

### 5. `lib/src/presentation/screens/qr/qr_scanner_screen.dart` ✅ REEMPLAZADO
Implementación completa con:
- Escaneo con cámara usando `mobile_scanner`
- Entrada manual de códigos QR
- Control de escaneos duplicados
- Historial visual de escaneos
- Barra de progreso
- Validaciones en tiempo real

### 6. `android/app/src/main/AndroidManifest.xml` ✅ ACTUALIZADO
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### 7. `ios/Runner/Info.plist` ✅ ACTUALIZADO
```xml
<key>NSCameraUsageDescription</key>
<string>Necesitamos acceso a la cámara para escanear códigos QR de las reservas</string>
```

---

## 🚀 Cómo Usar

### Navegación a la Pantalla de Escaneo

Desde cualquier parte de tu app, navega con los argumentos necesarios:

```dart
Navigator.pushNamed(
  context,
  QRScannerScreen.routeName,
  arguments: {
    'reserva': miReserva,           // Objeto Reserva con clientes
    'idPaseAcceso': 123,            // ID del pase de acceso
    'idPersonaOpe': 456,            // ID del operador/controlador
    'idSede': 789,                  // ID de la sede
  },
);
```

### Estructura del Objeto Reserva

```dart
final reserva = Reserva(
  id: '1',
  nombreReserva: 'Reserva Fútbol 5',
  fecha: '2025-12-05',
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
      escaneado: false,
    ),
    // ... más clientes
  ],
);
```

---

## 🔄 Flujo de Escaneo

1. **Usuario abre pantalla de escaneo** → Recibe reserva y parámetros
2. **Escanea QR** (con cámara o manualmente)
3. **Validación**:
   - ❌ QR no pertenece → Error
   - ⚠️ QR ya escaneado → Advertencia
   - ✅ QR válido y no escaneado → Éxito
4. **Registra hora de escaneo** → Actualiza estado del cliente
5. **Muestra en historial** → Feedback visual
6. **Al completar todos** → Presiona "Finalizar"
7. **API Calls**:
   - `ensureTrabaja()` - Vincula operador con sede
   - `finalizarPaseAccesoUsos()` - Actualiza pase
   - `crearControla()` - Auditoría del proceso
8. **Regresa con resultados** → Reserva actualizada

---

## 🎨 Características Implementadas

### ✅ Escaneo de Cámara
- Usa `mobile_scanner` para lectura de códigos QR
- Botón pause/resume para control del escaneo
- Compatible con Android e iOS

### ✅ Entrada Manual
- Campo de texto para ingresar códigos manualmente
- Útil cuando la cámara no funciona o para testing

### ✅ Control de Duplicados
- Evita escaneos múltiples del mismo código en menos de 2 segundos
- Previene errores por detección repetida de la cámara

### ✅ Historial Visual
- Lista de todos los escaneos realizados
- Códigos de color:
  - 🟢 Verde: Escaneo exitoso
  - 🟠 Naranja: Advertencia (ya escaneado)
  - 🔴 Rojo: Error (QR inválido)

### ✅ Barra de Progreso
- Muestra visualmente cuántas personas faltan por escanear
- Actualización en tiempo real

### ✅ Validaciones
- Verifica que el QR pertenezca a la reserva
- Detecta QRs ya escaneados
- Impide finalizar si faltan personas

### ✅ Integración con Backend
- Registra operador en sede (tabla `trabaja`)
- Actualiza pase de acceso (tabla `pases_acceso`)
- Crea registro de control (tabla `controla`)

---

## 🔧 Endpoints de Backend Utilizados

```
GET    /api/pases-acceso/reserva/:idReserva
GET    /api/trabaja/:idPersonaOpe/:idSede
POST   /api/trabaja
POST   /api/controla
PATCH  /api/pases-acceso/:idPaseAcceso
```

Asegúrate de que tu backend en `espacios_deportivos` tenga estos endpoints implementados.

---

## 📱 Permisos Configurados

### Android
- Permiso `CAMERA` agregado en `AndroidManifest.xml`
- Se solicita automáticamente al usuario la primera vez

### iOS
- `NSCameraUsageDescription` configurado en `Info.plist`
- Descripción clara del uso de la cámara

---

## 🐛 Troubleshooting

### Problema: La cámara no inicia
**Solución:** 
1. Verifica permisos en configuración del dispositivo
2. Reinstala la app después de agregar permisos
3. Usa entrada manual como alternativa

### Problema: Escaneos duplicados
**Solución:** Ya implementado - Control de 2 segundos entre escaneos del mismo código

### Problema: Error al finalizar
**Solución:** 
1. Verifica conexión con el backend
2. Revisa que los endpoints estén disponibles
3. Confirma que los IDs (idPersonaOpe, idSede, idPaseAcceso) sean válidos

### Problema: Hot reload no funciona
**Solución:** Hacer hot restart completo (`Shift + R` en terminal)

---

## 🔐 Consideraciones de Seguridad

- ✅ Usa `ApiClient` con autenticación por token
- ✅ Validación de permisos antes de acceder
- ✅ Registro de auditoría en tabla `controla`
- ⚠️ NO exponer IDs sensibles en logs de producción

---

## 📊 Datos de Prueba (Testing)

Para probar sin backend completo, puedes crear datos mock:

```dart
final reservaMock = Reserva(
  id: '1',
  nombreReserva: 'Reserva Test',
  fecha: '2025-12-05',
  hora: '18:00',
  cancha: 'Cancha Test',
  sedeId: 1,
  estado: 'pendiente',
  totalPersonas: 2,
  clientes: [
    Cliente(
      id: '1',
      nombre: 'Test User 1',
      documento: '12345678',
      qrCode: 'TEST001',
      escaneado: false,
    ),
    Cliente(
      id: '2',
      nombre: 'Test User 2',
      documento: '87654321',
      qrCode: 'TEST002',
      escaneado: false,
    ),
  ],
);

// Navegar con datos mock
Navigator.pushNamed(
  context,
  QRScannerScreen.routeName,
  arguments: {
    'reserva': reservaMock,
    'idPaseAcceso': 1,
    'idPersonaOpe': 1,
    'idSede': 1,
  },
);
```

Puedes escribir estos códigos (`TEST001`, `TEST002`) manualmente en el campo de texto.

---

## 📝 Próximos Pasos

### Para Implementación Completa:

1. **Cargar reservas reales desde el backend**
   - Crear endpoint para obtener reservas del día
   - Filtrar por sede del controlador
   - Mostrar lista de reservas antes de escanear

2. **Notificaciones**
   - Sonido o vibración al escanear exitosamente
   - Alertas visuales más prominentes

3. **Estadísticas**
   - Dashboard de escaneos del día
   - Reportes de asistencia

4. **Modo Offline**
   - Guardar escaneos localmente
   - Sincronizar cuando haya conexión

---

## 🎓 Diferencias con la Guía Original

| Aspecto | Guía Original | Implementación ROGU |
|---------|---------------|---------------------|
| Ubicación modelos | `lib/models/` | `lib/src/data/models/` |
| Ubicación servicios | `lib/services/` | `lib/src/apis/qr/` |
| Ubicación repositorios | `lib/repositories/` | `lib/src/data/repositories/` |
| Ubicación screens | `lib/screens/` | `lib/src/presentation/screens/qr/` |
| HTTP Client | Directo con `http` | `ApiClient` centralizado |
| Auth | Token opcional | Integrado con `authProvider` |
| Navegación | Simple | Con `BottomNavBar` y `AppDrawer` |

---

## ✅ Checklist de Verificación

- [x] Dependencia `mobile_scanner` instalada
- [x] Modelos `Reserva`, `Cliente`, `ScanResult` creados
- [x] API endpoints implementados en `QrApi`
- [x] Repository actualizado con nuevos métodos
- [x] Pantalla de escaneo completamente funcional
- [x] Permisos de cámara configurados (Android + iOS)
- [x] Control de escaneos duplicados
- [x] Historial visual implementado
- [x] Integración con backend
- [x] Manejo de errores robusto

---

## 📚 Recursos

- [Documentación mobile_scanner](https://pub.dev/packages/mobile_scanner)
- [Flutter Navigation](https://docs.flutter.dev/cookbook/navigation)
- [ApiClient del proyecto](lib/src/core/http/api_client.dart)

---

**Versión:** 1.0  
**Fecha:** Diciembre 2025  
**Proyecto:** ROGU Mobile  
**Estructura:** Adaptada a arquitectura limpia existente

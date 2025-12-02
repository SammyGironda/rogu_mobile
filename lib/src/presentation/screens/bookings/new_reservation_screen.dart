import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/app_drawer.dart';
import '../../../apis/deprecated/gestion_service.dart';
import '../../../apis/deprecated/auth_service.dart';
import '../../../apis/deprecated/profile_service.dart';
import 'package:url_launcher/url_launcher.dart';

// =============================================================
//  NUEVA PANTALLA "GESTIONAR" (adaptación completa de sedes React)
//  - Copia toda la funcionalidad estructural (crear sede, gestionar canchas)
//  - Sin lógica de backend (estado local), lista para integrar luego
//  - Inversión de colores: fondos claros -> oscuros; textos oscuros -> claros
// =============================================================

// ------------------ MODELOS ------------------
class SedeMng {
  final String id;
  final String nombre;
  final String descripcion;
  final String direccion;
  final String latitud;
  final String longitud;
  final String telefono;
  final String email;
  final String politicas;
  final String nit;
  final String licenciaFuncionamiento;
  SedeMng({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.direccion,
    required this.latitud,
    required this.longitud,
    required this.telefono,
    required this.email,
    required this.politicas,
    required this.nit,
    required this.licenciaFuncionamiento,
  });
  SedeMng copyWith({
    String? nombre,
    String? descripcion,
    String? direccion,
    String? latitud,
    String? longitud,
    String? telefono,
    String? email,
    String? politicas,
    String? nit,
    String? licenciaFuncionamiento,
  }) => SedeMng(
    id: id,
    nombre: nombre ?? this.nombre,
    descripcion: descripcion ?? this.descripcion,
    direccion: direccion ?? this.direccion,
    latitud: latitud ?? this.latitud,
    longitud: longitud ?? this.longitud,
    telefono: telefono ?? this.telefono,
    email: email ?? this.email,
    politicas: politicas ?? this.politicas,
    nit: nit ?? this.nit,
    licenciaFuncionamiento:
        licenciaFuncionamiento ?? this.licenciaFuncionamiento,
  );
}

class ParteAdicionalMng {
  final String id;
  final bool reglamentaria;
  final String equipamientoAdicional;
  final String observaciones;
  ParteAdicionalMng({
    required this.id,
    required this.reglamentaria,
    required this.equipamientoAdicional,
    required this.observaciones,
  });
}

class CanchaMng {
  final String id;
  final String sedeId;
  final String nombre;
  final String superficie;
  final bool cubierta;
  final bool iluminacion;
  final bool techada;
  final String aforoMaximo;
  final String dimensiones;
  final String reglasUso;
  final List<String> fotos;
  final List<String> disciplinas; // guarda ids de disciplinas
  final List<ParteAdicionalMng> partesAdicionales;
  CanchaMng({
    required this.id,
    required this.sedeId,
    required this.nombre,
    required this.superficie,
    required this.cubierta,
    required this.iluminacion,
    required this.techada,
    required this.aforoMaximo,
    required this.dimensiones,
    required this.reglasUso,
    required this.fotos,
    required this.disciplinas,
    required this.partesAdicionales,
  });
  CanchaMng copyWith({
    String? nombre,
    String? superficie,
    bool? cubierta,
    bool? iluminacion,
    bool? techada,
    String? aforoMaximo,
    String? dimensiones,
    String? reglasUso,
    List<String>? fotos,
    List<String>? disciplinas,
    List<ParteAdicionalMng>? partesAdicionales,
  }) => CanchaMng(
    id: id,
    sedeId: sedeId,
    nombre: nombre ?? this.nombre,
    superficie: superficie ?? this.superficie,
    cubierta: cubierta ?? this.cubierta,
    iluminacion: iluminacion ?? this.iluminacion,
    techada: techada ?? this.techada,
    aforoMaximo: aforoMaximo ?? this.aforoMaximo,
    dimensiones: dimensiones ?? this.dimensiones,
    reglasUso: reglasUso ?? this.reglasUso,
    fotos: fotos ?? this.fotos,
    disciplinas: disciplinas ?? this.disciplinas,
    partesAdicionales: partesAdicionales ?? this.partesAdicionales,
  );
}

class DisciplinaMng {
  final String id;
  final String nombre;
  final String categoria;
  final String descripcion;
  DisciplinaMng({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.descripcion,
  });
}

final disciplinasDisponibles = <DisciplinaMng>[
  DisciplinaMng(
    id: '1',
    nombre: 'Fútbol 11',
    categoria: 'Fútbol',
    descripcion: 'Fútbol tradicional con 11 jugadores por equipo',
  ),
  DisciplinaMng(
    id: '2',
    nombre: 'Fútbol 7',
    categoria: 'Fútbol',
    descripcion: 'Fútbol con 7 jugadores por equipo',
  ),
  DisciplinaMng(
    id: '3',
    nombre: 'Fútbol 5',
    categoria: 'Fútbol',
    descripcion: 'Fútbol sala con 5 jugadores por equipo',
  ),
  DisciplinaMng(
    id: '4',
    nombre: 'Baloncesto',
    categoria: 'Baloncesto',
    descripcion: 'Deporte de canasta con 5 jugadores por equipo',
  ),
  DisciplinaMng(
    id: '5',
    nombre: 'Voleibol',
    categoria: 'Voleibol',
    descripcion: 'Deporte de red con 6 jugadores por equipo',
  ),
  DisciplinaMng(
    id: '6',
    nombre: 'Tenis',
    categoria: 'Tenis',
    descripcion: 'Deporte individual o de parejas con raqueta',
  ),
  DisciplinaMng(
    id: '7',
    nombre: 'Pádel',
    categoria: 'Pádel',
    descripcion: 'Deporte de raqueta en pista cerrada',
  ),
  DisciplinaMng(
    id: '8',
    nombre: 'Atletismo',
    categoria: 'Atletismo',
    descripcion: 'Carreras y competencias atléticas',
  ),
];

// ------------------ STATE PROVIDERS ------------------
final _currentViewProvider = StateProvider<String>((_) => 'crear-sede');
final _sedeProvider = StateProvider<SedeMng?>((_) => null);
final _canchasProvider = StateProvider<List<CanchaMng>>((_) => []);

// ------------------ MAIN SCREEN ------------------
class NewReservationScreen extends ConsumerWidget {
  // mantiene nombre de ruta para bottom nav
  static const routeName = '/new-reservation';
  const NewReservationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(_currentViewProvider);
    final sede = ref.watch(_sedeProvider);
    final theme = Theme.of(context);
    final darkBg = const Color(0xFF121417);
    final darker = const Color(0xFF0D0F11);
    final lightText = const Color(0xFFF4F6F8);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: darker,
        title: Text(
          'Sistema de Gestión de Sedes Deportivas',
          style: theme.textTheme.titleMedium?.copyWith(color: lightText),
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu, color: lightText),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          if (sede != null && view == 'gestionar-canchas')
            TextButton.icon(
              onPressed: () {
                ref.read(_currentViewProvider.notifier).state = 'crear-sede';
                ref.read(_sedeProvider.notifier).state = null;
                ref.read(_canchasProvider.notifier).state = [];
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              label: const Text(
                'Volver a Crear Sede',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: const BottomNavBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [darker, darkBg, const Color(0xFF1E2230)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: (view == 'crear-sede' && sede == null)
                    ? _SedeForm(
                        onCreated: (s) {
                          ref.read(_sedeProvider.notifier).state = s;
                          ref.read(_currentViewProvider.notifier).state =
                              'gestionar-canchas';
                        },
                      )
                    : _CanchasManager(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------ WIDGET: SEDE FORM ------------------
class _SedeForm extends StatefulWidget {
  final void Function(SedeMng sede) onCreated;
  const _SedeForm({required this.onCreated});
  @override
  State<_SedeForm> createState() => _SedeFormState();
}

class _SedeFormState extends State<_SedeForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();
  final _direccion = TextEditingController();
  final _latitud = TextEditingController();
  final _longitud = TextEditingController();
  final _telefono = TextEditingController();
  final _email = TextEditingController();
  final _politicas = TextEditingController();
  final _nit = TextEditingController();
  final _licencia = TextEditingController();

  bool _submitting = false;
  String? _errorMsg;
  final _auth = AuthService();

  Future<void> _submit() async {
    if (_submitting) return;
    if (_formKey.currentState?.validate() != true) return;
    setState(() {
      _submitting = true;
      _errorMsg = null;
    });
    try {
      final user = await _auth.getUser();
      if (user == null || user.personaId == null) {
        setState(() {
          _errorMsg = 'Usuario sin persona asociada.';
          _submitting = false;
        });
        return;
      }
      final personaId = int.tryParse(user.personaId!) ?? 0;
      if (personaId == 0) {
        setState(() {
          _errorMsg = 'ID de persona inválido.';
          _submitting = false;
        });
        return;
      }
      final resp = await gestionService.createSede(
        idPersonaD: personaId,
        nombre: _nombre.text.trim(),
        descripcion: _descripcion.text.trim(),
        direccion: _direccion.text.trim(),
        latitud: _latitud.text.trim().isNotEmpty ? _latitud.text.trim() : null,
        longitud: _longitud.text.trim().isNotEmpty
            ? _longitud.text.trim()
            : null,
        telefono: _telefono.text.trim(),
        email: _email.text.trim(),
        politicas: _politicas.text.trim(),
        nit: _nit.text.trim(),
        licenciaFuncionamiento: _licencia.text.trim(),
      );
      if (resp['success'] == true) {
        final data = resp['data'] as Map<String, dynamic>? ?? {};
        final idBackend = data['idSede'] ?? data['id'] ?? data['id_sede'];
        final sedeArgs = <String, dynamic>{
          'id':
              idBackend?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          'nombre': _nombre.text.trim(),
          'descripcion': _descripcion.text.trim(),
          'direccion': _direccion.text.trim(),
          'latitud': _latitud.text.trim(),
          'longitud': _longitud.text.trim(),
          'telefono': _telefono.text.trim(),
          'email': _email.text.trim(),
          'politicas': _politicas.text.trim(),
          'nit': _nit.text.trim(),
          'licenciaFuncionamiento': _licencia.text.trim(),
        };
        if (!mounted) return;
        Navigator.of(
          context,
        ).pushNamed('/gestion-canchas', arguments: sedeArgs);
      } else {
        setState(() {
          _errorMsg = resp['message']?.toString() ?? 'Error desconocido';
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Error: $e';
      });
    } finally {
      if (mounted)
        setState(() {
          _submitting = false;
        });
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    _direccion.dispose();
    _latitud.dispose();
    _longitud.dispose();
    _telefono.dispose();
    _email.dispose();
    _politicas.dispose();
    _nit.dispose();
    _licencia.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final light = const Color(0xFFF4F6F8);
    final darkCard = const Color(0xFF1C1F26);
    final accent = AppColors.primary500;
    final labelStyle = TextStyle(color: light.withOpacity(.85), fontSize: 13);
    InputDecoration deco(String label, {String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: labelStyle,
      hintStyle: TextStyle(color: light.withOpacity(.4)),
      filled: true,
      fillColor: const Color(0xFF252A33),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: const Color(0xFF3A414D)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: accent),
      ),
    );

    double? lat = double.tryParse(_latitud.text.trim());
    double? lng = double.tryParse(_longitud.text.trim());
    final hasCoords = lat != null && lng != null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  'Crear Nueva Sede',
                  style: TextStyle(
                    color: light,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete la información de su sede deportiva',
                  style: TextStyle(color: light.withOpacity(.7)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (ctx, constraints) {
              // Layout simplificado móvil/desktop (heurística futura)
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _Card(
                          color: darkCard,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionTitle(
                                icon: Icons.domain,
                                title: 'Información Básica',
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _nombre,
                                decoration: deco(
                                  'Nombre de la Sede *',
                                  hint: 'Ej: Centro Deportivo Los Andes',
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Requerido'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _descripcion,
                                maxLines: 3,
                                decoration: deco(
                                  'Descripción',
                                  hint: 'Describe tu sede deportiva...',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _direccion,
                                decoration: deco(
                                  'Dirección *',
                                  hint: 'Ej: Calle 123 # 45-67',
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Requerido'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _latitud,
                                      decoration: deco(
                                        'Latitud',
                                        hint: 'Ej: -16.500',
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _longitud,
                                      decoration: deco(
                                        'Longitud',
                                        hint: 'Ej: -68.150',
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _politicas,
                                maxLines: 4,
                                decoration: deco(
                                  'Políticas de Uso',
                                  hint: 'Normas y políticas...',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            _Card(
                              color: darkCard,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionTitle(
                                    icon: Icons.call,
                                    title: 'Información de Contacto',
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _telefono,
                                    decoration: deco(
                                      'Teléfono *',
                                      hint: '+591 7xx xxx',
                                    ),
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                        ? 'Requerido'
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _email,
                                    decoration: deco(
                                      'Email *',
                                      hint: 'contacto@sede.com',
                                    ),
                                    validator: (v) =>
                                        v == null || !v.contains('@')
                                        ? 'Email inválido'
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _Card(
                              color: darkCard,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionTitle(
                                    icon: Icons.security,
                                    title: 'Información Legal',
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _nit,
                                    decoration: deco(
                                      'NIT *',
                                      hint: 'Ej: 123456-7',
                                    ),
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                        ? 'Requerido'
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _licencia,
                                    decoration: deco(
                                      'Licencia de Funcionamiento',
                                      hint: 'Ej: LIC-2025-001',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (hasCoords)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _Card(
                        color: darkCard,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle(
                              icon: Icons.pin_drop,
                              title: 'Vista Previa de Ubicación',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Lat: ${lat.toStringAsFixed(6)}  Lng: ${lng.toStringAsFixed(6)}',
                              style: TextStyle(color: light.withOpacity(.8)),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 220,
                              decoration: BoxDecoration(
                                color: const Color(0xFF252A33),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.place,
                                    color: light.withOpacity(.7),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Ubicación preparada',
                                    style: TextStyle(
                                      color: light.withOpacity(.8),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      final url = Uri.parse(
                                        'geo:${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}',
                                      );
                                      if (!await launchUrl(
                                        url,
                                        mode: LaunchMode.externalApplication,
                                      )) {
                                        final webUrl = Uri.parse(
                                          'https://www.google.com/maps/search/?api=1&query=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}',
                                        );
                                        await launchUrl(
                                          webUrl,
                                          mode: LaunchMode.externalApplication,
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.map),
                                    label: const Text('Ver en mapa'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: light,
                                      side: BorderSide(
                                        color: light.withOpacity(.3),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          if (_errorMsg != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Center(
                    child: Text(
                      _errorMsg!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_errorMsg!.toLowerCase().contains('401') ||
                      _errorMsg!.toLowerCase().contains('unauthorized'))
                    Wrap(
                      spacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        const Text(
                          '¿Aún no eres dueño?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        ElevatedButton(
                          onPressed: _submitting
                              ? null
                              : () async {
                                  setState(() {
                                    _submitting = true;
                                  });
                                  try {
                                    final user = await _auth.getUser();
                                    final token = await _auth.getToken();
                                    if (user == null ||
                                        token == null ||
                                        user.personaId == null) {
                                      setState(() {
                                        _errorMsg =
                                            'Inicia sesión y crea tu persona primero.';
                                      });
                                    } else {
                                      final resp = await ProfileService()
                                          .makeOwner(
                                            personaId: user.personaId!,
                                            token: token,
                                          );
                                      if (resp['success'] == true) {
                                        setState(() {
                                          _errorMsg =
                                              'Ahora eres dueño. Intenta nuevamente crear la sede.';
                                        });
                                      } else {
                                        setState(() {
                                          _errorMsg =
                                              'No se pudo crear dueño: ${resp['message'] ?? ''}';
                                        });
                                      }
                                    }
                                  } catch (e) {
                                    setState(() {
                                      _errorMsg = 'Error: $e';
                                    });
                                  } finally {
                                    setState(() {
                                      _submitting = false;
                                    });
                                  }
                                },
                          child: const Text('Hacerme dueño'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 38,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(
                _submitting ? 'Guardando...' : 'Guardar Sede y Continuar',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------ WIDGET: CANCHAS MANAGER ------------------
class _CanchasManager extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CanchasManager> createState() => _CanchasManagerState();
}

class _CanchasManagerState extends ConsumerState<_CanchasManager> {
  String view = 'list'; // list | create | edit
  CanchaMng? editing;
  String? deletingId;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Intento de carga inicial si ya existe sede (navegación directa futura)
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryFetch());
  }

  Future<void> _tryFetch() async {
    final sede = ref.read(_sedeProvider);
    if (sede == null) return;
    final idSedeInt = int.tryParse(sede.id);
    if (idSedeInt == null) return; // id local temporal
    setState(() {
      _loading = true;
      _error = null;
    });
    final resp = await gestionService.listCanchas(idSedeInt);
    if (!mounted) return;
    if (resp['success'] == true) {
      final data = resp['data'] as List? ?? [];
      final list = data.map((e) {
        final m = e as Map<String, dynamic>;
        return CanchaMng(
          id: (m['idCancha'] ?? m['id'] ?? '').toString(),
          sedeId: sede.id,
          nombre: m['nombre']?.toString() ?? 'Cancha',
          superficie: m['superficie']?.toString() ?? '',
          cubierta: (m['cubierta'] is bool)
              ? m['cubierta']
              : (m['cubierta']?.toString() == 'true'),
          iluminacion: (m['iluminacion']?.toString().toUpperCase() == 'SI'),
          techada: (m['techada'] is bool)
              ? m['techada']
              : (m['techada']?.toString() == 'true'),
          aforoMaximo: (m['aforoMax'] ?? m['aforoMaximo'] ?? '').toString(),
          dimensiones: m['dimensiones']?.toString() ?? '',
          reglasUso: m['reglasUso']?.toString() ?? '',
          fotos: (m['fotos'] is List)
              ? (m['fotos'] as List).map((x) => x.toString()).toList()
              : <String>[],
          disciplinas: (m['disciplinas'] is List)
              ? (m['disciplinas'] as List).map((x) => x.toString()).toList()
              : <String>[],
          partesAdicionales: const [], // No soportado aún en backend
        );
      }).toList();
      ref.read(_canchasProvider.notifier).state = list;
    } else {
      _error = resp['message']?.toString();
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sede = ref.watch(_sedeProvider);
    final canchas = ref.watch(_canchasProvider);
    final light = const Color(0xFFF4F6F8);
    final darkCard = const Color(0xFF1C1F26);
    final accent = AppColors.primary500;
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width < 360 ? 1 : 2;
    if (sede == null) {
      return const SizedBox.shrink();
    }
    if (view == 'create' || view == 'edit') {
      return _CanchaForm(
        sede: sede,
        cancha: editing,
        onCancel: () => setState(() => view = 'list'),
        onSave: (updatedBackend) async {
          // Tras creación/edición exitosa, recargar lista desde backend.
          await _tryFetch();
          setState(() {
            view = 'list';
            editing = null;
          });
        },
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Card(
          color: const Color(0xFF0F2535),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sede.nombre,
                style: TextStyle(
                  color: light,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${sede.direccion} | ${sede.telefono}',
                style: TextStyle(color: light.withOpacity(.7)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (sede.descripcion.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  sede.descripcion,
                  style: TextStyle(color: light.withOpacity(.65)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Canchas de la Sede',
                    style: TextStyle(
                      color: light,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (_loading)
                    Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cargando...',
                          style: TextStyle(color: light.withOpacity(.7)),
                        ),
                      ],
                    )
                  else
                    Text(
                      '${canchas.length} ${canchas.length == 1 ? 'cancha registrada' : 'canchas registradas'}',
                      style: TextStyle(color: light.withOpacity(.7)),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: accent),
                  onPressed: () => setState(() {
                    view = 'create';
                    editing = null;
                  }),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Agregar Cancha',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _loading ? null : _tryFetch,
              icon: const Icon(Icons.refresh),
              label: const Text('Refrescar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: light,
                side: BorderSide(color: light.withOpacity(.3)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (canchas.isEmpty)
          _Card(
            color: darkCard,
            dashed: true,
            child: Column(
              children: [
                const SizedBox(height: 24),
                Icon(
                  Icons.add_circle_outline,
                  size: 54,
                  color: light.withOpacity(.35),
                ),
                const SizedBox(height: 12),
                Text(
                  'No hay canchas registradas',
                  style: TextStyle(color: light, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Comienza agregando tu primera cancha',
                  style: TextStyle(color: light.withOpacity(.6)),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: accent),
                  onPressed: () => setState(() {
                    view = 'create';
                  }),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Crear Primera Cancha',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: .82,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: canchas.length,
            itemBuilder: (ctx, i) {
              final c = canchas[i];
              return _Card(
                color: darkCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E4A4F), Color(0xFF223D65)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: c.fotos.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  c.fotos.first,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Icon(
                                      Icons.image,
                                      color: Colors.white.withOpacity(.4),
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  'Sin fotos',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(.6),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      c.nombre,
                      style: TextStyle(
                        color: light,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${c.superficie} • ${c.dimensiones}',
                      style: TextStyle(
                        color: light.withOpacity(.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Aforo:',
                          style: TextStyle(
                            color: light.withOpacity(.65),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${c.aforoMaximo} personas',
                          style: TextStyle(color: light, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (c.disciplinas.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        children: [
                          for (
                            int k = 0;
                            k <
                                (c.disciplinas.length > 3
                                    ? 3
                                    : c.disciplinas.length);
                            k++
                          )
                            _Badge(label: 'Disciplina ${k + 1}'),
                          if (c.disciplinas.length > 3)
                            _Badge(label: '+${c.disciplinas.length - 3}'),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: light,
                              side: BorderSide(color: light.withOpacity(.3)),
                            ),
                            onPressed: () {
                              setState(() {
                                view = 'edit';
                                editing = c;
                              });
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Editar'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                            ),
                            onPressed: () {
                              setState(() {
                                deletingId = c.id;
                              });
                            },
                            icon: const Icon(Icons.delete, size: 18),
                            label: const Text('Eliminar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        if (deletingId != null)
          _DeleteDialog(
            onCancel: () => setState(() => deletingId = null),
            onConfirm: () {
              ref.read(_canchasProvider.notifier).state = canchas
                  .where((x) => x.id != deletingId)
                  .toList();
              setState(() => deletingId = null);
            },
          ),
      ],
    );
  }
}

// ------------------ CANCHA FORM ------------------
class _CanchaForm extends StatefulWidget {
  final SedeMng sede;
  final CanchaMng? cancha;
  final void Function(CanchaMng cancha) onSave;
  final VoidCallback onCancel;
  const _CanchaForm({
    required this.sede,
    required this.cancha,
    required this.onSave,
    required this.onCancel,
  });
  @override
  State<_CanchaForm> createState() => _CanchaFormState();
}

class _CanchaFormState extends State<_CanchaForm>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _nombre = TextEditingController();
  final _superficie = TextEditingController();
  final _aforo = TextEditingController();
  final _dimensiones = TextEditingController();
  final _reglas = TextEditingController();
  bool cubierta = false;
  bool iluminacion = false;
  bool techada = false;
  final fotos = <String>[];
  final disciplinasSel = <String>[];
  final partes = <ParteAdicionalMng>[];
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    final c = widget.cancha;
    if (c != null) {
      _nombre.text = c.nombre;
      _superficie.text = c.superficie;
      _aforo.text = c.aforoMaximo;
      _dimensiones.text = c.dimensiones;
      _reglas.text = c.reglasUso;
      cubierta = c.cubierta;
      iluminacion = c.iluminacion;
      techada = c.techada;
      fotos.addAll(c.fotos);
      disciplinasSel.addAll(c.disciplinas);
      partes.addAll(c.partesAdicionales);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nombre.dispose();
    _superficie.dispose();
    _aforo.dispose();
    _dimensiones.dispose();
    _reglas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final light = const Color(0xFFF4F6F8);
    final darkCard = const Color(0xFF1C1F26);
    final accent = AppColors.primary500;
    final vh = MediaQuery.of(context).size.height;
    final tabHeight = (vh * 0.6).clamp(380.0, 700.0);
    InputDecoration deco(String label, {String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: light.withOpacity(.85)),
      hintStyle: TextStyle(color: light.withOpacity(.4)),
      filled: true,
      fillColor: const Color(0xFF252A33),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: const Color(0xFF3A414D)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: accent),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.cancha == null
                        ? 'Crear Nueva Cancha'
                        : 'Editar Cancha',
                    style: TextStyle(
                      color: light,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sede: ${widget.sede.nombre}',
                    style: TextStyle(color: light.withOpacity(.7)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: light,
                    side: BorderSide(color: light.withOpacity(.3)),
                  ),
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TabBar(
          controller: _tabs,
          indicatorColor: accent,
          labelColor: light,
          unselectedLabelColor: light.withOpacity(.5),
          tabs: const [
            Tab(text: 'Información Básica'),
            Tab(text: 'Fotos'),
            Tab(text: 'Disciplinas'),
            Tab(text: 'Elementos Adicionales'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: tabHeight,
          child: TabBarView(
            controller: _tabs,
            children: [
              // Básica
              SingleChildScrollView(
                child: _Card(
                  color: darkCard,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nombre,
                              decoration: deco(
                                'Nombre de la Cancha *',
                                hint: 'Ej: Cancha Principal',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _superficie,
                              decoration: deco(
                                'Superficie *',
                                hint: 'Césped sintético',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _dimensiones,
                              decoration: deco(
                                'Dimensiones *',
                                hint: '40m x 20m',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _aforo,
                              decoration: deco('Aforo Máximo *', hint: '100'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SectionTitle(icon: Icons.tune, title: 'Características'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _ToggleChip(
                            label: 'Cubierta',
                            value: cubierta,
                            onChanged: (v) => setState(() => cubierta = v),
                          ),
                          _ToggleChip(
                            label: 'Iluminación',
                            value: iluminacion,
                            onChanged: (v) => setState(() => iluminacion = v),
                          ),
                          _ToggleChip(
                            label: 'Techada',
                            value: techada,
                            onChanged: (v) => setState(() => techada = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _reglas,
                        maxLines: 5,
                        decoration: deco(
                          'Reglas de Uso',
                          hint: 'Normativas...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Fotos
              SingleChildScrollView(
                child: _Card(
                  color: darkCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(
                        icon: Icons.photo_library,
                        title: 'Galería de Fotos',
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                        ),
                        onPressed: () async {
                          final url = await _promptUrl(context);
                          if (url != null && url.trim().isNotEmpty) {
                            setState(() => fotos.add(url.trim()));
                          }
                        },
                        icon: const Icon(Icons.upload, color: Colors.white),
                        label: const Text(
                          'Agregar Foto (URL)',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (fotos.isEmpty)
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white24,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'No hay fotos agregadas aún',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                          itemCount: fotos.length,
                          itemBuilder: (ctx, i) {
                            final f = fotos[i];
                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      f,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.black26,
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.broken_image,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: InkWell(
                                    onTap: () =>
                                        setState(() => fotos.removeAt(i)),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.close,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              // Disciplinas
              SingleChildScrollView(
                child: _Card(
                  color: darkCard,
                  child: Column(
                    children: [
                      _SectionTitle(
                        icon: Icons.emoji_events,
                        title: 'Disciplinas Deportivas',
                      ),
                      const SizedBox(height: 8),
                      if (disciplinasSel.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF123524),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${disciplinasSel.length} disciplina(s) seleccionada(s)',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: disciplinasDisponibles.length,
                        itemBuilder: (ctx, i) {
                          final d = disciplinasDisponibles[i];
                          final selected = disciplinasSel.contains(d.id);
                          return InkWell(
                            onTap: () => setState(
                              () => selected
                                  ? disciplinasSel.remove(d.id)
                                  : disciplinasSel.add(d.id),
                            ),
                            child: _Card(
                              color: selected
                                  ? const Color(0xFF0E3B24)
                                  : const Color(0xFF252A33),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          d.nombre,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (selected)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.greenAccent,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  _Badge(label: d.categoria),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: Text(
                                      d.descripcion,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      if (disciplinasSel.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _Card(
                            color: const Color(0xFF252A33),
                            dashed: true,
                            child: SizedBox(
                              height: 100,
                              child: Center(
                                child: Text(
                                  'Selecciona al menos una disciplina',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Partes Adicionales
              SingleChildScrollView(
                child: _Card(
                  color: darkCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(
                        icon: Icons.settings,
                        title: 'Elementos y Partes Adicionales',
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                        ),
                        onPressed: () async {
                          final nueva = await showDialog<ParteAdicionalMng>(
                            context: context,
                            builder: (ctx) {
                              bool reglamentaria = false;
                              final equip = TextEditingController();
                              final obs = TextEditingController();
                              return AlertDialog(
                                backgroundColor: const Color(0xFF252A33),
                                title: const Text(
                                  'Nuevo Elemento',
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: SizedBox(
                                  width: 400,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '¿Es reglamentaria?',
                                              style: TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ),
                                          Switch(
                                            value: reglamentaria,
                                            onChanged: (v) => setState(() {
                                              reglamentaria = v;
                                            }),
                                            activeColor: accent,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: equip,
                                        maxLines: 3,
                                        decoration: InputDecoration(
                                          labelText: 'Equipamiento Adicional',
                                          labelStyle: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFF1C1F26),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.white24,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: obs,
                                        maxLines: 3,
                                        decoration: InputDecoration(
                                          labelText: 'Observaciones',
                                          labelStyle: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFF1C1F26),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.white24,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(
                                        ctx,
                                        ParteAdicionalMng(
                                          id: DateTime.now()
                                              .millisecondsSinceEpoch
                                              .toString(),
                                          reglamentaria: reglamentaria,
                                          equipamientoAdicional: equip.text
                                              .trim(),
                                          observaciones: obs.text.trim(),
                                        ),
                                      );
                                    },
                                    child: const Text('Guardar'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (nueva != null) setState(() => partes.add(nueva));
                        },
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'Agregar Elemento Adicional',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (partes.isEmpty)
                        _Card(
                          color: const Color(0xFF252A33),
                          dashed: true,
                          child: SizedBox(
                            height: 120,
                            child: Center(
                              child: Text(
                                'No hay elementos adicionales registrados',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          ),
                        )
                      else
                        Column(
                          children: partes
                              .map(
                                (p) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _Card(
                                    color: const Color(0xFF252A33),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (p.reglamentaria)
                                                _Badge(
                                                  label: 'Reglamentaria',
                                                  color: Colors.green,
                                                ),
                                              if (p
                                                  .equipamientoAdicional
                                                  .isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 4,
                                                      ),
                                                  child: Text(
                                                    p.equipamientoAdicional,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              if (p.observaciones.isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 4,
                                                      ),
                                                  child: Text(
                                                    p.observaciones,
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              setState(() => partes.remove(p)),
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: widget.onCancel,
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              onPressed: _saving
                  ? null
                  : () async {
                      setState(() {
                        _saving = true;
                        _error = null;
                      });
                      try {
                        final sedeIdInt = int.tryParse(widget.sede.id);
                        if (sedeIdInt == null) {
                          setState(() {
                            _error = 'ID de sede inválido';
                          });
                          return;
                        }
                        if (_nombre.text.trim().isEmpty ||
                            _superficie.text.trim().isEmpty ||
                            _aforo.text.trim().isEmpty ||
                            _dimensiones.text.trim().isEmpty) {
                          setState(() {
                            _error = 'Campos requeridos faltantes';
                          });
                          return;
                        }
                        final aforoInt = int.tryParse(_aforo.text.trim());
                        if (aforoInt == null) {
                          setState(() {
                            _error = 'Aforo inválido';
                          });
                          return;
                        }
                        Map<String, dynamic> resp;
                        if (widget.cancha == null) {
                          resp = await gestionService.createCancha(
                            idSede: sedeIdInt,
                            nombre: _nombre.text.trim(),
                            superficie: _superficie.text.trim(),
                            cubierta: cubierta,
                            iluminacion: iluminacion,
                            techada: techada,
                            aforoMax: aforoInt,
                            dimensiones: _dimensiones.text.trim(),
                            reglasUso: _reglas.text.trim(),
                            disciplinas: List.of(disciplinasSel),
                            fotos: List.of(fotos),
                          );
                        } else {
                          final canchaIdInt = int.tryParse(widget.cancha!.id);
                          if (canchaIdInt == null) {
                            setState(() {
                              _error = 'ID de cancha inválido';
                            });
                            return;
                          }
                          final fields = {
                            'nombre': _nombre.text.trim(),
                            'superficie': _superficie.text.trim(),
                            'cubierta': cubierta,
                            // Backend espera string con longitud >= 3
                            'iluminacion': iluminacion ? 'true' : 'false',
                            'aforoMax': aforoInt,
                            'dimensiones': _dimensiones.text.trim(),
                            'reglasUso': _reglas.text.trim(),
                            'disciplinas': List.of(disciplinasSel),
                            'fotos': List.of(fotos),
                          };
                          resp = await gestionService.updateCancha(
                            canchaIdInt,
                            fields,
                          );
                        }
                        if (resp['success'] == true) {
                          widget.onSave(
                            widget.cancha ??
                                CanchaMng(
                                  id:
                                      (resp['data']?['idCancha'] ??
                                              resp['data']?['id'] ??
                                              DateTime.now()
                                                  .millisecondsSinceEpoch)
                                          .toString(),
                                  sedeId: widget.sede.id,
                                  nombre: _nombre.text.trim(),
                                  superficie: _superficie.text.trim(),
                                  cubierta: cubierta,
                                  iluminacion: iluminacion,
                                  techada: techada,
                                  aforoMaximo: _aforo.text.trim(),
                                  dimensiones: _dimensiones.text.trim(),
                                  reglasUso: _reglas.text.trim(),
                                  fotos: List.of(fotos),
                                  disciplinas: List.of(disciplinasSel),
                                  partesAdicionales: List.of(partes),
                                ),
                          );
                        } else {
                          setState(() {
                            _error =
                                resp['message']?.toString() ??
                                'Error desconocido';
                          });
                        }
                      } catch (e) {
                        setState(() {
                          _error = 'Error: $e';
                        });
                      } finally {
                        if (mounted)
                          setState(() {
                            _saving = false;
                          });
                      }
                    },
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(
                _saving ? 'Guardando...' : 'Guardar Cancha',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ------------------ REUSABLES ------------------
class _Card extends StatelessWidget {
  final Widget child;
  final Color color;
  final bool dashed;
  const _Card({required this.child, required this.color, this.dashed = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white24,
          width: 1,
          style: dashed ? BorderStyle.solid : BorderStyle.solid,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color? color;
  const _Badge({required this.label, this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: (color ?? Colors.blueGrey).withOpacity(.6),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(color: Colors.white, fontSize: 11),
    ),
  );
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleChip({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF0E3B24) : const Color(0xFF252A33),
          border: Border.all(
            color: value ? Colors.greenAccent : Colors.white24,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_circle : Icons.circle_outlined,
              color: value ? Colors.greenAccent : Colors.white38,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _DeleteDialog extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  const _DeleteDialog({required this.onCancel, required this.onConfirm});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1C1F26),
      title: const Text(
        '¿Estás seguro?',
        style: TextStyle(color: Colors.white),
      ),
      content: const Text(
        'Esta acción no se puede deshacer. La cancha será eliminada permanentemente.',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(onPressed: onCancel, child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: onConfirm,
          child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

Future<String?> _promptUrl(BuildContext context) async {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1C1F26),
        title: const Text(
          'Agregar Foto (URL)',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'URL',
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Agregar'),
          ),
        ],
      );
    },
  );
}

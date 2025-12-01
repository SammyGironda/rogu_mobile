import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/bottom_nav.dart';
import '../services/gestion_service.dart';
import '../state/providers.dart';
import 'login_screen.dart';
import 'new_reservation_screen.dart';
import 'dashboard_screen.dart';

// Modelos locales (idénticos a los usados en new_reservation_screen)
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
  final List<String> disciplinas;
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
}

// Proveedores locales para el estado de esta pantalla
final _sedeProvider = StateProvider<SedeMng?>((_) => null);
final _canchasProvider = StateProvider<List<CanchaMng>>((_) => []);

class GestionCanchasScreen extends ConsumerStatefulWidget {
  static const String routeName = '/gestion-canchas';
  final Map<String, dynamic> sedeArgs;
  const GestionCanchasScreen({super.key, required this.sedeArgs});

  @override
  ConsumerState<GestionCanchasScreen> createState() =>
      _GestionCanchasScreenState();
}

class _GestionCanchasScreenState extends ConsumerState<GestionCanchasScreen> {
  @override
  void initState() {
    super.initState();
    // Inicializar estado de sede al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (!auth.isAuthenticated) {
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        return;
      }
      // Validar roles y resolver sede real desde idPersona
      final personaId = int.tryParse(auth.user?.personaId ?? '');
      if (personaId == null) {
        Navigator.pushReplacementNamed(context, NewReservationScreen.routeName);
        return;
      }
      // Usa servicio unificado para validar Admin/Dueño y traer sede
      gestionService.resolveGestionEntryForPersona(personaId).then((result) {
        if (!mounted) return;
        if (result['success'] != true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message']?.toString() ?? 'Acceso restringido',
              ),
            ),
          );
          Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
          return;
        }
        final isAdmin = result['isAdmin'] == true;
        final isOwner = result['isOwner'] == true;
        if (!(isAdmin || isOwner)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Acceso permitido sólo a dueños o administradores')),
          );
          Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
          return;
        }

        final dynamic sedeObj = result['sede'];
        if (sedeObj == null) {
          // Sin sede: enviar a creación de sede
          Navigator.pushReplacementNamed(context, NewReservationScreen.routeName);
          return;
        }
        // Normalizar sede y setear provider local
        final raw = sedeObj as Map<String, dynamic>;
        final sede = SedeMng(
          id: (raw['idSede'] ?? raw['id'] ?? raw['idsede'] ?? '')
              .toString(),
          nombre: raw['nombre']?.toString() ?? '',
          descripcion: raw['descripcion']?.toString() ?? '',
          direccion: (raw['direccion'] ?? raw['addressLine'] ?? '').toString(),
          latitud: (raw['latitud'] ?? raw['latitude'] ?? '').toString(),
          longitud: (raw['longitud'] ?? raw['longitude'] ?? '').toString(),
          telefono: raw['telefono']?.toString() ?? '',
          email: raw['email']?.toString() ?? '',
          politicas: raw['politicas']?.toString() ?? '',
          nit: (raw['NIT'] ?? raw['nit'] ?? '').toString(),
          licenciaFuncionamiento:
              (raw['LicenciaFuncionamiento'] ?? raw['licenciaFuncionamiento'] ?? '')
                  .toString(),
        );
        ref.read(_sedeProvider.notifier).state = sede;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final darkBg = const Color(0xFF121417);
    final darker = const Color(0xFF0D0F11);
    final lightText = const Color(0xFFF4F6F8);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: darker,
        title: Text(
          'Gestionar Canchas',
          style: theme.textTheme.titleMedium?.copyWith(color: lightText),
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu, color: lightText),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
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
            child: const _CanchasManager(),
          ),
        ),
      ),
    );
  }
}

class _CanchasManager extends ConsumerStatefulWidget {
  const _CanchasManager();
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
          iluminacion:
              (m['iluminacion']?.toString().toUpperCase() == 'SI') ||
              (m['iluminacion']?.toString() == 'true'),
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
          partesAdicionales: const [],
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.black26,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.white54,
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
        borderSide: const BorderSide(color: Color(0xFF3A414D)),
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
                      // Se removió la sección de "Características" (cubierta/iluminación/techada)
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
                      const _SectionTitle(
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
                          child: const Text(
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
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(20),
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
                      const _SectionTitle(
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
                        itemCount: _disciplinasDisponibles.length,
                        itemBuilder: (ctx, i) {
                          final d = _disciplinasDisponibles[i];
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
                                          style: const TextStyle(
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
                                      style: const TextStyle(
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
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: _Card(
                            color: Color(0xFF252A33),
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
                      const _SectionTitle(
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
                                          const Text(
                                            'Reglamentaria',
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                          const Spacer(),
                                          StatefulBuilder(
                                            builder: (ctx, setInner) {
                                              return Switch(
                                                value: reglamentaria,
                                                onChanged: (v) => setInner(
                                                  () => reglamentaria = v,
                                                ),
                                                activeColor: accent,
                                              );
                                            },
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
                                            borderSide: const BorderSide(
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
                                            borderSide: const BorderSide(
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
                        const _Card(
                          color: Color(0xFF252A33),
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
                                                const _Badge(
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
                                                const Padding(
                                                  padding: EdgeInsets.only(
                                                    top: 4,
                                                  ),
                                                  child: Text(
                                                    'Observaciones',
                                                    style: TextStyle(
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

// _ToggleChip eliminado por solicitud; ya no se usa sección Características.

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

// Disciplinas mock locales (idénticas a las del otro archivo)
class _DisciplinaMng {
  final String id;
  final String nombre;
  final String categoria;
  final String descripcion;
  _DisciplinaMng({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.descripcion,
  });
}

final _disciplinasDisponibles = <_DisciplinaMng>[
  _DisciplinaMng(
    id: '1',
    nombre: 'Fútbol 11',
    categoria: 'Fútbol',
    descripcion: 'Fútbol tradicional con 11 jugadores por equipo',
  ),
  _DisciplinaMng(
    id: '2',
    nombre: 'Fútbol 7',
    categoria: 'Fútbol',
    descripcion: 'Fútbol con 7 jugadores por equipo',
  ),
  _DisciplinaMng(
    id: '3',
    nombre: 'Fútbol 5',
    categoria: 'Fútbol',
    descripcion: 'Fútbol sala con 5 jugadores por equipo',
  ),
  _DisciplinaMng(
    id: '4',
    nombre: 'Baloncesto',
    categoria: 'Baloncesto',
    descripcion: 'Deporte de canasta con 5 jugadores por equipo',
  ),
  _DisciplinaMng(
    id: '5',
    nombre: 'Voleibol',
    categoria: 'Voleibol',
    descripcion: 'Deporte de red con 6 jugadores por equipo',
  ),
  _DisciplinaMng(
    id: '6',
    nombre: 'Tenis',
    categoria: 'Tenis',
    descripcion: 'Deporte individual o de parejas con raqueta',
  ),
  _DisciplinaMng(
    id: '7',
    nombre: 'Pádel',
    categoria: 'Pádel',
    descripcion: 'Deporte de raqueta en pista cerrada',
  ),
  _DisciplinaMng(
    id: '8',
    nombre: 'Atletismo',
    categoria: 'Atletismo',
    descripcion: 'Carreras y competencias atléticas',
  ),
];

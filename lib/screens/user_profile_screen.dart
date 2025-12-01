import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';
import '../theme/theme.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/gradient_button.dart';
import '../widgets/app_drawer.dart';
import '../models/persona.dart';
import 'login_screen.dart';

// Provider separado para obtener Persona completa
final personaProvider = FutureProvider.autoDispose<Persona?>((ref) async {
  final authState = ref.watch(authProvider);
  final user = authState.user;
  if (user == null || user.personaId == null) return null;
  final token = await ref.read(authServiceProvider).getToken();
  if (token == null) return null;
  final profileSvc = ref.read(profileServiceProvider);
  final result = await profileSvc.fetchPersona(user.personaId!, token);
  if (result['success'] == true && result['data'] != null) {
    return Persona.fromMap(result['data']);
  }
  return null;
});

class UserProfileScreen extends ConsumerWidget {
  static const String routeName = '/profile';
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: 280,
              child: GradientButton(
                onPressed: () => Navigator.pushReplacementNamed(context, LoginScreen.routeName),
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.lock_open, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Iniciar Sesión'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final personaAsync = ref.watch(personaProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : AppColors.neutral700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu, color: iconColor),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, LoginScreen.routeName);
              }
            },
          )
        ],
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: const BottomNavBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                personaAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error cargando datos personales: $e'),
                    ),
                  ),
                  data: (persona) => _personaCard(theme, user.username, user.email, persona),
                ),
                const SizedBox(height: 16),
                _actionsCard(context, ref, theme),
                const SizedBox(height: 32),
                _bottomSessionActions(context, ref),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _personaCard(ThemeData theme, String username, String email, Persona? p) {
    int? edad;
    if (p?.fechaNacimiento != null) {
      final hoy = DateTime.now();
      edad = hoy.year - p!.fechaNacimiento!.year - ((hoy.month < p.fechaNacimiento!.month || (hoy.month == p.fechaNacimiento!.month && hoy.day < p.fechaNacimiento!.day)) ? 1 : 0);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary500,
                  backgroundImage: (p?.urlFoto != null && (p!.urlFoto?.isNotEmpty ?? false)) ? NetworkImage(p.urlFoto!) : null,
                  child: (p?.urlFoto == null || (p!.urlFoto?.isEmpty ?? true))
                      ? const Icon(Icons.person, size: 36, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p?.nombres ?? username, style: theme.textTheme.titleLarge),
                      if (p != null)
                        Text([
                          p.paterno,
                          p.materno,
                        ].where((e) => e != null && e.isNotEmpty).join(' ')),
                      Text(email, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.neutral600)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(label: Text('Usuario: $username')),
                if (p?.genero != null && p!.genero!.isNotEmpty) Chip(label: Text('Género: ${p.genero}')),
                if (edad != null) Chip(label: Text('Edad: $edad')),
              ],
            ),
            const Divider(height: 32),
            _infoRow('Documento', _doc(p)),
            _infoRow('Teléfono', p?.telefono ?? 'No disponible'),
            _infoRow('Nacimiento', _fecha(p?.fechaNacimiento)),
            _infoRow('Creado', _fecha(p?.creadoEn)),
          ],
        ),
      ),
    );
  }

  Widget _actionsCard(BuildContext context, WidgetRef ref, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Acciones', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showEditPersona(context, ref),
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar datos'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showChangePassword(context, ref),
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('Cambiar contraseña'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showChangeAvatar(context, ref),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Cambiar foto'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _makeOwner(context, ref),
                  icon: const Icon(Icons.workspace_premium),
                  label: const Text('Hacerme dueño'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomSessionActions(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: GradientButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, LoginScreen.routeName);
              }
            },
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: const Text('Cerrar sesión'),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Flexible(child: Text(value.isEmpty ? '-' : value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  String _doc(Persona? p) {
    if (p == null) return '-';
    final tipo = p.documentoTipo;
    final num = p.documentoNumero;
    if ((tipo == null || tipo.isEmpty) && (num == null || num.isEmpty)) return '-';
    return [tipo, num].where((e) => e != null && e.isNotEmpty).join(' ');
  }

  String _fecha(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  void _showEditPersona(BuildContext context, WidgetRef ref) {
    final persona = ref.read(personaProvider).value;
    final user = ref.read(authProvider).user;
    if (persona == null || user?.personaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sin datos para editar')));
      return;
    }
    final nombresCtrl = TextEditingController(text: persona.nombres);
    final paternoCtrl = TextEditingController(text: persona.paterno ?? '');
    final maternoCtrl = TextEditingController(text: persona.materno ?? '');
    final telefonoCtrl = TextEditingController(text: persona.telefono ?? '');
    DateTime? fechaNacimiento = persona.fechaNacimiento;
    final fechaCtrl = TextEditingController(
      text: fechaNacimiento == null ? '' : _fecha(fechaNacimiento),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar datos personales'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nombresCtrl, decoration: const InputDecoration(labelText: 'Nombres')),
              TextField(controller: paternoCtrl, decoration: const InputDecoration(labelText: 'Apellido paterno')),
              TextField(controller: maternoCtrl, decoration: const InputDecoration(labelText: 'Apellido materno')),
              TextField(controller: telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono')),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: fechaNacimiento ?? DateTime(2000, 1, 1),
                    firstDate: DateTime(1900, 1, 1),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    fechaNacimiento = picked;
                    fechaCtrl.text = _fecha(picked);
                  }
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: fechaCtrl,
                    decoration: const InputDecoration(labelText: 'Fecha nacimiento (tocar para elegir)'),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final token = await ref.read(authServiceProvider).getToken();
              if (token == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sin token')));
                return;
              }
              final original = persona;
              final updateFields = <String, dynamic>{};
              void addIfChanged(String key, String? originalValue, String newValue) {
                final trimmed = newValue.trim();
                if (trimmed.isNotEmpty && trimmed != (originalValue ?? '')) {
                  updateFields[key] = trimmed;
                }
              }
              addIfChanged('nombres', original.nombres, nombresCtrl.text);
              addIfChanged('paterno', original.paterno, paternoCtrl.text);
              addIfChanged('materno', original.materno, maternoCtrl.text);
              addIfChanged('telefono', original.telefono, telefonoCtrl.text);
              if (fechaNacimiento != null && original.fechaNacimiento != fechaNacimiento) {
                // Backend espera formato ISO (YYYY-MM-DD)
                final iso = '${fechaNacimiento!.year.toString().padLeft(4,'0')}-${fechaNacimiento!.month.toString().padLeft(2,'0')}-${fechaNacimiento!.day.toString().padLeft(2,'0')}';
                updateFields['fechaNacimiento'] = iso;
              }
              if (updateFields.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sin cambios para actualizar')));
                return;
              }
              final res = await ref.read(profileServiceProvider).updatePersona(
                personaId: user!.personaId!,
                token: token,
                fields: updateFields,
              );
              if (res['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos actualizados')));
                // Consumir el valor de retorno para evitar lint de unused result
                final _ = ref.refresh(personaProvider);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${res['message']}')));
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showChangePassword(BuildContext context, WidgetRef ref) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: currentCtrl, decoration: const InputDecoration(labelText: 'Actual'), obscureText: true),
            TextField(controller: newCtrl, decoration: const InputDecoration(labelText: 'Nueva'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final token = await ref.read(authServiceProvider).getToken();
              if (token == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sin token')));
                return;
              }
              if (newCtrl.text.trim().length < 8) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La nueva contraseña debe tener mínimo 8 caracteres')));
                return;
              }
              final user = ref.read(authProvider).user;
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario no disponible')));
                return;
              }
              final res = await ref.read(profileServiceProvider).changePasswordWithCurrent(
                token: token,
                userEmail: user.email,
                currentPassword: currentCtrl.text.trim(),
                userId: user.id,
                newPassword: newCtrl.text.trim(),
              );
              if (res['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña cambiada')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${res['message']}')));
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showChangeAvatar(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar foto de perfil'),
        content: const Text('Funcionalidad pendiente: seleccionar imagen y subir al servidor.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Future<void> _makeOwner(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authProvider).user;
    if (user?.personaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Persona no asociada')));
      return;
    }
    final token = await ref.read(authServiceProvider).getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sin token')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Creando perfil de dueño...')));
    final res = await ref.read(profileServiceProvider).makeOwner(
      personaId: user!.personaId!,
      token: token,
    );
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solicitud de dueño registrada')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${res['message']}')));
    }
  }
}

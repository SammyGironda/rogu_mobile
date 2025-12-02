import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/persona.dart';
import '../../../data/models/user.dart';
import '../../../features/profile/application/profile_controller.dart';
import '../../state/providers.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/gradient_button.dart';
import '../auth/login_screen.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
	static const String routeName = '/profile';

	const UserProfileScreen({super.key});

	@override
	ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
	final TextEditingController _currentPassCtrl = TextEditingController();
	final TextEditingController _newPassCtrl = TextEditingController();
	final TextEditingController _confirmPassCtrl = TextEditingController();
	final TextEditingController _deleteConfirmCtrl = TextEditingController();
	final TextEditingController _deletePasswordCtrl = TextEditingController();

	@override
	void initState() {
		super.initState();
		Future.microtask(() {
			final auth = ref.read(authProvider);
			if (auth.isAuthenticated && auth.user != null) {
				ref.read(profileControllerProvider.notifier).loadProfile(
					user: auth.user!,
				);
			} else {
				Navigator.pushReplacementNamed(context, LoginScreen.routeName);
			}
		});
	}

	@override
	void dispose() {
		_currentPassCtrl.dispose();
		_newPassCtrl.dispose();
		_confirmPassCtrl.dispose();
		_deleteConfirmCtrl.dispose();
		_deletePasswordCtrl.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		final authState = ref.watch(authProvider);
		final user = authState.user;
		if (!authState.isAuthenticated || user == null) {
			return const SizedBox.shrink();
		}

		final profileState = ref.watch(profileControllerProvider);
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
								Navigator.pushReplacementNamed(
									context,
									LoginScreen.routeName,
								);
							}
						},
					),
				],
			),
			drawer: const AppDrawer(),
			bottomNavigationBar: const BottomNavBar(),
			body: RefreshIndicator(
				onRefresh: () async {
					await ref.read(profileControllerProvider.notifier).loadProfile(
						user: user,
					);
				},
				child: SingleChildScrollView(
					physics: const AlwaysScrollableScrollPhysics(),
					padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
					child: Column(
						children: [
							_ProfileHeader(
								user: user,
								persona: profileState.persona,
								roles: profileState.roles,
								primaryRole: profileState.primaryRole,
								verified: profileState.correoVerificado ||
									profileState.telefonoVerificado,
								avatarUrl: profileState.avatarUrl,
								loading: profileState.loading,
							),
							if (profileState.error != null)
								Card(
									margin: const EdgeInsets.only(top: 12),
									color: Colors.red.shade50,
									child: Padding(
										padding: const EdgeInsets.all(12),
										child: Text(
											profileState.error!,
											style: TextStyle(color: Colors.red.shade700),
										),
									),
								),
							const SizedBox(height: 16),
							_ImageSection(onChange: () => _showChangeAvatar(context)),
							const SizedBox(height: 12),
							_InfoSection(persona: profileState.persona, user: user),
							const SizedBox(height: 12),
							_ClientSection(persona: profileState.persona, user: user),
							const SizedBox(height: 12),
							_OwnerSection(
								roles: profileState.roles,
								loading: profileState.loading,
							),
							const SizedBox(height: 12),
							_ControllerSection(
								isActive: profileState.roles.contains('CONTROLADOR'),
							),
							const SizedBox(height: 12),
							_SecuritySection(
								user: user,
								currentCtrl: _currentPassCtrl,
								newCtrl: _newPassCtrl,
								confirmCtrl: _confirmPassCtrl,
								onChangePassword: () => _changePassword(context, ref),
							),
							const SizedBox(height: 16),
							_DangerZone(
								deleteConfirmCtrl: _deleteConfirmCtrl,
								deletePasswordCtrl: _deletePasswordCtrl,
								onExport: () => _pending(context),
								onDeactivate: () => _pending(context),
								onDelete: () => _pending(context),
							),
							const SizedBox(height: 20),
							GradientButton(
								onPressed: () async {
									await ref.read(authProvider.notifier).logout();
									if (context.mounted) {
										Navigator.pushReplacementNamed(
											context,
											LoginScreen.routeName,
										);
									}
								},
								padding: const EdgeInsets.symmetric(vertical: 14),
								child: const Text('Cerrar sesión'),
							),
						],
					),
				),
			),
		);
	}

	void _changePassword(BuildContext context, WidgetRef ref) async {
		final current = _currentPassCtrl.text.trim();
		final newPwd = _newPassCtrl.text.trim();
		final confirm = _confirmPassCtrl.text.trim();
		final user = ref.read(authProvider).user;

		if (user == null) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Usuario no disponible')),
			);
			return;
		}
		if (newPwd.length < 8) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(
					content: Text('La nueva contraseña debe tener al menos 8 caracteres'),
				),
			);
			return;
		}
		if (newPwd != confirm) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Las contraseñas no coinciden')),
			);
			return;
		}

		try {
			final repo = ref.read(profileRepositoryProvider);
			await repo.changePasswordWithCurrent(
				userEmail: user.email,
				currentPassword: current,
				userId: user.id,
				newPassword: newPwd,
			);
			if (!context.mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Contraseña cambiada')),
			);
			_currentPassCtrl.clear();
			_newPassCtrl.clear();
			_confirmPassCtrl.clear();
		} catch (e) {
			if (!context.mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Error: $e')),
			);
		}
	}

	void _showChangeAvatar(BuildContext context) {
		showDialog(
			context: context,
			builder: (ctx) => AlertDialog(
				title: const Text('Cambiar foto de perfil'),
				content: const Text(
					'Funcionalidad pendiente: seleccionar imagen y subir al servidor.',
				),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(ctx),
						child: const Text('Cerrar'),
					),
				],
			),
		);
	}

	void _pending(BuildContext context) {
		ScaffoldMessenger.of(context).showSnackBar(
			const SnackBar(content: Text('Funcionalidad en desarrollo')),
		);
	}
}

class _ProfileHeader extends StatelessWidget {
	const _ProfileHeader({
		required this.user,
		required this.persona,
		required this.roles,
		required this.primaryRole,
		required this.verified,
		required this.avatarUrl,
		required this.loading,
	});

	final User user;
	final Persona? persona;
	final List<String> roles;
	final String primaryRole;
	final bool verified;
	final String? avatarUrl;
	final bool loading;

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		final name = _fullName(persona, user);
		final initials = name.isNotEmpty
			? name.trim().characters.first
			: user.username.characters.first;

		return Container(
			width: double.infinity,
			decoration: BoxDecoration(
				gradient: LinearGradient(
					colors: [
						AppColors.primary500.withOpacity(.18),
						AppColors.primary300.withOpacity(.14),
						AppColors.primary100.withOpacity(.10),
					],
					begin: Alignment.topLeft,
					end: Alignment.bottomRight,
				),
				borderRadius: BorderRadius.circular(18),
			),
			padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
			child: Column(
				children: [
					CircleAvatar(
						radius: 42,
						backgroundColor: AppColors.primary500,
						backgroundImage:
							(avatarUrl != null && avatarUrl!.isNotEmpty)
								? NetworkImage(avatarUrl!)
								: null,
						child: (avatarUrl == null || avatarUrl!.isEmpty)
							? Text(
								initials,
								style: const TextStyle(
									color: Colors.white,
									fontSize: 22,
									fontWeight: FontWeight.w700,
								),
							)
							: null,
					),
					const SizedBox(height: 12),
					Text(
						name,
						style: theme.textTheme.titleLarge?.copyWith(
							fontWeight: FontWeight.w700,
						),
					),
					const SizedBox(height: 4),
					Text('@${user.username}', style: theme.textTheme.bodyMedium),
					const SizedBox(height: 10),
					Wrap(
						spacing: 8,
						runSpacing: 8,
						alignment: WrapAlignment.center,
						children: [
							_Badge(
								label: verified ? 'Verificado' : 'Verificación pendiente',
								icon: verified ? Icons.verified : Icons.verified_outlined,
								color: verified ? AppColors.primary600 : AppColors.neutral500,
							),
							...roles.map(
								(r) => _Badge(
									label: r,
									icon: _roleIcon(r),
								),
							),
						],
					),
					const SizedBox(height: 14),
					Wrap(
						spacing: 10,
						runSpacing: 10,
						alignment: WrapAlignment.center,
						children: [
							_InfoPill(
								label: 'Rol principal',
								value: primaryRole,
							),
							_InfoPill(
								label: 'Registro',
								value: _fecha(persona?.creadoEn),
							),
							_InfoPill(
								label: 'Estado',
								value: verified ? 'Verificado' : 'Pendiente',
							),
						],
					),
					if (loading)
						const Padding(
							padding: EdgeInsets.only(top: 12),
							child: CircularProgressIndicator(),
						),
				],
			),
		);
	}

	String _fullName(Persona? p, User user) {
		final parts = [
			p?.nombres ?? '',
			p?.paterno ?? '',
			p?.materno ?? '',
		].where((e) => e.trim().isNotEmpty).join(' ');
		if (parts.isNotEmpty) return parts;
		return user.username;
	}
}

class _ImageSection extends StatelessWidget {
	const _ImageSection({required this.onChange});

	final VoidCallback onChange;

	@override
	Widget build(BuildContext context) {
		return _SectionCard(
			title: 'Imagen de perfil',
			child: Row(
				children: [
					const CircleAvatar(
						radius: 26,
						backgroundColor: AppColors.primary100,
						child: Icon(Icons.photo_camera, color: AppColors.primary600),
					),
					const SizedBox(width: 12),
					Expanded(
						child: Text(
							'Recomendación: imagen cuadrada, buena iluminación y fondo neutro.',
							style: Theme.of(context).textTheme.bodyMedium,
						),
					),
					const SizedBox(width: 8),
					TextButton.icon(
						onPressed: onChange,
						icon: const Icon(Icons.edit),
						label: const Text('Cambiar foto'),
					),
				],
			),
		);
	}
}

class _InfoSection extends StatelessWidget {
	const _InfoSection({required this.persona, required this.user});

	final Persona? persona;
	final User user;

	@override
	Widget build(BuildContext context) {
		final List<_DetailItem> items = [
			_DetailItem('Documento', _doc(persona)),
			_DetailItem('Nombres', persona?.nombres ?? '-'),
			_DetailItem(
				'Apellidos',
				[(persona?.paterno ?? ''), (persona?.materno ?? '')]
					.where((e) => e.trim().isNotEmpty)
					.join(' ')
					.ifEmpty('-'),
			),
			_DetailItem('Teléfono', persona?.telefono ?? 'No disponible'),
			_DetailItem('País / Ciudad', 'No disponible'),
			_DetailItem('Dirección', 'No disponible'),
			_DetailItem('Biografía', 'No disponible'),
			_DetailItem('Deportes favoritos', 'No especificado'),
		];
		return _SectionCard(
			title: 'Información personal',
			child: _DetailGrid(items: items),
		);
	}
}

class _ClientSection extends StatelessWidget {
	const _ClientSection({required this.persona, required this.user});

	final Persona? persona;
	final User user;

	@override
	Widget build(BuildContext context) {
		return _SectionCard(
			title: 'Perfil como cliente',
			child: _DetailGrid(
				items: [
					_DetailItem('Apodo deportivo', '@${user.username}'),
					_DetailItem('Nivel', 'Aficionado'),
					_DetailItem('Observaciones', 'No hay observaciones registradas'),
				],
			),
		);
	}
}

class _OwnerSection extends StatelessWidget {
	const _OwnerSection({required this.roles, required this.loading});

	final List<String> roles;
	final bool loading;

	@override
	Widget build(BuildContext context) {
		final bool isOwner = roles.contains('DUENIO');
		return _SectionCard(
			title: 'Perfil como dueño',
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					_DetailGrid(
						items: [
							_DetailItem(
								'Estado de verificación',
								isOwner ? 'Verificado' : 'No registrado',
							),
							_DetailItem('Última verificación', '-'),
							_DetailItem(
								'Resumen',
								isOwner
									? 'Tu perfil de dueño está activo.'
									: 'Solicita verificación para gestionar sedes.',
							),
						],
					),
					if (!isOwner && !loading)
						Align(
							alignment: Alignment.centerRight,
							child: TextButton.icon(
								onPressed: () {
									ScaffoldMessenger.of(context).showSnackBar(
										const SnackBar(
											content: Text('Solicitud de dueño pendiente en backend'),
										),
									);
								},
								icon: const Icon(Icons.workspace_premium),
								label: const Text('Solicitar verificación'),
							),
						),
				],
			),
		);
	}
}

class _ControllerSection extends StatelessWidget {
	const _ControllerSection({required this.isActive});

	final bool isActive;

	@override
	Widget build(BuildContext context) {
		return _SectionCard(
			title: 'Perfil como controlador',
			child: _DetailGrid(
				items: [
					const _DetailItem('Código de empleado', 'No asignado'),
					const _DetailItem('Turno', 'No asignado'),
					_DetailItem('Estado', isActive ? 'Activo' : 'No disponible'),
				],
			),
		);
	}
}

class _SecuritySection extends StatelessWidget {
	const _SecuritySection({
		required this.user,
		required this.currentCtrl,
		required this.newCtrl,
		required this.confirmCtrl,
		required this.onChangePassword,
	});

	final User user;
	final TextEditingController currentCtrl;
	final TextEditingController newCtrl;
	final TextEditingController confirmCtrl;
	final VoidCallback onChangePassword;

	@override
	Widget build(BuildContext context) {
		return _SectionCard(
			title: 'Cuenta y seguridad',
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					_DetailGrid(
						items: [
							_DetailItem('Email', user.email),
							_DetailItem('Usuario', '@${user.username}'),
						],
					),
					const SizedBox(height: 12),
					Text('Cambiar contraseña', style: Theme.of(context).textTheme.titleSmall),
					const SizedBox(height: 8),
					TextField(
						controller: currentCtrl,
						obscureText: true,
						decoration: const InputDecoration(
							labelText: 'Contraseña actual',
							border: OutlineInputBorder(),
						),
					),
					const SizedBox(height: 10),
					TextField(
						controller: newCtrl,
						obscureText: true,
						decoration: const InputDecoration(
							labelText: 'Nueva contraseña',
							border: OutlineInputBorder(),
						),
					),
					const SizedBox(height: 10),
					TextField(
						controller: confirmCtrl,
						obscureText: true,
						decoration: const InputDecoration(
							labelText: 'Confirmar contraseña',
							border: OutlineInputBorder(),
						),
					),
					const SizedBox(height: 10),
					Align(
						alignment: Alignment.centerRight,
						child: ElevatedButton.icon(
							onPressed: onChangePassword,
							icon: const Icon(Icons.lock_reset),
							label: const Text('Guardar cambios'),
						),
					),
				],
			),
		);
	}
}

class _DangerZone extends StatelessWidget {
	const _DangerZone({
		required this.deleteConfirmCtrl,
		required this.deletePasswordCtrl,
		required this.onExport,
		required this.onDeactivate,
		required this.onDelete,
	});

	final TextEditingController deleteConfirmCtrl;
	final TextEditingController deletePasswordCtrl;
	final VoidCallback onExport;
	final VoidCallback onDeactivate;
	final VoidCallback onDelete;

	@override
	Widget build(BuildContext context) {
		return Container(
			width: double.infinity,
			decoration: BoxDecoration(
				color: Colors.red.shade50,
				borderRadius: BorderRadius.circular(14),
				border: Border.all(color: Colors.red.shade100),
			),
			padding: const EdgeInsets.all(16),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(
						'Zona de peligro',
						style: Theme.of(context).textTheme.titleMedium?.copyWith(
							color: Colors.red.shade700,
							fontWeight: FontWeight.w700,
						),
					),
					const SizedBox(height: 12),
					Wrap(
						spacing: 8,
						runSpacing: 8,
						children: [
							OutlinedButton.icon(
								onPressed: onExport,
								icon: const Icon(Icons.download),
								label: const Text('Exportar mis datos'),
							),
							OutlinedButton.icon(
								onPressed: onDeactivate,
								icon: const Icon(Icons.pause_circle_filled),
								label: const Text('Desactivar cuenta'),
							),
						],
					),
					const SizedBox(height: 12),
					TextField(
						controller: deletePasswordCtrl,
						obscureText: true,
						decoration: const InputDecoration(
							labelText: 'Contraseña actual',
							border: OutlineInputBorder(),
						),
					),
					const SizedBox(height: 10),
					TextField(
						controller: deleteConfirmCtrl,
						decoration: const InputDecoration(
							labelText: 'ESCRIBE ELIMINAR PARA CONFIRMAR',
							border: OutlineInputBorder(),
						),
					),
					const SizedBox(height: 12),
					Align(
						alignment: Alignment.centerRight,
						child: ElevatedButton.icon(
							style: ElevatedButton.styleFrom(
								backgroundColor: Colors.red.shade600,
							),
							onPressed: onDelete,
							icon: const Icon(Icons.delete_forever),
							label: const Text('Eliminar cuenta'),
						),
					),
				],
			),
		);
	}
}

class _SectionCard extends StatelessWidget {
	const _SectionCard({required this.title, required this.child});

	final String title;
	final Widget child;

	@override
	Widget build(BuildContext context) {
		return Card(
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
			child: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Text(
							title,
							style: Theme.of(context).textTheme.titleMedium?.copyWith(
								fontWeight: FontWeight.w700,
							),
						),
						const SizedBox(height: 10),
						child,
					],
				),
			),
		);
	}
}

class _DetailGrid extends StatelessWidget {
	const _DetailGrid({required this.items});

	final List<_DetailItem> items;

	@override
	Widget build(BuildContext context) {
		return Wrap(
			spacing: 12,
			runSpacing: 12,
			children: items
				.map(
					(item) => SizedBox(
						width: MediaQuery.of(context).size.width > 520
							? (MediaQuery.of(context).size.width - 72) / 2
							: double.infinity,
						child: _DetailTile(item: item),
					),
				)
				.toList(),
		);
	}
}

class _DetailItem {
	const _DetailItem(this.label, this.value);
	final String label;
	final String value;
}

class _DetailTile extends StatelessWidget {
	const _DetailTile({required this.item});
	final _DetailItem item;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(12),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(10),
				border: Border.all(color: AppColors.neutral200),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(
						item.label,
						style: Theme.of(context).textTheme.bodySmall?.copyWith(
							color: AppColors.neutral500,
						),
					),
					const SizedBox(height: 4),
					Text(
						item.value.ifEmpty('-'),
						style: const TextStyle(
							fontWeight: FontWeight.w600,
							color: AppColors.neutral700,
						),
					),
				],
			),
		);
	}
}

IconData _roleIcon(String role) {
	final normalized = role.trim().toUpperCase();
	switch (normalized) {
		case 'DUENIO':
		case 'DUENO':
		case 'OWNER':
			return Icons.workspace_premium;
		case 'CONTROLADOR':
			return Icons.qr_code_scanner;
		case 'ADMIN':
			return Icons.shield_moon;
		default:
			return Icons.sports_soccer;
	}
}

class _Badge extends StatelessWidget {
	const _Badge({
		required this.label,
		required this.icon,
		this.color,
	});

	final String label;
	final IconData icon;
	final Color? color;

	@override
	Widget build(BuildContext context) {
		final Color bg = color ?? AppColors.primary500;
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
			decoration: BoxDecoration(
				color: bg,
				borderRadius: BorderRadius.circular(20),
			),
			child: Row(
				mainAxisSize: MainAxisSize.min,
				children: [
					Icon(icon, size: 16, color: Colors.white),
					const SizedBox(width: 6),
					Text(
						label,
						style: TextStyle(
							color: Colors.white,
							fontWeight: FontWeight.w600,
						),
					),
				],
			),
		);
	}
}

class _InfoPill extends StatelessWidget {
	const _InfoPill({required this.label, required this.value});
	final String label;
	final String value;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(12),
				border: Border.all(color: AppColors.neutral200),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(
						label,
						style: Theme.of(context).textTheme.bodySmall?.copyWith(
							color: AppColors.neutral500,
						),
					),
					const SizedBox(height: 2),
					Text(
						value.ifEmpty('-'),
						style: const TextStyle(
							fontWeight: FontWeight.w700,
						),
					),
				],
			),
		);
	}
}

String _doc(Persona? p) {
	if (p == null) return '-';
	final tipo = p.documentoTipo;
	final num = p.documentoNumero;
	if ((tipo == null || tipo.isEmpty) && (num == null || num.isEmpty)) {
		return '-';
	}
	return [tipo, num].where((e) => e != null && e.isNotEmpty).join(' ');
}

String _fecha(DateTime? dt) {
	if (dt == null) return '-';
	return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

extension _StrX on String {
	String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}

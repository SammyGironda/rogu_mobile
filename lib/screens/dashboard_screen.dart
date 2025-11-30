import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/gallery_section.dart';
import '../widgets/footer_rogu.dart';
import '../widgets/gradient_button.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
	static const String routeName = '/dashboard';

	const DashboardScreen({super.key});

	@override
	State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
	// Navigation handled by BottomNavBar (shared widget)
	String _query = '';
	String? _venue;
	String? _location;
	// Removed sport dropdown from dashboard filters; sport chips exist in gallery
	RangeValues _playersRange = const RangeValues(2, 14);

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
			final bool isDark = theme.brightness == Brightness.dark;
			final Color iconColor = isDark ? Colors.white : AppColors.neutral700;
		return Scaffold(
						appBar: AppBar(
								titleSpacing: 0,
								title: Padding(
									padding: const EdgeInsets.symmetric(horizontal: 12),
									child: Row(
										children: [
											Container(
												padding: const EdgeInsets.all(8),
												decoration: BoxDecoration(
													gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF06B6D4)]),
													borderRadius: BorderRadius.circular(12),
												),
												child: const Icon(Icons.emoji_events, color: Colors.white),
											),
											const SizedBox(width: 10),
											Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: const [
													Text('ROGÜ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
													Text('Reserva tu cancha favorita', style: TextStyle(fontSize: 11, color: Colors.grey)),
												],
											),
											const Spacer(),
																						GradientButton(
																								onPressed: () => Navigator.pushNamed(context, LoginScreen.routeName),
																								padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
																								child: Row(
																									mainAxisSize: MainAxisSize.min,
																									children: const [
																										Icon(Icons.lock_open, color: Colors.white),
																										SizedBox(width: 8),
																										Text('Iniciar sesión'),
																									],
																								),
																						),
											const SizedBox(width: 8),
										],
									),
								),
								leading: Builder(builder: (ctx) {
										return IconButton(
														icon: Icon(Icons.menu, color: iconColor),
												onPressed: () => Scaffold.of(ctx).openDrawer(),
										);
								}),
								actions: [
												IconButton(icon: Icon(Icons.qr_code, color: iconColor), onPressed: () => Navigator.pushNamed(context, '/qr')),
												IconButton(icon: Icon(Icons.person, color: iconColor), onPressed: () => Navigator.pushNamed(context, '/profile')),
								],
						),
			drawer: Drawer(
				child: ListView(
					padding: EdgeInsets.zero,
					children: [
						DrawerHeader(
							decoration: BoxDecoration(color: AppColors.primary500),
							child: Text('ROGU', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white)),
						),
							ListTile(leading: Icon(Icons.dashboard, color: iconColor), title: const Text('Dashboard'), onTap: () => Navigator.pushReplacementNamed(context, DashboardScreen.routeName)),
							ListTile(leading: Icon(Icons.history, color: iconColor), title: const Text('Historial'), onTap: () => Navigator.pushNamed(context, '/booking_history')),
							ListTile(leading: Icon(Icons.event_available, color: iconColor), title: const Text('Gestión de reservas'), onTap: () => Navigator.pushNamed(context, '/new-reservation')),
						const Divider(),
							ListTile(leading: Icon(Icons.settings, color: iconColor), title: const Text('Configuración'), onTap: () {}),
					],
				),
			),
			body: SingleChildScrollView(
				padding: const EdgeInsets.all(12),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
												// Removed upper search bar per request
												const SizedBox(height: 16),
						const SizedBox(height: 20),
												// Barra de búsqueda + filtros
						TextField(
							decoration: InputDecoration(
								prefixIcon: const Icon(Icons.search),
								labelText: 'Buscar por sede o deporte',
								border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
							),
							onChanged: (v) {
								setState(() {
									_query = v;
								});
							},
						),
												const SizedBox(height: 12),
												Wrap(
														spacing: 10,
														runSpacing: 10,
														children: [
																SizedBox(
																	width: 160,
																	child: DropdownButtonFormField<String>(
																		value: _venue,
																		decoration: const InputDecoration(labelText: 'Sede'),
																		items: const [
																			DropdownMenuItem(value: 'Sede Principal', child: Text('Sede Principal')),
																			DropdownMenuItem(value: 'Sede Norte', child: Text('Sede Norte')),
																			DropdownMenuItem(value: 'Sede Centro', child: Text('Sede Centro')),
																			DropdownMenuItem(value: 'Sede Elite', child: Text('Sede Elite')),
																			DropdownMenuItem(value: 'Sede Indoor', child: Text('Sede Indoor')),
																			DropdownMenuItem(value: 'Sede Rooftop', child: Text('Sede Rooftop')),
																		],
																		onChanged: (v) => setState(() => _venue = v),
																	),
																),
																SizedBox(
																	width: 140,
																	child: DropdownButtonFormField<String>(
																		value: _location,
																		decoration: const InputDecoration(labelText: 'Ubicación'),
																		items: const [
																			DropdownMenuItem(value: 'Centro', child: Text('Centro')),
																			DropdownMenuItem(value: 'Norte', child: Text('Norte')),
																			DropdownMenuItem(value: 'Sur', child: Text('Sur')),
																		],
																		onChanged: (v) => setState(() => _location = v),
																	),
																),
																// Removed sport filter here; it's handled below
																SizedBox(
																	width: 220,
																	child: Column(
																		crossAxisAlignment: CrossAxisAlignment.start,
																		children: [
																			const Text('Jugadores'),
																			RangeSlider(
																				values: _playersRange,
																				min: 2,
																				max: 14,
																				divisions: 6,
																				labels: RangeLabels(
																					_playersRange.start.round().toString(),
																					_playersRange.end.round().toString(),
																				),
																				onChanged: (v) => setState(() => _playersRange = v),
																			),
																		],
																	),
																),
															],
												),
						const SizedBox(height: 20),
						// Gallery Section
												GallerySection(
													filterText: _query,
													venue: _venue,
													location: _location,
													sport: null,
													minPlayers: _playersRange.start.round(),
													maxPlayers: _playersRange.end.round(),
												),
						const SizedBox(height: 32),
						// Footer brand block
						const ROGUFooter(),
					],
				),
			),
									bottomNavigationBar: const BottomNavBar(),
		);
	}
}

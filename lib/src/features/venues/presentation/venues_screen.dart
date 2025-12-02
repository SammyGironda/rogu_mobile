import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/venue.dart';
import '../application/venues_controller.dart';
import 'widgets/venue_card.dart';
import '../../../presentation/screens/auth/login_screen.dart';
import '../../../presentation/state/providers.dart';
import '../../../presentation/widgets/app_drawer.dart';
import '../../../presentation/widgets/bottom_nav.dart';

class VenuesScreen extends ConsumerStatefulWidget {
	static const String routeName = '/venues';

	const VenuesScreen({super.key});

	@override
	ConsumerState<VenuesScreen> createState() => _VenuesScreenState();
}

class _VenuesScreenState extends ConsumerState<VenuesScreen> {
	@override
	void initState() {
		super.initState();
		Future.microtask(() {
			final snapshot = ref.read(venuesControllerProvider);
			if (snapshot.venues.isEmpty && !snapshot.loadingList) {
				ref.read(venuesControllerProvider.notifier).loadVenues();
			}
		});
	}

	@override
	Widget build(BuildContext context) {
		final state = ref.watch(venuesControllerProvider);
		final controller = ref.read(venuesControllerProvider.notifier);
		final theme = Theme.of(context);
		final isDark = theme.brightness == Brightness.dark;

		return Scaffold(
			appBar: AppBar(
				title: const Text('Sedes deportivas'),
				leading: Builder(
					builder: (ctx) {
						final Color iconColor =
							isDark ? Colors.white : AppColors.neutral700;
						return IconButton(
							icon: Icon(Icons.menu, color: iconColor),
							onPressed: () => Scaffold.of(ctx).openDrawer(),
						);
					},
				),
				actions: const [
					_AuthAction(),
					SizedBox(width: 8),
				],
			),
			drawer: const AppDrawer(),
			bottomNavigationBar: const BottomNavBar(),
			body: RefreshIndicator(
				onRefresh: () => controller.loadVenues(),
				child: ListView(
					physics: const AlwaysScrollableScrollPhysics(),
					padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
					children: [
						Text(
							'Explora las sedes y sus canchas',
							style: theme.textTheme.headlineSmall,
						),
						const SizedBox(height: 6),
						Text(
							'Consulta ubicacion, contacto y disponibilidad antes de reservar.',
							style: theme.textTheme.bodyMedium,
						),
						const SizedBox(height: 16),
						_VenueList(state: state, controller: controller),
					],
				),
			),
		);
	}
}

class VenuesPreviewSection extends ConsumerStatefulWidget {
	const VenuesPreviewSection({super.key});

	@override
	ConsumerState<VenuesPreviewSection> createState() =>
		_VenuesPreviewSectionState();
}

class _VenuesPreviewSectionState
	extends ConsumerState<VenuesPreviewSection> {
	@override
	void initState() {
		super.initState();
		Future.microtask(() {
			final snapshot = ref.read(venuesControllerProvider);
			if (snapshot.venues.isEmpty && !snapshot.loadingList) {
				ref.read(venuesControllerProvider.notifier).loadVenues();
			}
		});
	}

	@override
	Widget build(BuildContext context) {
		final state = ref.watch(venuesControllerProvider);
		final controller = ref.read(venuesControllerProvider.notifier);
		final theme = Theme.of(context);
		final List<Venue> previewVenues =
			state.venues.take(4).toList(growable: false);

		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Row(
					mainAxisAlignment: MainAxisAlignment.spaceBetween,
					children: [
						Text('Sedes', style: theme.textTheme.titleLarge),
						TextButton(
							onPressed: () =>
								Navigator.pushNamed(context, VenuesScreen.routeName),
							child: const Text('Ver todas'),
						),
					],
				),
				const SizedBox(height: 10),
				if (state.error != null)
					_StatusCard(
						color: Colors.red.shade50,
						child: Text(
							state.error!,
							style: TextStyle(color: Colors.red.shade700),
						),
					)
				else if (state.loadingList && state.venues.isEmpty)
					const Padding(
						padding: EdgeInsets.symmetric(vertical: 28),
						child: Center(child: CircularProgressIndicator()),
					)
				else if (previewVenues.isEmpty)
					const Padding(
						padding: EdgeInsets.symmetric(vertical: 20),
						child: Text('No hay sedes disponibles.'),
					)
				else
					Column(
						children: previewVenues
							.map(
								(v) => VenueCard(
									venue: v,
									fields: state.fieldsByVenue[v.id] ?? const [],
									expanded: state.expandedVenueId == v.id,
									loadingFields: state.loadingFieldsFor == v.id,
									onToggle: () => controller.toggleExpanded(v.id),
								),
							)
							.toList(),
					),
				if (state.venues.length > 4)
					Padding(
						padding: const EdgeInsets.only(top: 6),
						child: Align(
							alignment: Alignment.center,
							child: OutlinedButton.icon(
								style: OutlinedButton.styleFrom(
									padding: const EdgeInsets.symmetric(
										horizontal: 18,
										vertical: 12,
									),
								),
								onPressed: () =>
									Navigator.pushNamed(context, VenuesScreen.routeName),
								icon: const Icon(Icons.list_alt),
								label: const Text('Ver todas'),
							),
						),
					),
			],
		);
	}
}

class _VenueList extends StatelessWidget {
	const _VenueList({
		required this.state,
		required this.controller,
	});

	final VenuesState state;
	final VenuesController controller;

	@override
	Widget build(BuildContext context) {
		if (state.error != null) {
			return _StatusCard(
				color: Colors.red.shade50,
				child: Text(
					state.error!,
					style: TextStyle(color: Colors.red.shade700),
				),
			);
		}
		if (state.loadingList && state.venues.isEmpty) {
			return const Padding(
				padding: EdgeInsets.symmetric(vertical: 40),
				child: Center(child: CircularProgressIndicator()),
			);
		}
		if (state.venues.isEmpty) {
			return const Padding(
				padding: EdgeInsets.symmetric(vertical: 40),
				child: Center(child: Text('No hay sedes disponibles.')),
			);
		}
		return ListView.separated(
			shrinkWrap: true,
			physics: const NeverScrollableScrollPhysics(),
			itemCount: state.venues.length,
			separatorBuilder: (_, __) => const SizedBox(height: 12),
			itemBuilder: (context, index) {
				final v = state.venues[index];
				return VenueCard(
					venue: v,
					fields: state.fieldsByVenue[v.id] ?? const [],
					expanded: state.expandedVenueId == v.id,
					loadingFields: state.loadingFieldsFor == v.id,
					onToggle: () => controller.toggleExpanded(v.id),
				);
			},
		);
	}
}

class _StatusCard extends StatelessWidget {
	const _StatusCard({required this.child, this.color});

	final Widget child;
	final Color? color;

	@override
	Widget build(BuildContext context) {
		return Card(
			color: color,
			child: Padding(
				padding: const EdgeInsets.all(12),
				child: child,
			),
		);
	}
}

class _AuthAction extends ConsumerWidget {
	const _AuthAction();

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		final auth = ref.watch(authProvider);
		if (auth.isAuthenticated && auth.user != null) {
			final username = auth.user!.username;
			final String initials =
				username.isNotEmpty ? username.characters.first : '?';
			return Padding(
				padding: const EdgeInsets.only(right: 8),
				child: InkWell(
					onTap: () => Navigator.pushNamed(context, '/profile'),
					borderRadius: BorderRadius.circular(18),
					child: Row(
						mainAxisSize: MainAxisSize.min,
						children: [
							CircleAvatar(
								radius: 16,
								child: Text(initials),
							),
							const SizedBox(width: 8),
							ConstrainedBox(
								constraints: const BoxConstraints(maxWidth: 140),
								child: Text(
									username,
									overflow: TextOverflow.ellipsis,
									style: const TextStyle(
										fontWeight: FontWeight.w600,
									),
								),
							),
						],
					),
				),
			);
		}
		return Padding(
			padding: const EdgeInsets.only(right: 8),
			child: TextButton.icon(
				style: TextButton.styleFrom(
					padding: const EdgeInsets.symmetric(
						horizontal: 12,
						vertical: 8,
					),
				),
				onPressed: () =>
					Navigator.pushNamed(context, LoginScreen.routeName),
				icon: const Icon(Icons.lock_open),
				label: const Text('Login'),
			),
		);
	}
}

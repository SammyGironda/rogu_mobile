import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/reservations/application/booking_form_controller.dart';
import '../../../features/reservations/models/booking_draft.dart';
import '../../../data/models/field.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/venue.dart';
import '../../../data/repositories/reservations_repository.dart' as res_repo;
import '../../widgets/time_slot_chip.dart';
import 'booking_confirm_screen.dart';

typedef ReservationSlot = res_repo.ReservationSlot;

class BookingFormScreen extends ConsumerStatefulWidget {
	static const String routeName = '/booking_form';

	const BookingFormScreen({super.key});

	@override
	ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
	final PageController _pageController = PageController();

	@override
	void dispose() {
		_pageController.dispose();
		super.dispose();
	}

	Widget _buildPlayers(
		BookingFormState state,
		BookingFormController controller,
		ThemeData theme,
	) {
		const int minPlayers = 1;
		final int maxPlayers = state.maxPlayers > 0 ? state.maxPlayers : 10;
		return Card(
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
			elevation: 2,
			child: Padding(
				padding: const EdgeInsets.all(14),
				child: Row(
					mainAxisAlignment: MainAxisAlignment.spaceBetween,
					children: [
						Text('Jugadores', style: theme.textTheme.titleMedium),
						Row(
							children: [
								IconButton(
									onPressed: state.players > minPlayers
											? () => controller.setPlayers(state.players - 1)
											: null,
									icon: const Icon(Icons.remove),
								),
								Text(
									state.players.toString(),
									style: theme.textTheme.titleMedium,
								),
								IconButton(
									onPressed: state.players < maxPlayers
											? () => controller.setPlayers(state.players + 1)
											: () {
												ScaffoldMessenger.of(context).showSnackBar(
													SnackBar(
														content: Text(
															'Esta cancha permite maximo $maxPlayers jugadores.',
														),
													),
												);
											},
									icon: const Icon(Icons.add),
								),
							],
						),
					],
				),
			),
		);
	}

	@override
	void initState() {
		super.initState();
		Future.microtask(
			() {
				final args = ModalRoute.of(context)?.settings.arguments;
				final Map<String, dynamic>? map =
					args is Map<String, dynamic> ? args : null;
				final int? venueId = map != null ? map['venueId'] as int? : null;
				final int? fieldId = map != null ? map['fieldId'] as int? : null;
				ref
					.read(bookingFormControllerProvider.notifier)
					.init(initialVenueId: venueId, initialFieldId: fieldId);
			},
		);
	}

	@override
	Widget build(BuildContext context) {
		final state = ref.watch(bookingFormControllerProvider);
		final controller = ref.read(bookingFormControllerProvider.notifier);
		final theme = Theme.of(context);
		final isDark = theme.brightness == Brightness.dark;
		final field = _selectedField(state);
		Venue? venue;
		if (state.selectedVenueId != null) {
			for (final v in state.venues) {
				if (v.id == state.selectedVenueId) {
					venue = v;
					break;
				}
			}
		}
		venue ??= state.venues.isNotEmpty ? state.venues.first : null;
		final venueName = venue?.nombre;

		return Scaffold(
			appBar: AppBar(
				title: const Text('Nueva reserva'),
				leading: IconButton(
					icon: const Icon(Icons.arrow_back),
					onPressed: () => Navigator.pop(context),
				),
			),
			body: RefreshIndicator(
				onRefresh: () => controller.refresh(),
				child: ListView(
					padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
					physics: const AlwaysScrollableScrollPhysics(),
					children: [
						if (field != null) ...[
							_FieldCarousel(field: field, pageController: _pageController),
							const SizedBox(height: 12),
							Text(
								field.nombre,
								style: theme.textTheme.headlineSmall,
							),
							if (venueName != null)
								Padding(
									padding: const EdgeInsets.only(top: 4),
									child: Text(
										venueName,
										style: theme.textTheme.bodyMedium?.copyWith(
											color: AppColors.neutral600,
										),
									),
								),
						],
						const SizedBox(height: 16),
						if (state.error != null)
							Card(
								color: Colors.red.shade50,
								child: Padding(
									padding: const EdgeInsets.all(12),
									child: Text(
										state.error!,
										style: TextStyle(color: Colors.red.shade800),
									),
								),
							),
						const SizedBox(height: 12),
						_buildDatePicker(state, controller, theme, context),
						const SizedBox(height: 16),
						_buildSlots(state, controller, theme, isDark),
						const SizedBox(height: 16),
						_buildPlayers(state, controller, theme),
						const SizedBox(height: 16),
						_buildSummary(state, field, theme),
						const SizedBox(height: 16),
						_buildSubmit(state),
					],
				),
			),
		);
	}

	Widget _buildDatePicker(
		BookingFormState state,
		BookingFormController controller,
		ThemeData theme,
		BuildContext context,
	) {
		final displayDate = _formatDate(state.selectedDate);
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Text('Fecha', style: theme.textTheme.titleMedium),
				const SizedBox(height: 8),
				InkWell(
					onTap: () async {
						final now = DateTime.now();
						final picked = await showDatePicker(
							context: context,
							initialDate: state.selectedDate,
							firstDate: DateTime(now.year, now.month, now.day),
							lastDate: DateTime(now.year + 1),
						);
						if (picked != null) controller.changeDate(picked);
					},
					child: Container(
						padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
						decoration: BoxDecoration(
							color: AppColors.neutral50,
							borderRadius: BorderRadius.circular(12),
							border: Border.all(color: AppColors.neutral200),
						),
						child: Row(
							mainAxisAlignment: MainAxisAlignment.spaceBetween,
							children: [
								Text(displayDate),
								const Icon(Icons.calendar_today),
							],
						),
					),
				),
			],
		);
	}

	Widget _buildSlots(
		BookingFormState state,
		BookingFormController controller,
		ThemeData theme,
		bool isDark,
	) {
		if (state.loadingSlots) {
			return const Center(child: CircularProgressIndicator());
		}
		if (state.selectedFieldId == null) {
			return Card(
				color: isDark ? Colors.grey[850] : AppColors.neutral100,
				child: const Padding(
					padding: EdgeInsets.all(12),
					child: Text('Selecciona una cancha para ver horarios.'),
				),
			);
		}
		if (state.slots.isEmpty) {
			return Card(
				color: isDark ? Colors.grey[850] : AppColors.neutral100,
				child: const Padding(
					padding: EdgeInsets.all(12),
					child: Text('No hay horarios disponibles para esta fecha.'),
				),
			);
		}
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Text('Horarios disponibles', style: theme.textTheme.titleMedium),
				const SizedBox(height: 8),
				Wrap(
					spacing: 8,
					runSpacing: 10,
					children: state.slots.map((slot) {
						final disabled = slot.ocupado || _isPastSlot(state.selectedDate, slot);
						final selected = state.selectedSlots.any(
							(s) =>
								s.horaInicio == slot.horaInicio && s.horaFin == slot.horaFin,
						);
						return TimeSlotChip(
							label: _slotLabel(slot),
							selected: selected,
							disabled: disabled,
							onTap: () {
								final before = List<ReservationSlot>.from(
									state.selectedSlots,
								);
								controller.toggleSlot(slot);
								final after = ref
									.read(bookingFormControllerProvider)
									.selectedSlots;
								final bool invalid =
									after.length == 1 &&
									before.isNotEmpty &&
									!(after.first.horaInicio == before.last.horaFin);
								if (invalid) {
									ScaffoldMessenger.of(context).showSnackBar(
										const SnackBar(
											content: Text(
												'Solo puedes seleccionar horarios consecutivos',
											),
										),
									);
								}
							},
						);
					}).toList(),
				),
			],
		);
	}

	Widget _buildSummary(BookingFormState state, Field? field, ThemeData theme) {
		final slots = state.selectedSlots;
		final duration = slots.isNotEmpty ? _totalDuration(slots) : null;
		final double pricePerHour = field?.precio ?? 0;
		final double total = duration != null
				? pricePerHour * (duration.inMinutes / 60)
				: 0;
		return Card(
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
			elevation: 2,
			child: Padding(
				padding: const EdgeInsets.all(14),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Text('Resumen', style: theme.textTheme.titleMedium),
						const SizedBox(height: 8),
						_RowItem(label: 'Fecha', value: _formatDate(state.selectedDate)),
						_RowItem(label: 'Cancha', value: field?.nombre ?? '-'),
						if (slots.isNotEmpty)
							_RowItem(
								label: 'Horarios',
								value: slots.map(_slotLabel).join(', '),
							),
						_RowItem(label: 'Jugadores', value: state.players.toString()),
						const SizedBox(height: 10),
						Container(
							padding: const EdgeInsets.all(10),
							decoration: BoxDecoration(
								color: AppColors.primary50,
								borderRadius: BorderRadius.circular(10),
							),
							child: Row(
								mainAxisAlignment: MainAxisAlignment.spaceBetween,
								children: [
									const Text(
										'Total estimado',
										style: TextStyle(fontWeight: FontWeight.w600),
									),
									Text(
										pricePerHour == 0
												? '-'
												: 'Bs ${total.toStringAsFixed(2)}',
										style: const TextStyle(
											fontWeight: FontWeight.bold,
											fontSize: 16,
										),
									),
								],
							),
						),
						if (slots.isEmpty)
							Padding(
								padding: const EdgeInsets.only(top: 8),
								child: Text(
									'Selecciona un horario para continuar.',
									style: theme.textTheme.bodySmall?.copyWith(
										color: AppColors.neutral600,
									),
								),
							),
					],
				),
			),
		);
	}

	Widget _buildSubmit(BookingFormState state) {
		final bool disabled =
			state.submitting ||
			state.selectedFieldId == null ||
			state.selectedSlots.isEmpty ||
			state.players < 1;
		return ElevatedButton(
			onPressed: disabled ? null : () => _onSubmit(),
			style: ElevatedButton.styleFrom(
				padding: const EdgeInsets.symmetric(vertical: 16),
				shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
			),
			child: state.submitting
					? const SizedBox(
						height: 18,
						width: 18,
						child: CircularProgressIndicator(strokeWidth: 2),
					)
					: const Text('Confirmar reserva'),
		);
	}

	Future<void> _onSubmit() async {
		final currentState = ref.read(bookingFormControllerProvider);
		if (currentState.selectedFieldId == null ||
			currentState.selectedSlots.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(
					content: Text('Selecciona una cancha y un horario disponible.'),
				),
			);
			return;
		}
		if (currentState.players < 1) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Debes indicar al menos 1 jugador.')),
			);
			return;
		}

		final field = _selectedField(currentState);
		Venue? venue;
		if (currentState.selectedVenueId != null) {
			for (final v in currentState.venues) {
				if (v.id == currentState.selectedVenueId) {
					venue = v;
					break;
				}
			}
		}
		venue ??= currentState.venues.isNotEmpty ? currentState.venues.first : null;

		final slots = List<ReservationSlot>.from(currentState.selectedSlots)
			..sort((a, b) => a.horaInicio.compareTo(b.horaInicio));
		final duration = _totalDuration(slots);
		final pricePerHour = field?.precio ?? 0;
		final total = pricePerHour * (duration.inMinutes / 60);

		final draft = BookingDraft(
			reservationId: null,
			fieldId: currentState.selectedFieldId!,
			fieldName: field?.nombre ?? 'Cancha',
			fieldPhotos: field?.fotos ?? const [],
			venueId: currentState.selectedVenueId ?? 0,
			venueName: venue?.nombre ?? 'Sede',
			date: currentState.selectedDate,
			slots: slots
				.map(
					(s) => BookingSlot(
						startTime: s.horaInicio,
						endTime: s.horaFin,
					),
				)
				.toList(),
			players: currentState.players,
			totalAmount: total,
			description: null,
			currency: null,
			hostMessage: null,
		);

		if (!mounted) return;
		Navigator.pushNamed(
			context,
			BookingConfirmScreen.routeName,
			arguments: draft,
		);
	}

	String _formatDate(DateTime date) =>
			'${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

	String _slotLabel(ReservationSlot slot) =>
			'${slot.horaInicio.substring(0, 5)} - ${slot.horaFin.substring(0, 5)}';

	bool _isPastSlot(DateTime selectedDate, ReservationSlot slot) {
		final now = DateTime.now();
		final dateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
		final today = DateTime(now.year, now.month, now.day);
		if (dateOnly.isAfter(today)) return false;
		if (dateOnly.isBefore(today)) return true;

		final parts = slot.horaInicio.split(':');
		final slotDate = DateTime(
			selectedDate.year,
			selectedDate.month,
			selectedDate.day,
			int.tryParse(parts[0]) ?? 0,
			int.tryParse(parts[1]) ?? 0,
		);
		return slotDate.isBefore(now);
	}

	Field? _selectedField(BookingFormState state) {
		for (final f in state.fields) {
			if (f.id == state.selectedFieldId) {
				return f;
			}
		}
		return null;
	}

	Duration _slotDuration(ReservationSlot slot) {
		final startParts = slot.horaInicio.split(':');
		final endParts = slot.horaFin.split(':');
		final start = DateTime(
			0,
			1,
			1,
			int.tryParse(startParts[0]) ?? 0,
			int.tryParse(startParts[1]) ?? 0,
		);
		final end = DateTime(
			0,
			1,
			1,
			int.tryParse(endParts[0]) ?? 0,
			int.tryParse(endParts[1]) ?? 0,
		);
		return end.difference(start);
	}

	Duration _totalDuration(List<ReservationSlot> slots) {
		Duration total = Duration.zero;
		for (final s in slots) {
			total += _slotDuration(s);
		}
		return total;
	}
}

class _FieldCarousel extends StatelessWidget {
	const _FieldCarousel({
		required this.field,
		required this.pageController,
	});

	final Field field;
	final PageController pageController;

	@override
	Widget build(BuildContext context) {
		final photos = field.fotos;
		if (photos.isEmpty) {
			return Container(
				height: 200,
				decoration: BoxDecoration(
					color: AppColors.neutral200,
					borderRadius: BorderRadius.circular(16),
				),
				alignment: Alignment.center,
				child: const Text('Sin foto'),
			);
		}
		return SizedBox(
			height: 220,
			child: Stack(
				children: [
					PageView.builder(
						controller: pageController,
						itemCount: photos.length,
						itemBuilder: (_, index) {
							return ClipRRect(
								borderRadius: BorderRadius.circular(16),
								child: Image.network(
									photos[index],
									fit: BoxFit.cover,
									errorBuilder: (_, __, ___) => Container(
										color: AppColors.neutral200,
										alignment: Alignment.center,
										child: const Text('Sin foto'),
									),
								),
							);
						},
					),
					if (photos.length > 1)
						Positioned(
							bottom: 10,
							left: 0,
							right: 0,
							child: Row(
								mainAxisAlignment: MainAxisAlignment.center,
								children: List.generate(
									photos.length,
									(i) => AnimatedBuilder(
										animation: pageController,
										builder: (_, __) {
											double selected = 0;
											if (pageController.hasClients &&
												pageController.page != null) {
												selected = (pageController.page ?? 0) - i;
											}
											final isActive = selected.abs() < 0.5;
											return Container(
												width: isActive ? 10 : 8,
												height: isActive ? 10 : 8,
												margin: const EdgeInsets.symmetric(horizontal: 4),
												decoration: BoxDecoration(
													color: isActive
															? Colors.white
															: Colors.white70,
													shape: BoxShape.circle,
													boxShadow: [
														BoxShadow(
															color: Colors.black.withOpacity(0.2),
															blurRadius: 4,
														),
													],
												),
											);
										},
									),
								),
							),
						),
				],
			),
		);
	}
}

class _RowItem extends StatelessWidget {
	const _RowItem({required this.label, required this.value});

	final String label;
	final String value;

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.only(bottom: 6),
			child: Row(
				mainAxisAlignment: MainAxisAlignment.spaceBetween,
				children: [
					Text(label),
					Text(value),
				],
			),
		);
	}
}

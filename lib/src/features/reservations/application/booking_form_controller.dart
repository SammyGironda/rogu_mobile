import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/field.dart';
import '../../../data/models/venue.dart';
import '../../../data/repositories/venues_repository.dart';
import '../../../data/repositories/reservations_repository.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../presentation/state/providers.dart';

class BookingFormState {
	const BookingFormState({
		required this.venues,
		required this.fields,
		required this.slots,
		required this.selectedDate,
		this.selectedVenueId,
		this.selectedFieldId,
		this.selectedSlots = const [],
		this.players = 1,
		this.maxPlayers = 10,
		this.loadingVenues = false,
		this.loadingSlots = false,
		this.submitting = false,
		this.error,
	});

	factory BookingFormState.initial() => BookingFormState(
		venues: const [],
		fields: const [],
		slots: const [],
		selectedDate: DateTime.now(),
		selectedSlots: const [],
		players: 1,
		maxPlayers: 10,
		loadingVenues: false,
		loadingSlots: false,
		submitting: false,
	);

	final List<Venue> venues;
	final List<Field> fields;
	final List<ReservationSlot> slots;
	final int? selectedVenueId;
	final int? selectedFieldId;
	final List<ReservationSlot> selectedSlots;
	final int players;
	final int maxPlayers;
	final DateTime selectedDate;
	final bool loadingVenues;
	final bool loadingSlots;
	final bool submitting;
	final String? error;

	BookingFormState copyWith({
		List<Venue>? venues,
		List<Field>? fields,
		List<ReservationSlot>? slots,
		int? selectedVenueId,
		int? selectedFieldId,
		List<ReservationSlot>? selectedSlots,
		int? players,
		int? maxPlayers,
		DateTime? selectedDate,
		bool? loadingVenues,
		bool? loadingSlots,
		bool? submitting,
		String? error,
		bool clearError = false,
	}) {
		return BookingFormState(
			venues: venues ?? this.venues,
			fields: fields ?? this.fields,
			slots: slots ?? this.slots,
			selectedVenueId: selectedVenueId ?? this.selectedVenueId,
			selectedFieldId: selectedFieldId ?? this.selectedFieldId,
			selectedSlots: selectedSlots ?? this.selectedSlots,
			players: players ?? this.players,
			maxPlayers: maxPlayers ?? this.maxPlayers,
			selectedDate: selectedDate ?? this.selectedDate,
			loadingVenues: loadingVenues ?? this.loadingVenues,
			loadingSlots: loadingSlots ?? this.loadingSlots,
			submitting: submitting ?? this.submitting,
			error: clearError ? null : (error ?? this.error),
		);
	}
}

class BookingSubmitResult {
	const BookingSubmitResult({
		required this.success,
		required this.message,
		this.data,
	});

	final bool success;
	final String message;
	final Map<String, dynamic>? data;

	factory BookingSubmitResult.success({
		required Map<String, dynamic> data,
		String message = 'Reserva creada correctamente',
	}) => BookingSubmitResult(success: true, message: message, data: data);

	factory BookingSubmitResult.failure(String message) =>
			BookingSubmitResult(success: false, message: message);
}

class BookingFormRepository {
	BookingFormRepository({
		required VenuesRepository venuesRepository,
		required ReservationsRepository reservationsRepository,
	}) : _venuesRepository = venuesRepository,
			_reservationsRepository = reservationsRepository;

	final VenuesRepository _venuesRepository;
	final ReservationsRepository _reservationsRepository;

	Future<List<Venue>> fetchVenues() async =>
			_venuesRepository.getVenuesInicio();

	Future<Venue> fetchVenue(int id) async => _venuesRepository.getVenue(id);

	Future<List<Field>> fetchFields(int venueId) async =>
			_venuesRepository.getVenueFields(venueId);

	Future<List<ReservationSlot>> fetchSlots(
		Field field,
		DateTime date,
	) async {
		final existing = await _reservationsRepository.getFieldReservations(
			idCancha: field.id,
			fecha: date,
		);
		final startHour = _parseHour(field.horaApertura) ?? 6;
		final endHour = _parseHour(field.horaCierre) ?? 22;
		return _reservationsRepository.buildSlots(
			existing,
			inicioHora: startHour,
			finHora: endHour,
			intervaloMinutos: 60,
		);
	}

	int? _parseHour(String? hhmm) {
		if (hhmm == null || hhmm.isEmpty) return null;
		final parts = hhmm.split(':');
		return int.tryParse(parts.first);
	}

	Future<Map<String, dynamic>> createReservation({
		required int idCliente,
		required int idCancha,
		required DateTime start,
		required DateTime end,
		required double monto,
		required String token,
		required int players,
	}) async {
		return _reservationsRepository.createReservation(
			idCliente: idCliente,
			idCancha: idCancha,
			inicia: start,
			termina: end,
			cantidadPersonas: players,
			montoBase: monto,
			montoExtra: 0,
		);
	}
}

final bookingFormRepositoryProvider =
		Provider.autoDispose<BookingFormRepository>((ref) {
			final venuesRepo = VenuesRepository();
			final reservationsRepo = ReservationsRepository();
			return BookingFormRepository(
				venuesRepository: venuesRepo,
				reservationsRepository: reservationsRepo,
			);
		});

final bookingFormControllerProvider =
		StateNotifierProvider.autoDispose<BookingFormController, BookingFormState>((
			ref,
		) {
			final repo = ref.watch(bookingFormRepositoryProvider);
			return BookingFormController(ref, repo);
		});

class BookingFormController extends StateNotifier<BookingFormState> {
	BookingFormController(this._ref, this._repository)
		: super(BookingFormState.initial());

	final Ref _ref;
	final BookingFormRepository _repository;

	Future<void> init({int? initialVenueId, int? initialFieldId}) async {
		await _loadVenues(
			initialVenueId: initialVenueId,
			initialFieldId: initialFieldId,
		);
	}

	Future<void> refresh() => _loadVenues(
		initialVenueId: state.selectedVenueId,
		initialFieldId: state.selectedFieldId,
	);

	Future<void> selectVenue(int venueId) async {
		state = state.copyWith(
			selectedVenueId: venueId,
			selectedFieldId: null,
			fields: const [],
			slots: const [],
			selectedSlots: const [],
			maxPlayers: 10,
			loadingSlots: true,
			clearError: true,
		);
		await _loadFields(venueId);
	}

	Future<void> selectField(int fieldId) async {
		final maxForField = _maxPlayersForField(fieldId);
		final clampedPlayers =
				(state.players > maxForField && maxForField > 0) ? maxForField : state.players;
		state = state.copyWith(
			selectedFieldId: fieldId,
			selectedSlots: const [],
			slots: const [],
			maxPlayers: maxForField,
			players: clampedPlayers,
			loadingSlots: true,
			clearError: true,
		);
		await _loadSlots(fieldId, state.selectedDate);
	}

	Future<void> changeDate(DateTime date) async {
		final now = DateTime.now();
		final today = DateTime(now.year, now.month, now.day);
		if (date.isBefore(today)) {
			state = state.copyWith(
				error: 'No puedes reservar una fecha pasada',
			);
			return;
		}
		state = state.copyWith(
			selectedDate: date,
			selectedSlots: const [],
			slots: const [],
			loadingSlots: true,
			clearError: true,
		);
		final fieldId = state.selectedFieldId;
		if (fieldId != null) {
			await _loadSlots(fieldId, date);
		} else {
			state = state.copyWith(loadingSlots: false);
		}
	}

	void toggleSlot(ReservationSlot slot) {
		final current = List<ReservationSlot>.from(state.selectedSlots);
		final exists = current.any((s) =>
			s.horaInicio == slot.horaInicio && s.horaFin == slot.horaFin);
		if (exists) {
			// Reiniciar selección al tocar uno seleccionado
			state = state.copyWith(selectedSlots: const [], clearError: true);
			return;
		}

		if (current.isEmpty) {
			state = state.copyWith(selectedSlots: [slot], clearError: true);
			return;
		}

		current.sort((a, b) => a.horaInicio.compareTo(b.horaInicio));
		final last = current.last;
		if (slot.horaInicio == last.horaFin) {
			current.add(slot);
			current.sort((a, b) => a.horaInicio.compareTo(b.horaInicio));
			state = state.copyWith(selectedSlots: current, clearError: true);
			return;
		}

		// No es consecutivo: reiniciar selección con este slot como inicio
		state = state.copyWith(selectedSlots: [slot], clearError: true);
	}

	void setPlayers(int value, {int? maxOverride}) {
		final maxCap = maxOverride ?? state.maxPlayers;
		final max = maxCap > 0 ? maxCap : 10;
		if (value < 1) {
			state = state.copyWith(players: 1);
			return;
		}
		if (value > max) {
			state = state.copyWith(players: max);
			return;
		}
		state = state.copyWith(players: value);
	}

	Future<BookingSubmitResult> submit() async {
		if (state.selectedFieldId == null || state.selectedSlots.isEmpty) {
			return BookingSubmitResult.failure(
				'Selecciona una cancha y un horario disponible.',
			);
		}
		if (state.players < 1) {
			return BookingSubmitResult.failure(
				'Debes indicar al menos 1 jugador.',
			);
		}
		final duration = _totalDuration(state.selectedSlots);

		final authState = _ref.read(authProvider);
		if (!authState.isAuthenticated || authState.user == null) {
			return BookingSubmitResult.failure(
				'Inicia sesión para crear una reserva.',
			);
		}
		final idCliente = int.tryParse(
			authState.user!.personaId ?? authState.user!.id,
		);
		if (idCliente == null) {
			return BookingSubmitResult.failure('ID de cliente no válido.');
		}

		final token = await StorageHelper.getToken();
		if (token == null || token.isEmpty) {
			return BookingSubmitResult.failure(
				'Token no encontrado. Por favor vuelve a iniciar sesión.',
			);
		}

		final start = _composeDate(
			state.selectedDate,
			state.selectedSlots.first.horaInicio,
		);
		final end = _composeDate(
			state.selectedDate,
			state.selectedSlots.last.horaFin,
		);
		final montoBase = _priceFor(duration);

		state = state.copyWith(submitting: true, clearError: true);
		try {
			final resp = await _repository.createReservation(
				idCliente: idCliente,
				idCancha: state.selectedFieldId!,
				start: start,
				end: end,
				monto: montoBase,
				token: token,
				players: state.players,
			);
			return BookingSubmitResult.success(data: resp);
		} catch (e) {
			return BookingSubmitResult.failure('Error al crear la reserva: $e');
		} finally {
			state = state.copyWith(submitting: false);
		}
	}

	Future<void> _loadVenues({int? initialVenueId, int? initialFieldId}) async {
		state = state.copyWith(
			loadingVenues: true,
			loadingSlots: true,
			clearError: true,
		);
		try {
			List<Venue> venues = await _repository.fetchVenues();
			// Si venimos desde el detalle y la sede no estÃ¡ en el listado inicial,
			// la agregamos para evitar que se seleccione otra por defecto.
			if (initialVenueId != null &&
					venues.every((v) => v.id != initialVenueId)) {
				try {
					final venue = await _repository.fetchVenue(initialVenueId);
					venues = [venue, ...venues];
				} catch (_) {
					// Si falla, continuamos con el listado actual.
				}
			}

			final selectedVenueId =
					initialVenueId ?? (venues.isNotEmpty ? venues.first.id : null);

			final fields = selectedVenueId != null
					? await _repository.fetchFields(selectedVenueId)
					: <Field>[];

			final selectedFieldId = initialFieldId != null &&
					fields.any((f) => f.id == initialFieldId)
				? initialFieldId
				: (fields.isNotEmpty ? fields.first.id : null);

			final selectedField = selectedFieldId != null
					? fields.firstWhere((f) => f.id == selectedFieldId)
					: null;
			final maxPlayersSelected = _maxPlayersForField(
				selectedFieldId,
				fieldsOverride: fields,
				fieldOverride: selectedField,
			);
			final clampedPlayers = (state.players > maxPlayersSelected && maxPlayersSelected > 0)
					? maxPlayersSelected
					: state.players;

			List<ReservationSlot> slots = <ReservationSlot>[];
			if (selectedFieldId != null) {
				final selectedField = fields.firstWhere((f) => f.id == selectedFieldId);
				slots = await _repository.fetchSlots(selectedField, state.selectedDate);
			}

			state = state.copyWith(
				venues: venues,
				fields: fields,
				slots: slots,
				selectedVenueId: selectedVenueId,
				selectedFieldId: selectedFieldId,
				selectedSlots: const [],
				maxPlayers: maxPlayersSelected,
				players: clampedPlayers,
				loadingVenues: false,
				loadingSlots: false,
			);
		} catch (e) {
			state = state.copyWith(
				loadingVenues: false,
				loadingSlots: false,
				error: e.toString(),
			);
		}
	}

	Future<void> _loadFields(int venueId) async {
		try {
			final fields = await _repository.fetchFields(venueId);
			final selectedFieldId = fields.isNotEmpty ? fields.first.id : null;
			final selectedField =
					selectedFieldId != null
							? fields.firstWhere((f) => f.id == selectedFieldId)
							: null;
			final maxForField = _maxPlayersForField(
				selectedFieldId,
				fieldsOverride: fields,
				fieldOverride: selectedField,
			);
			state = state.copyWith(
				fields: fields,
				selectedFieldId: selectedFieldId,
				loadingSlots: true,
				maxPlayers: maxForField,
				players: (state.players > maxForField && maxForField > 0)
						? maxForField
						: state.players,
			);
			if (selectedFieldId != null) {
				await _loadSlots(selectedFieldId, state.selectedDate);
			} else {
				state = state.copyWith(loadingSlots: false);
			}
		} catch (e) {
			state = state.copyWith(loadingSlots: false, error: e.toString());
		}
	}

	Future<void> _loadSlots(int fieldId, DateTime date) async {
		state = state.copyWith(loadingSlots: true, clearError: true);
		try {
			final field = state.fields.firstWhere((f) => f.id == fieldId);
			final slots = await _repository.fetchSlots(field, date);
			state = state.copyWith(
				slots: slots,
				loadingSlots: false,
				selectedSlots: const [],
			);
		} catch (e) {
			state = state.copyWith(loadingSlots: false, error: e.toString());
		}
	}

	DateTime _composeDate(DateTime date, String hhmmss) {
		final parts = hhmmss.split(':');
		final h = int.tryParse(parts[0]) ?? 0;
		final m = int.tryParse(parts[1]) ?? 0;
		return DateTime(date.year, date.month, date.day, h, m);
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

	double _priceFor(Duration duration) {
		final field = state.fields.firstWhere(
			(f) => f.id == state.selectedFieldId,
			orElse: () => Field(
				id: state.selectedFieldId ?? 0,
				sedeId: 0,
				nombre: 'Cancha',
				fotos: const [],
			),
		);
		final pricePerHour = field.precio ?? 0;
		return pricePerHour * (duration.inMinutes / 60);
	}

	int _maxPlayersForField(
		int? fieldId, {
		List<Field>? fieldsOverride,
		Field? fieldOverride,
	}) {
		if (fieldOverride != null) {
			final maxCap = fieldOverride.maxPlayers ?? fieldOverride.aforoMaximo;
			if (maxCap != null && maxCap > 0) return maxCap;
		}
		if (fieldId == null) return 10;
		final fields = fieldsOverride ?? state.fields;
		final field = fields.firstWhere(
			(f) => f.id == fieldId,
			orElse: () => Field(
				id: fieldId,
				sedeId: 0,
				nombre: 'Cancha',
				fotos: const [],
			),
		);
		final max = field.maxPlayers ?? field.aforoMaximo;
		if (max == null || max <= 0) return 10;
		return max;
	}
}

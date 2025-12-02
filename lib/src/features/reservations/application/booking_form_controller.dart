import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/field.dart';
import '../../../data/models/venue.dart';
import '../../../apis/deprecated/fields_service.dart';
import '../../../apis/deprecated/reservations_service.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../../state/providers.dart';

class RentalOption {
  const RentalOption({
    required this.id,
    required this.label,
    required this.duration,
    this.helper,
  });

  final String id;
  final String label;
  final Duration duration;
  final String? helper;
}

class BookingFormState {
  const BookingFormState({
    required this.venues,
    required this.fields,
    required this.slots,
    required this.selectedDate,
    this.selectedVenueId,
    this.selectedFieldId,
    this.selectedRentalId,
    this.selectedSlot,
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
    loadingVenues: false,
    loadingSlots: false,
    submitting: false,
  );

  final List<Venue> venues;
  final List<Field> fields;
  final List<ReservationSlot> slots;
  final int? selectedVenueId;
  final int? selectedFieldId;
  final String? selectedRentalId;
  final ReservationSlot? selectedSlot;
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
    String? selectedRentalId,
    ReservationSlot? selectedSlot,
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
      selectedRentalId: selectedRentalId ?? this.selectedRentalId,
      selectedSlot: selectedSlot ?? this.selectedSlot,
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
    required FieldsService fieldsService,
    required ReservationsService reservationsService,
  }) : _fieldsService = fieldsService,
       _reservationsService = reservationsService;

  final FieldsService _fieldsService;
  final ReservationsService _reservationsService;

  Future<List<Venue>> fetchVenues() async => _fieldsService.fetchVenuesInicio();

  Future<List<Field>> fetchFields(int venueId) async =>
      _fieldsService.fetchVenueFields(venueId);

  Future<List<ReservationSlot>> fetchSlots(int fieldId, DateTime date) async {
    final existing = await _reservationsService.getReservationsForField(
      fieldId,
      date,
    );
    return _reservationsService.buildSlots(existing);
  }

  Future<Map<String, dynamic>> createReservation({
    required int idCliente,
    required int idCancha,
    required DateTime start,
    required DateTime end,
    required double monto,
    required String token,
  }) async {
    return _reservationsService.createReservation(
      idCliente: idCliente,
      idCancha: idCancha,
      inicia: start,
      termina: end,
      montoBase: monto,
      montoExtra: 0,
      token: token,
    );
  }
}

final bookingFormRepositoryProvider =
    Provider.autoDispose<BookingFormRepository>((ref) {
      return BookingFormRepository(
        fieldsService: fieldsService,
        reservationsService: reservationsService,
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

  static const List<RentalOption> rentalOptions = [
    RentalOption(
      id: 'hourly',
      label: 'Por hora',
      duration: Duration(hours: 1),
      helper: 'Ideal para juegos r\u00e1pidos o entrenamientos',
    ),
    RentalOption(
      id: 'half-day',
      label: 'Media jornada',
      duration: Duration(hours: 4),
      helper: 'Bloque de 4 horas (ma\u00f1ana o tarde)',
    ),
    RentalOption(
      id: 'full-day',
      label: 'D\u00eda completo',
      duration: Duration(hours: 8),
      helper: 'Reserva extendida para eventos o torneos',
    ),
  ];

  final Ref _ref;
  final BookingFormRepository _repository;

  Future<void> init() async {
    await _loadVenues();
  }

  Future<void> refresh() => _loadVenues();

  Future<void> selectVenue(int venueId) async {
    state = state.copyWith(
      selectedVenueId: venueId,
      selectedFieldId: null,
      fields: const [],
      slots: const [],
      selectedSlot: null,
      loadingSlots: true,
      clearError: true,
    );
    await _loadFields(venueId);
  }

  Future<void> selectField(int fieldId) async {
    state = state.copyWith(
      selectedFieldId: fieldId,
      selectedSlot: null,
      slots: const [],
      loadingSlots: true,
      clearError: true,
    );
    await _loadSlots(fieldId, state.selectedDate);
  }

  Future<void> changeDate(DateTime date) async {
    state = state.copyWith(
      selectedDate: date,
      selectedSlot: null,
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

  void selectRental(String rentalId) {
    state = state.copyWith(
      selectedRentalId: rentalId,
      selectedSlot: null,
      clearError: true,
    );
  }

  void selectSlot(ReservationSlot slot) {
    state = state.copyWith(selectedSlot: slot, clearError: true);
  }

  bool canStartAt(ReservationSlot slot) {
    final duration = _currentDuration();
    return _spanAvailable(slot, duration);
  }

  Future<BookingSubmitResult> submit() async {
    if (state.selectedFieldId == null || state.selectedSlot == null) {
      return BookingSubmitResult.failure(
        'Selecciona una cancha y un horario disponible.',
      );
    }
    final duration = _currentDuration();
    if (!_spanAvailable(state.selectedSlot!, duration)) {
      return BookingSubmitResult.failure(
        'El horario elegido no cubre la duraci\u00f3n seleccionada.',
      );
    }

    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user == null) {
      return BookingSubmitResult.failure(
        'Inicia sesi\u00f3n para crear una reserva.',
      );
    }
    final idCliente = int.tryParse(
      authState.user!.personaId ?? authState.user!.id,
    );
    if (idCliente == null) {
      return BookingSubmitResult.failure('ID de cliente no v\u00e1lido.');
    }

    final token = await StorageHelper.getToken();
    if (token == null || token.isEmpty) {
      return BookingSubmitResult.failure(
        'Token no encontrado. Por favor vuelve a iniciar sesi\u00f3n.',
      );
    }

    final start = _composeDate(
      state.selectedDate,
      state.selectedSlot!.horaInicio,
    );
    final end = start.add(duration);
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
      );
      return BookingSubmitResult.success(data: resp);
    } catch (e) {
      return BookingSubmitResult.failure('Error al crear la reserva: $e');
    } finally {
      state = state.copyWith(submitting: false);
    }
  }

  Future<void> _loadVenues() async {
    state = state.copyWith(
      loadingVenues: true,
      loadingSlots: true,
      clearError: true,
    );
    try {
      final venues = await _repository.fetchVenues();
      final selectedVenueId = venues.isNotEmpty ? venues.first.id : null;
      final fields = selectedVenueId != null
          ? await _repository.fetchFields(selectedVenueId)
          : <Field>[];
      final selectedFieldId = fields.isNotEmpty ? fields.first.id : null;
      final slots = selectedFieldId != null
          ? await _repository.fetchSlots(selectedFieldId, state.selectedDate)
          : <ReservationSlot>[];

      state = state.copyWith(
        venues: venues,
        fields: fields,
        slots: slots,
        selectedVenueId: selectedVenueId,
        selectedFieldId: selectedFieldId,
        selectedRentalId: state.selectedRentalId ?? rentalOptions.first.id,
        selectedSlot: null,
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
      state = state.copyWith(
        fields: fields,
        selectedFieldId: selectedFieldId,
        loadingSlots: true,
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
      final slots = await _repository.fetchSlots(fieldId, date);
      state = state.copyWith(
        slots: slots,
        loadingSlots: false,
        selectedSlot: null,
      );
    } catch (e) {
      state = state.copyWith(loadingSlots: false, error: e.toString());
    }
  }

  bool _spanAvailable(ReservationSlot startSlot, Duration duration) {
    final startHour = _parseHour(startSlot.horaInicio);
    final requiredHours = duration.inHours;
    final endHour = startHour + requiredHours;
    if (endHour > 24) return false;

    for (int h = startHour; h < endHour; h++) {
      final slot = _findSlotForHour(h);
      if (slot == null || slot.ocupado) return false;
    }
    return true;
  }

  ReservationSlot? _findSlotForHour(int hour) {
    for (final slot in state.slots) {
      if (_parseHour(slot.horaInicio) == hour) return slot;
    }
    return null;
  }

  int _parseHour(String hhmmss) {
    final parts = hhmmss.split(':');
    return int.tryParse(parts.first) ?? 0;
  }

  DateTime _composeDate(DateTime date, String hhmmss) {
    final parts = hhmmss.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return DateTime(date.year, date.month, date.day, h, m);
  }

  double _priceFor(Duration duration) {
    final field = state.fields.firstWhere(
      (f) => f.id == state.selectedFieldId,
      orElse: () => Field(
        id: state.selectedFieldId ?? 0,
        nombre: 'Cancha',
        fotos: const [],
      ),
    );
    final pricePerHour = field.precio ?? 0;
    return pricePerHour * duration.inHours;
  }

  Duration _currentDuration() {
    final rental = rentalOptions.firstWhere(
      (r) => r.id == state.selectedRentalId,
      orElse: () => rentalOptions.first,
    );
    return rental.duration;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/field.dart';
import '../../../data/models/venue.dart';
import '../../../data/repositories/venues_repository.dart';

class VenuesState {
  const VenuesState({
    required this.venues,
    required this.fieldsByVenue,
    required this.loadingList,
    required this.loadingFieldsFor,
    this.expandedVenueId,
    this.error,
  });

  factory VenuesState.initial() => VenuesState(
    venues: const [],
    fieldsByVenue: const {},
    loadingList: false,
    loadingFieldsFor: null,
    expandedVenueId: null,
    error: null,
  );

  final List<Venue> venues;
  final Map<int, List<Field>> fieldsByVenue;
  final bool loadingList;
  final int? loadingFieldsFor;
  final int? expandedVenueId;
  final String? error;

  VenuesState copyWith({
    List<Venue>? venues,
    Map<int, List<Field>>? fieldsByVenue,
    bool? loadingList,
    int? loadingFieldsFor,
    int? expandedVenueId,
    String? error,
    bool clearError = false,
  }) {
    return VenuesState(
      venues: venues ?? this.venues,
      fieldsByVenue: fieldsByVenue ?? this.fieldsByVenue,
      loadingList: loadingList ?? this.loadingList,
      loadingFieldsFor: loadingFieldsFor,
      expandedVenueId: expandedVenueId ?? this.expandedVenueId,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final venuesControllerProvider =
    StateNotifierProvider.autoDispose<VenuesController, VenuesState>((ref) {
      return VenuesController(venuesRepository: VenuesRepository());
    });

class VenuesController extends StateNotifier<VenuesState> {
  VenuesController({required VenuesRepository venuesRepository})
    : _venuesRepository = venuesRepository,
      super(VenuesState.initial());

  final VenuesRepository _venuesRepository;

  Future<void> loadVenues() async {
    state = state.copyWith(loadingList: true, clearError: true);
    try {
      final venues = await _venuesRepository.getVenuesInicio();
      state = state.copyWith(
        venues: venues,
        loadingList: false,
        expandedVenueId: venues.isNotEmpty ? venues.first.id : null,
      );
      if (venues.isNotEmpty) {
        await fetchFieldsForVenue(venues.first.id);
      }
    } catch (e) {
      state = state.copyWith(loadingList: false, error: e.toString());
    }
  }

  Future<void> fetchFieldsForVenue(int venueId) async {
    if (state.fieldsByVenue.containsKey(venueId)) {
      return;
    }
    state = state.copyWith(loadingFieldsFor: venueId, clearError: true);
    try {
      final fields = await _venuesRepository.getVenueFields(venueId);
      final updated = Map<int, List<Field>>.from(state.fieldsByVenue)
        ..[venueId] = fields;
      state = state.copyWith(fieldsByVenue: updated, loadingFieldsFor: null);
    } catch (e) {
      state = state.copyWith(loadingFieldsFor: null, error: e.toString());
    }
  }

  Future<void> toggleExpanded(int venueId) async {
    final current = state.expandedVenueId;
    final nextId = current == venueId ? null : venueId;
    state = state.copyWith(expandedVenueId: nextId, clearError: true);
    if (nextId != null) {
      await fetchFieldsForVenue(nextId);
    }
  }
}

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
		required this.isLoadingDetail,
		this.venueDetail,
		this.expandedVenueId,
		this.error,
	});

	factory VenuesState.initial() => VenuesState(
		venues: const [],
		fieldsByVenue: const {},
		loadingList: false,
		loadingFieldsFor: null,
		isLoadingDetail: false,
		venueDetail: null,
		expandedVenueId: null,
		error: null,
	);

	final List<Venue> venues;
	final Map<int, List<Field>> fieldsByVenue;
	final bool loadingList;
	final int? loadingFieldsFor;
	final bool isLoadingDetail;
	final Venue? venueDetail;
	final int? expandedVenueId;
	final String? error;

	VenuesState copyWith({
		List<Venue>? venues,
		Map<int, List<Field>>? fieldsByVenue,
		bool? loadingList,
		int? loadingFieldsFor,
		bool? isLoadingDetail,
		Venue? venueDetail,
		int? expandedVenueId,
		String? error,
		bool clearError = false,
		bool clearVenueDetail = false,
	}) {
		return VenuesState(
			venues: venues ?? this.venues,
			fieldsByVenue: fieldsByVenue ?? this.fieldsByVenue,
			loadingList: loadingList ?? this.loadingList,
			loadingFieldsFor: loadingFieldsFor,
			isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
			venueDetail: clearVenueDetail ? null : (venueDetail ?? this.venueDetail),
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

	Future<void> loadVenueDetail(int venueId) async {
		state = state.copyWith(
			isLoadingDetail: true,
			clearVenueDetail: true,
			clearError: true,
		);
		try {
			print('loadVenueDetail -> id=$venueId');
			final venue = await _venuesRepository.getVenue(venueId);
			final fields = await _venuesRepository.getVenueFields(venueId);
			print(
				'loadVenueDetail fetched venue=${venue.id} fields=${fields.length}',
			);
			final venueWithFields = _mergeVenueWithFields(venue, fields);
			final updatedFields = Map<int, List<Field>>.from(state.fieldsByVenue)
				..[venueId] = fields;
			state = state.copyWith(
				venueDetail: venueWithFields,
				fieldsByVenue: updatedFields,
				isLoadingDetail: false,
			);
		} catch (e) {
			print('loadVenueDetail error: $e');
			state = state.copyWith(
				isLoadingDetail: false,
				error: e.toString(),
			);
		}
	}

	Venue _mergeVenueWithFields(Venue venue, List<Field> fields) {
		return Venue(
			id: venue.id,
			nombre: venue.nombre,
			ciudad: venue.ciudad,
			direccion: venue.direccion,
			fotoPrincipal: venue.fotoPrincipal,
			descripcion: venue.descripcion,
			propietario: venue.propietario,
			telefono: venue.telefono,
			email: venue.email,
			lat: venue.lat,
			lon: venue.lon,
			managerName: venue.managerName,
			managerPhone: venue.managerPhone,
			managerEmail: venue.managerEmail,
			totalCanchas: venue.totalCanchas ?? fields.length,
			deportesDisponibles: venue.deportesDisponibles,
			canchas: fields,
		);
	}
}

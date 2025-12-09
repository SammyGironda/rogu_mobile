import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../features/reservations/application/booking_confirm_controller.dart';
import '../../../features/reservations/models/booking_draft.dart';
import 'booking_payment_screen.dart';

/// Step 2: shows the booking summary and routes to payment.
class BookingConfirmScreen extends ConsumerStatefulWidget {
	const BookingConfirmScreen({super.key});

	static const String routeName = '/booking_confirm';

	@override
	ConsumerState<BookingConfirmScreen> createState() =>
			_BookingConfirmScreenState();
}

class _BookingConfirmScreenState
		extends ConsumerState<BookingConfirmScreen> {
	BookingDraft? _draft;

	@override
	void initState() {
		super.initState();
		WidgetsBinding.instance.addPostFrameCallback((_) {
			final draft =
				ModalRoute.of(context)!.settings.arguments as BookingDraft;
			_draft = draft;
			ref.read(bookingConfirmControllerProvider.notifier).setDraft(draft);
			if (mounted) setState(() {});
		});
	}

	@override
	Widget build(BuildContext context) {
		final draft = _draft;
		if (draft == null) {
			return const Scaffold(
				body: Center(child: CircularProgressIndicator()),
			);
		}

		final theme = Theme.of(context);
		final photos = draft.fieldPhotos;
		final slotsLabel = draft.slots
			.map((s) => '${s.startTime.substring(0, 5)} - ${s.endTime.substring(0, 5)}')
			.join(', ');
		final dateStr =
			'${draft.date.year.toString().padLeft(4, '0')}-${draft.date.month.toString().padLeft(2, '0')}-${draft.date.day.toString().padLeft(2, '0')}';

		return Scaffold(
			appBar: AppBar(title: const Text('Confirmación de reserva')),
			body: SafeArea(
				child: SingleChildScrollView(
					padding: const EdgeInsets.all(16),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.stretch,
						children: [
							_PhotoCarousel(photos: photos),
							const SizedBox(height: 16),
							Text(
								draft.fieldName,
								style: theme.textTheme.headlineSmall?.copyWith(
									fontWeight: FontWeight.bold,
								),
							),
							const SizedBox(height: 4),
							Text(
								draft.venueName,
								style: theme.textTheme.bodyMedium?.copyWith(
									color: AppColors.neutral600,
								),
							),
							const SizedBox(height: 12),
							_SummaryRow(
								label: 'Fecha',
								value: dateStr,
							),
							_SummaryRow(
								label: 'Horarios',
								value: slotsLabel,
							),
							_SummaryRow(
								label: 'Jugadores',
								value: draft.players.toString(),
							),
							const SizedBox(height: 12),
							Container(
								padding: const EdgeInsets.all(14),
								decoration: BoxDecoration(
									color: AppColors.primary50,
									borderRadius: BorderRadius.circular(12),
								),
								child: Row(
									mainAxisAlignment: MainAxisAlignment.spaceBetween,
									children: [
										const Text(
											'Total estimado',
											style: TextStyle(
												fontWeight: FontWeight.w700,
												color: AppColors.neutral800,
											),
										),
										Text(
											'Bs ${draft.totalAmount.toStringAsFixed(2)}',
											style: const TextStyle(
												fontWeight: FontWeight.w800,
												fontSize: 18,
												color: AppColors.neutral900,
											),
										),
									],
								),
							),
							const SizedBox(height: 24),
							ElevatedButton(
								onPressed: () {
									Navigator.pushNamed(
										context,
										BookingPaymentScreen.routeName,
										arguments: draft,
									);
								},
								style: ElevatedButton.styleFrom(
									padding: const EdgeInsets.symmetric(vertical: 16),
									shape: RoundedRectangleBorder(
										borderRadius: BorderRadius.circular(14),
									),
								),
								child: const Text('Ir a pagar'),
							),
						],
					),
				),
			),
		);
	}
}

class _PhotoCarousel extends StatefulWidget {
	const _PhotoCarousel({required this.photos});
	final List<String> photos;

	@override
	State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
	final PageController _pageController = PageController();

	@override
	void dispose() {
		_pageController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		final photos = widget.photos;
		if (photos.isEmpty) {
			return Container(
				height: 200,
				decoration: BoxDecoration(
					color: AppColors.neutral200,
					borderRadius: BorderRadius.circular(16),
				),
				alignment: Alignment.center,
				child: const Text('Sin fotos'),
			);
		}
		return SizedBox(
			height: 220,
			child: Stack(
				children: [
					PageView.builder(
						controller: _pageController,
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
										animation: _pageController,
										builder: (_, __) {
											double selected = 0;
											if (_pageController.hasClients &&
												_pageController.page != null) {
												selected = (_pageController.page ?? 0) - i;
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
															color: Colors.black.withValues(alpha: 0.2),
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

class _SummaryRow extends StatelessWidget {
	const _SummaryRow({required this.label, required this.value});
	final String label;
	final String value;

	@override
	Widget build(BuildContext context) {
		return Container(
			margin: const EdgeInsets.only(bottom: 8),
			padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
			decoration: BoxDecoration(
				color: AppColors.neutral50,
				borderRadius: BorderRadius.circular(12),
				border: Border.all(color: AppColors.neutral200),
			),
			child: Row(
				mainAxisAlignment: MainAxisAlignment.spaceBetween,
				children: [
					Text(
						label,
						style: const TextStyle(
							fontWeight: FontWeight.w600,
							color: AppColors.neutral700,
						),
					),
					Flexible(
						child: Text(
							value,
							textAlign: TextAlign.end,
							style: const TextStyle(
								fontWeight: FontWeight.w700,
								color: AppColors.neutral900,
							),
						),
					),
				],
			),
		);
	}
}

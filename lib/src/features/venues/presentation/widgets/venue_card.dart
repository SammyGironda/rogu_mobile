import 'package:flutter/material.dart';

import '../../../../data/models/venue.dart';
import '../../../../core/theme/app_theme.dart';

/// Card compacta de sede al estilo web: imagen + nombre + ubicación + badge de canchas.
class VenueCard extends StatelessWidget {
	const VenueCard({
		super.key,
		required this.venue,
		required this.fieldsCount,
		required this.onTap,
	});

	final Venue venue;
	final int fieldsCount;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		final Color overlay = Colors.black.withOpacity(0.35);
		final int count = venue.totalCanchas ?? fieldsCount;

		return Card(
			margin: const EdgeInsets.only(bottom: 14),
			clipBehavior: Clip.antiAlias,
			elevation: 3,
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
			child: InkWell(
				onTap: onTap,
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						AspectRatio(
							aspectRatio: 3 / 2,
							child: Stack(
								children: [
									Positioned.fill(
										child: venue.fotoPrincipal != null
												? Image.network(
													venue.fotoPrincipal!,
													fit: BoxFit.cover,
													errorBuilder: (_, __, ___) => _fallbackImage(),
												)
												: _fallbackImage(),
									),
									Positioned.fill(
										child: Container(
											decoration: BoxDecoration(
												gradient: LinearGradient(
													begin: Alignment.topCenter,
													end: Alignment.bottomCenter,
													colors: [
														Colors.black.withOpacity(0.10),
														overlay,
													],
												),
											),
										),
									),
									Positioned(
										left: 12,
										right: 12,
										bottom: 12,
										child: Row(
											children: [
												Expanded(
													child: Column(
														crossAxisAlignment: CrossAxisAlignment.start,
														children: [
															Text(
																venue.nombre,
																maxLines: 1,
																overflow: TextOverflow.ellipsis,
																style: theme.textTheme.titleMedium?.copyWith(
																	color: Colors.white,
																	fontWeight: FontWeight.w700,
																),
															),
															const SizedBox(height: 4),
															Row(
																children: [
																	const Icon(
																		Icons.location_on,
																		size: 16,
																		color: Colors.white70,
																	),
																	const SizedBox(width: 4),
																	Expanded(
																		child: Text(
																			venue.getShortLocation(),
																			maxLines: 1,
																			overflow: TextOverflow.ellipsis,
																			style: theme.textTheme.bodySmall?.copyWith(
																				color: Colors.white70,
																			),
																		),
																	),
																],
															),
														],
													),
												),
												const SizedBox(width: 10),
												Container(
													padding: const EdgeInsets.symmetric(
														horizontal: 10,
														vertical: 6,
													),
													decoration: BoxDecoration(
														color: Colors.white.withOpacity(0.18),
														borderRadius: BorderRadius.circular(12),
														border: Border.all(color: Colors.white24),
													),
													child: Row(
														mainAxisSize: MainAxisSize.min,
														children: [
															const Icon(
																Icons.sports_soccer,
																size: 16,
																color: Colors.white,
															),
															const SizedBox(width: 4),
															Text(
																count > 0
																		? '$count canchas'
																		: 'Ver canchas',
																style: const TextStyle(
																	color: Colors.white,
																	fontWeight: FontWeight.w600,
																),
															),
														],
													),
												),
											],
										),
									),
								],
							),
						),
						Padding(
							padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
							child: Row(
								children: [
									const Icon(
										Icons.place_outlined,
										size: 18,
										color: AppColors.neutral500,
									),
									const SizedBox(width: 6),
									Expanded(
										child: Text(
											venue.getShortLocation(),
											maxLines: 1,
											overflow: TextOverflow.ellipsis,
											style: theme.textTheme.bodyMedium?.copyWith(
												color: AppColors.neutral700,
											),
										),
									),
								],
							),
						),
					],
				),
			),
		);
	}

	Widget _fallbackImage() {
		return Container(
			color: AppColors.neutral200,
			alignment: Alignment.center,
			child: const Icon(
				Icons.image_not_supported,
				color: AppColors.neutral500,
				size: 32,
			),
		);
	}
}

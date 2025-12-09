import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class TimeSlotChip extends StatelessWidget {
	const TimeSlotChip({
		super.key,
		required this.label,
		required this.selected,
		required this.disabled,
		required this.onTap,
	});

	final String label;
	final bool selected;
	final bool disabled;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		final Color background = disabled
				? const Color(0xFFEDEDED)
				: (selected ? AppColors.primary600 : const Color(0xFFF2F4F7));
		final Color border = disabled
				? const Color(0xFFEDEDED)
				: (selected ? AppColors.primary700 : const Color(0xFFE0E3E7));
		final Color textColor = disabled
				? AppColors.neutral400
				: (selected ? Colors.white : const Color(0xFF1A1C1E));

		return SizedBox(
			height: 44,
			child: Material(
				color: background,
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(12),
					side: BorderSide(color: border),
				),
				child: InkWell(
					onTap: disabled ? null : onTap,
					borderRadius: BorderRadius.circular(12),
					child: Padding(
						padding: const EdgeInsets.symmetric(horizontal: 12),
						child: Row(
							mainAxisSize: MainAxisSize.min,
							children: [
								Text(
									label,
									style: Theme.of(context).textTheme.bodyMedium?.copyWith(
										color: textColor,
										fontWeight:
											selected ? FontWeight.w600 : FontWeight.w500,
									),
								),
								const SizedBox(width: 8),
								SizedBox(
									width: 14,
									height: 14,
									child: selected
											? const Icon(
												Icons.check_circle,
												size: 14,
												color: Colors.white,
											)
											: const SizedBox.shrink(),
								),
							],
						),
					),
				),
			),
		);
	}
}

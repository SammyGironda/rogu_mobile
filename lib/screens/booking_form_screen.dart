import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/app_drawer.dart';

class BookingFormScreen extends StatefulWidget {
	static const String routeName = '/booking_form';

	const BookingFormScreen({super.key});

	@override
	State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
	final _formKey = GlobalKey<FormState>();

	final List<Map<String, String>> _courts = [
		{'id': '1', 'name': 'Cancha de Fútbol 1'},
		{'id': '2', 'name': 'Cancha de Fútbol 2'},
		{'id': '3', 'name': 'Cancha de Baloncesto'},
		{'id': '4', 'name': 'Cancha de Tenis 1'},
		{'id': '5', 'name': 'Cancha de Tenis 2'},
		{'id': '6', 'name': 'Cancha de Voleibol'},
	];

	final List<String> _timeSlots = [
		'08:00 - 10:00',
		'10:00 - 12:00',
		'12:00 - 14:00',
		'14:00 - 16:00',
		'16:00 - 18:00',
		'18:00 - 20:00',
		'20:00 - 22:00',
	];

	final List<Map<String, String>> _rentalTypes = [
		{'id': 'hourly', 'name': 'Por Hora', 'price': '15€/hora'},
		{'id': 'half-day', 'name': 'Media Jornada', 'price': '50€'},
		{'id': 'full-day', 'name': 'Día Completo', 'price': '90€'},
	];

	String? _selectedCourt;
	DateTime? _selectedDate;
	String? _selectedTime;
	String? _selectedRental;

	void _pickDate() async {
		final now = DateTime.now();
		final d = await showDatePicker(
			context: context,
			initialDate: _selectedDate ?? now,
			firstDate: now,
			lastDate: DateTime(now.year + 1),
		);
		if (d != null) setState(() => _selectedDate = d);
	}

	void _submit() {
		if (_selectedCourt == null || _selectedDate == null || _selectedTime == null || _selectedRental == null) {
			ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor completa todos los campos')));
			return;
		}

		// Simulate success
		ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Reserva creada exitosamente!')));

		// Reset
		setState(() {
			_selectedCourt = null;
			_selectedDate = null;
			_selectedTime = null;
			_selectedRental = null;
		});
		_formKey.currentState?.reset();
	}

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		final isDark = theme.brightness == Brightness.dark;
		// Buttons in dark mode should be light for contrast; text on light buttons should be dark.
		final Color buttonBg = isDark ? Colors.white : theme.colorScheme.primary;
		final Color buttonFg = isDark ? Colors.black : Colors.white;
		final Color inputFill = isDark ? Colors.white.withAlpha((0.06 * 255).round()) : AppColors.neutral100;
		final displayDate = _selectedDate == null ? '' : _selectedDate!.toLocal().toString().split(' ').first;

			return Scaffold(
				appBar: AppBar(
					title: const Text('Nueva Reserva'),
					leading: Builder(builder: (ctx) {
						final theme = Theme.of(context);
						final bool isDark = theme.brightness == Brightness.dark;
						final Color iconColor = isDark ? Colors.white : AppColors.neutral700;
						return IconButton(icon: Icon(Icons.menu, color: iconColor), onPressed: () => Scaffold.of(ctx).openDrawer());
					}),
				),
				drawer: const AppDrawer(),
				bottomNavigationBar: const BottomNavBar(),
			body: SingleChildScrollView(
				padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
				child: Center(
					child: ConstrainedBox(
						constraints: const BoxConstraints(maxWidth: 760),
						child: Form(
							key: _formKey,
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.stretch,
								children: [
									Text('Nueva Reserva', style: theme.textTheme.headlineSmall),
									const SizedBox(height: 16),

									// Court
									Text('Selecciona la Cancha', style: theme.textTheme.bodyLarge),
									const SizedBox(height: 8),
														DropdownButtonFormField<String>(
															initialValue: _selectedCourt,
										items: _courts.map((c) => DropdownMenuItem(value: c['id'], child: Text(c['name']!))).toList(),
										onChanged: (v) => setState(() => _selectedCourt = v),
										decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: inputFill),
										hint: const Text('Elige una cancha'),
									),
									const SizedBox(height: 12),

									// Date
									Text('Fecha', style: theme.textTheme.bodyLarge),
									const SizedBox(height: 8),
									InkWell(
										onTap: _pickDate,
										child: InputDecorator(
											decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: inputFill),
											child: Row(
												mainAxisAlignment: MainAxisAlignment.spaceBetween,
												children: [Text(displayDate.isEmpty ? 'Elige una fecha' : displayDate), const Icon(Icons.calendar_month)],
											),
										),
									),
									const SizedBox(height: 12),

									// Time
									Text('Horario', style: theme.textTheme.bodyLarge),
									const SizedBox(height: 8),
														DropdownButtonFormField<String>(
															initialValue: _selectedTime,
										items: _timeSlots.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
										onChanged: (v) => setState(() => _selectedTime = v),
										decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: inputFill),
										hint: const Text('Selecciona un horario'),
									),
									const SizedBox(height: 12),

									// Rental types
									Text('Tipo de Alquiler', style: theme.textTheme.bodyLarge),
									const SizedBox(height: 8),
									Wrap(
										spacing: 8,
										runSpacing: 8,
                                        children: _rentalTypes.map((t) {
											final id = t['id']!;
											final selected = _selectedRental == id;
								final labelColor = selected ? (isDark ? Colors.black : Colors.white) : theme.textTheme.bodyLarge?.color;
								final priceColor = selected ? (isDark ? Colors.black : Colors.white) : theme.textTheme.bodySmall?.color;
								return ChoiceChip(
									label: Column(
										mainAxisSize: MainAxisSize.min,
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											Text(t['name']!, style: theme.textTheme.bodyLarge?.copyWith(color: labelColor)),
											Text(t['price']!, style: theme.textTheme.bodySmall?.copyWith(color: priceColor)),
										],
									),
									selected: selected,
									onSelected: (_) => setState(() => _selectedRental = id),
									selectedColor: isDark ? Colors.white.withAlpha((0.90 * 255).round()) : AppColors.secondary500.withAlpha((0.12 * 255).round()),
									backgroundColor: isDark ? Colors.grey[800]! : AppColors.surface,
									side: BorderSide(color: selected ? AppColors.secondary500 : (isDark ? AppColors.neutral700 : AppColors.neutral200)),
								);
										}).toList(),
									),

									const SizedBox(height: 18),
									ElevatedButton(
										onPressed: _submit,
										style: ElevatedButton.styleFrom(
											backgroundColor: buttonBg,
											foregroundColor: buttonFg,
											padding: const EdgeInsets.symmetric(vertical: 14),
										),
										child: Text('Confirmar Reserva', style: TextStyle(color: buttonFg)),
									),

									const SizedBox(height: 12),
									Card(
										color: isDark ? Colors.grey[850] : AppColors.neutral100,
										child: Padding(
											padding: const EdgeInsets.all(12),
											child: Text('💡 Las reservas están sujetas a disponibilidad. Recibirás una confirmación una vez que se apruebe tu solicitud.', style: theme.textTheme.bodyMedium),
										),
									),
								],
							),
						),
					),
				),
			),
		);
	}
}

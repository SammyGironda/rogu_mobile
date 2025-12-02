import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/reservations/application/booking_form_controller.dart';
import '../../../data/models/field.dart';
import '../../../apis/deprecated/reservations_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/bottom_nav.dart';

class BookingFormScreen extends ConsumerStatefulWidget {
  static const String routeName = '/booking_form';

  const BookingFormScreen({super.key});

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(bookingFormControllerProvider.notifier).init(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingFormControllerProvider);
    final controller = ref.read(bookingFormControllerProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color inputFill = isDark
        ? Colors.white.withAlpha((0.06 * 255).round())
        : AppColors.neutral100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva reserva'),
        leading: Builder(
          builder: (ctx) {
            final Color iconColor = isDark
                ? Colors.white
                : AppColors.neutral700;
            return IconButton(
              icon: Icon(Icons.menu, color: iconColor),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            );
          },
        ),
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: const BottomNavBar(),
      body: RefreshIndicator(
        onRefresh: () => controller.refresh(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Text('Reserva de cancha', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Selecciona sede, cancha, fecha y horario seg\u00fan disponibilidad.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
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
            _buildVenueDropdown(state, controller, inputFill),
            const SizedBox(height: 12),
            _buildFieldDropdown(state, controller, inputFill),
            const SizedBox(height: 12),
            _buildDatePicker(state, controller, inputFill, context),
            const SizedBox(height: 12),
            _buildRentalOptions(state, controller, theme, isDark),
            const SizedBox(height: 12),
            _buildSlots(state, controller, theme, isDark),
            const SizedBox(height: 16),
            _buildSummary(state, theme),
            const SizedBox(height: 16),
            _buildSubmit(controller, state),
          ],
        ),
      ),
    );
  }

  Widget _buildVenueDropdown(
    BookingFormState state,
    BookingFormController controller,
    Color inputFill,
  ) {
    return DropdownButtonFormField<int>(
      value: state.selectedVenueId,
      items: state.venues
          .map((v) => DropdownMenuItem(value: v.id, child: Text(v.nombre)))
          .toList(),
      onChanged: state.loadingVenues
          ? null
          : (v) {
              if (v != null) controller.selectVenue(v);
            },
      decoration: InputDecoration(
        labelText: 'Sede',
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      hint: const Text('Elige una sede'),
    );
  }

  Widget _buildFieldDropdown(
    BookingFormState state,
    BookingFormController controller,
    Color inputFill,
  ) {
    final hasFields = state.fields.isNotEmpty;
    return DropdownButtonFormField<int>(
      value: hasFields ? state.selectedFieldId : null,
      items: state.fields
          .map((f) => DropdownMenuItem(value: f.id, child: Text(f.nombre)))
          .toList(),
      onChanged: state.loadingSlots
          ? null
          : (v) {
              if (v != null) controller.selectField(v);
            },
      decoration: InputDecoration(
        labelText: 'Cancha',
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      hint: Text(
        hasFields ? 'Elige una cancha' : 'No hay canchas en esta sede',
      ),
    );
  }

  Widget _buildDatePicker(
    BookingFormState state,
    BookingFormController controller,
    Color inputFill,
    BuildContext context,
  ) {
    final displayDate = _formatDate(state.selectedDate);
    return InkWell(
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
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha',
          filled: true,
          fillColor: inputFill,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(displayDate), const Icon(Icons.calendar_today)],
        ),
      ),
    );
  }

  Widget _buildRentalOptions(
    BookingFormState state,
    BookingFormController controller,
    ThemeData theme,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Duraci\u00f3n', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BookingFormController.rentalOptions.map((opt) {
            final selected = state.selectedRentalId == opt.id;
            final Color labelColor = selected
                ? (isDark ? Colors.black : Colors.white)
                : theme.textTheme.bodyLarge?.color ?? Colors.black;
            return ChoiceChip(
              label: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(opt.label, style: TextStyle(color: labelColor)),
                  if (opt.helper != null)
                    Text(
                      opt.helper!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: labelColor.withOpacity(0.8),
                      ),
                    ),
                ],
              ),
              selected: selected,
              onSelected: (_) => controller.selectRental(opt.id),
              selectedColor: isDark
                  ? Colors.white.withAlpha((0.90 * 255).round())
                  : AppColors.secondary500.withAlpha((0.12 * 255).round()),
              backgroundColor: isDark ? Colors.grey[800]! : AppColors.surface,
              side: BorderSide(
                color: selected
                    ? AppColors.secondary500
                    : (isDark ? AppColors.neutral700 : AppColors.neutral200),
              ),
            );
          }).toList(),
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
        Text('Horarios disponibles', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: state.slots.map((slot) {
            final disabled = slot.ocupado || !controller.canStartAt(slot);
            final selected = state.selectedSlot == slot;
            final Color textColor = disabled
                ? AppColors.neutral400
                : (selected
                      ? (isDark ? Colors.black : Colors.white)
                      : theme.textTheme.bodyMedium?.color ?? Colors.black);
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_slotLabel(slot), style: TextStyle(color: textColor)),
                  if (slot.ocupado)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.lock_clock,
                        size: 16,
                        color: AppColors.neutral400,
                      ),
                    ),
                ],
              ),
              selected: selected,
              onSelected: disabled ? null : (_) => controller.selectSlot(slot),
              selectedColor: isDark
                  ? Colors.white.withAlpha((0.90 * 255).round())
                  : AppColors.primary500,
              backgroundColor: isDark ? Colors.grey[800]! : AppColors.surface,
              disabledColor: isDark ? Colors.grey[800]! : AppColors.neutral100,
              side: BorderSide(
                color: selected
                    ? AppColors.primary700
                    : (isDark ? AppColors.neutral700 : AppColors.neutral200),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSummary(BookingFormState state, ThemeData theme) {
    final Field? field = _selectedField(state);
    final rental = BookingFormController.rentalOptions.firstWhere(
      (r) => r.id == state.selectedRentalId,
      orElse: () => BookingFormController.rentalOptions.first,
    );
    final double pricePerHour = field?.precio ?? 0;
    final double total = pricePerHour * rental.duration.inHours;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Fecha'),
                Text(_formatDate(state.selectedDate)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [const Text('Cancha'), Text(field?.nombre ?? '-')],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Duraci\u00f3n'),
                Text('${rental.duration.inHours} h (${rental.label})'),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Inicio'),
                Text(
                  state.selectedSlot != null
                      ? _slotLabel(state.selectedSlot!)
                      : '-',
                ),
              ],
            ),
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
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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

  Widget _buildSubmit(
    BookingFormController controller,
    BookingFormState state,
  ) {
    final bool disabled =
        state.submitting ||
        state.selectedFieldId == null ||
        state.selectedSlot == null;
    return ElevatedButton(
      onPressed: disabled ? null : () => _onSubmit(controller),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
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

  Future<void> _onSubmit(BookingFormController controller) async {
    final result = await controller.submit();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
    if (result.success) {
      Navigator.of(context).maybePop();
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _slotLabel(ReservationSlot slot) =>
      '${slot.horaInicio.substring(0, 5)} - ${slot.horaFin.substring(0, 5)}';

  Field? _selectedField(BookingFormState state) {
    for (final f in state.fields) {
      if (f.id == state.selectedFieldId) {
        return f;
      }
    }
    return null;
  }
}

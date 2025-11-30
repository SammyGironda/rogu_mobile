import 'package:flutter/material.dart';

import '../widgets/bottom_nav.dart';
import '../widgets/app_drawer.dart';
import '../theme/theme.dart';

class DenunciaScreen extends StatefulWidget {
  static const String routeName = '/denuncia';

  const DenunciaScreen({super.key});

  @override
  State<DenunciaScreen> createState() => _DenunciaScreenState();
}

class _DenunciaScreenState extends State<DenunciaScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _bookingId;
  String? _courtName;
  String _reporterName = '';
  String _reason = '';
  String _details = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _bookingId = args['bookingId'] as String?;
      _courtName = args['courtName'] as String?;
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // Use filled data to show confirmation; in a real app send to backend
    final msg = 'Denuncia enviada para ${_courtName ?? 'la cancha'}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    debugPrint('Denuncia: bookingId=$_bookingId court=$_courtName reporter=$_reporterName reason=$_reason details=$_details');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Denunciar Cancha'),
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
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Denuncia para: ${_courtName ?? '—'}', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Tu nombre'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu nombre' : null,
                        onSaved: (v) => _reporterName = v ?? '',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Motivo (breve)'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Ingresa un motivo' : null,
                        onSaved: (v) => _reason = v ?? '',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Detalles (opcional)'),
                        maxLines: 4,
                        onSaved: (v) => _details = v ?? '',
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _submit, child: const Text('Enviar Denuncia')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/providers.dart';
import '../dashboard/dashboard_screen.dart';
import 'register_screen.dart';
import '../../widgets/gradient_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  static const String routeName = '/login';

  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref
        .read(authProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);

    if (mounted) {
      final error = ref.read(authProvider).error;

      setState(() {
        _isLoading = false;
        _errorMessage = success ? null : (error ?? 'Error al iniciar sesión');
      });

      if (success) {
        Navigator.of(context).pushReplacementNamed(DashboardScreen.routeName);
      } else {
        if (_errorMessage != null && _errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_errorMessage!)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final iconColor = isDark ? Colors.white : Colors.black87;
            return IconButton(
              icon: Icon(Icons.arrow_back, color: iconColor),
              onPressed: () {
                if (Navigator.of(ctx).canPop()) {
                  Navigator.of(ctx).pop();
                } else {
                  Navigator.of(
                    ctx,
                  ).pushReplacementNamed(DashboardScreen.routeName);
                }
              },
            );
          },
        ),
        title: const Text('Iniciar sesión'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header con marca/gradiente
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF3B82F6),
                              Color(0xFF06B6D4),
                              Color(0xFF8B5CF6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(
                          'lib/assets/rogu_logo.png',
                          width: 28,
                          height: 28,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ROGÜ',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Reserva tu cancha favorita',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Bienvenido a Rogu',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu correo';
                      }
                      if (!value.contains('@')) {
                        return 'Correo inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu contraseña';
                      }
                      if (value.length < 8) {
                        return 'La contraseña debe tener al menos 8 caracteres';
                      }
                      if (value.length > 20) {
                        return 'La contraseña no debe superar 20 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Iniciar Sesión'),
                    expand: true,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿No tienes cuenta?'),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text('Regístrate'),
                      ),
                    ],
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

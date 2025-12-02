import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../state/providers.dart';
import 'dashboard/dashboard_screen.dart';
import 'auth/login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  static const String routeName = '/splash';

  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure auth check is triggered if not already
    // ref.read(authProvider); // Accessing it triggers the notifier constructor
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (!next.isLoading) {
        // Add a small delay if needed for visual effect, or just navigate
        if (next.isAuthenticated) {
          Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
        } else {
          Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        }
      }
    });

    // Also check current state in case it's already loaded (e.g. hot reload)
    final authState = ref.watch(authProvider);
    if (!authState.isLoading) {
      // We use a microtask to avoid navigation during build
      // ignore: use_build_context_synchronously
      Future.microtask(() {
        if (!mounted) return;
        if (authState.isAuthenticated) {
          Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
        } else {
          Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        }
      });
    }

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App title / logo placeholder
              Text(
                'ROGU',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.primary600,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gestión y reservas',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

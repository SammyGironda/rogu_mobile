import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/theme.dart';
import 'config/app_config.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/booking_form_screen.dart';
import 'screens/booking_history_screen.dart';
import 'screens/denuncia_screen.dart';
import 'screens/courts_screen.dart';
import 'screens/new_reservation_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/gestion_canchas_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa configuración (baseUrl, flags).
  await AppConfig.init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ROGU Mobile',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // Fija el escalado de texto del sistema a 1.0 para evitar overflows globales
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaleFactor: 1.0),
          child: child ?? const SizedBox.shrink(),
        );
      },
      // Cambiamos la pantalla inicial al Dashboard según solicitud.
      initialRoute: DashboardScreen.routeName,
      routes: {
        SplashScreen.routeName: (context) => const SplashScreen(),
        DashboardScreen.routeName: (context) => const DashboardScreen(),
        QRScannerScreen.routeName: (context) => const QRScannerScreen(),
        UserProfileScreen.routeName: (context) => const UserProfileScreen(),
        BookingFormScreen.routeName: (context) => const BookingFormScreen(),
        BookingHistoryScreen.routeName: (context) =>
            const BookingHistoryScreen(),
        DenunciaScreen.routeName: (context) => const DenunciaScreen(),
        CourtsScreen.routeName: (context) => const CourtsScreen(),
        NewReservationScreen.routeName: (context) =>
            const NewReservationScreen(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        RegisterScreen.routeName: (context) => const RegisterScreen(),
        GestionCanchasScreen.routeName: (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return GestionCanchasScreen(sedeArgs: args);
        },
        // FieldDetailScreen y SelectSlotScreen usan MaterialPageRoute con argumentos dinámicos
      },
    );
  }
}

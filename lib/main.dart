import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/core/theme/app_theme.dart';
import 'src/core/config/app_config.dart';
import 'src/presentation/screens/splash_screen.dart';
import 'src/presentation/screens/dashboard/dashboard_screen.dart';
import 'src/presentation/screens/qr/qr_home_screen.dart';
import 'src/presentation/screens/qr/qr_scanner_screen.dart';
import 'src/presentation/screens/qr/qr_sede_pases_screen.dart';
import 'src/presentation/screens/profile/user_profile_screen.dart';
import 'src/presentation/screens/bookings/booking_form_screen.dart';
import 'src/presentation/screens/bookings/booking_confirm_screen.dart';
import 'src/presentation/screens/bookings/booking_payment_screen.dart';
import 'src/presentation/screens/bookings/booking_qr_screen.dart';
import 'src/presentation/screens/bookings/booking_success_screen.dart';
import 'src/presentation/screens/bookings/booking_history_screen.dart';
import 'src/presentation/screens/dashboard/denuncia_screen.dart';
import 'src/presentation/screens/auth/login_screen.dart';
import 'src/presentation/screens/auth/register_screen.dart';
import 'src/presentation/screens/management/gestion_canchas_screen.dart';
import 'src/features/venues/presentation/venues_screen.dart';
import 'src/features/venues/presentation/venue_detail_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa configuracion (baseUrl, flags).
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
      // Cambiamos la pantalla inicial al Dashboard segun solicitud.
      initialRoute: DashboardScreen.routeName,
      routes: {
        SplashScreen.routeName: (context) => const SplashScreen(),
        DashboardScreen.routeName: (context) => const DashboardScreen(),
        QrHomeScreen.routeName: (context) => const QrHomeScreen(),
        QRScannerScreen.routeName: (context) => const QRScannerScreen(),
        QrSedePasesScreen.routeName: (context) => const QrSedePasesScreen(),
        UserProfileScreen.routeName: (context) => const UserProfileScreen(),
        BookingFormScreen.routeName: (context) => const BookingFormScreen(),
        BookingConfirmScreen.routeName: (context) =>
            const BookingConfirmScreen(),
        BookingPaymentScreen.routeName: (context) =>
            const BookingPaymentScreen(),
        BookingQrScreen.routeName: (context) => const BookingQrScreen(),
        BookingSuccessScreen.routeName: (context) =>
            const BookingSuccessScreen(),
        BookingHistoryScreen.routeName: (context) =>
            const BookingHistoryScreen(),
        DenunciaScreen.routeName: (context) => const DenunciaScreen(),
        VenuesScreen.routeName: (context) => const VenuesScreen(),
        VenueDetailScreen.routeName: (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          final int venueId = (args as int?) ?? 0;
          return VenueDetailScreen(venueId: venueId);
        },
        LoginScreen.routeName: (context) => const LoginScreen(),
        RegisterScreen.routeName: (context) => const RegisterScreen(),
        GestionCanchasScreen.routeName: (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return GestionCanchasScreen(sedeArgs: args);
        },
        // FieldDetailScreen y SelectSlotScreen usan MaterialPageRoute con argumentos dinamicos
      },
    );
  }
}

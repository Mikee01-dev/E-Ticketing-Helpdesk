import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'config/supabase_config.dart';
import 'config/theme_config.dart';
import 'config/routes.dart';
import 'bindings/app_bindings.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/verify_token_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/create_ticket_screen.dart';
import 'screens/ticket_list_screen.dart';
import 'screens/ticket_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notification_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'E-Ticketing Helpdesk',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialBinding: AppBindings(),
      debugShowCheckedModeBanner: false,

      // Pakai AppRoutes dari config
      getPages: [
        GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
        GetPage(name: AppRoutes.login, page: () => LoginScreen()),
        GetPage(name: AppRoutes.register, page: () => RegisterScreen()),
        GetPage(name: AppRoutes.forgotPassword, page: () => ForgotPasswordScreen()),
        GetPage(name: AppRoutes.verifyToken, page: () => VerifyTokenScreen()),
        GetPage(name: AppRoutes.dashboard, page: () => DashboardScreen()),
        GetPage(name: AppRoutes.createTicket, page: () => CreateTicketScreen()),
        GetPage(name: AppRoutes.ticketList, page: () => TicketListScreen()),
        GetPage(name: AppRoutes.profile, page: () => ProfileScreen()),
        GetPage(name: AppRoutes.notifications, page: () => NotificationScreen()),
        GetPage(
          name: AppRoutes.ticketDetail,
          page: () {
            final ticketId = Get.parameters['id']!;
            return TicketDetailScreen(ticketId: ticketId);
          },
        ),
      ],

      unknownRoute: GetPage(
        name: '/not-found',
        page: () => const Scaffold(
          body: Center(child: Text('Halaman tidak ditemukan')),
        ),
      ),

      home: const SplashScreen(),
    );
  }
}
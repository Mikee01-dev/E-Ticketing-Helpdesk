class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String updatePassword = '/update-password';
  static const String dashboard = '/dashboard';
  static const String createTicket = '/create-ticket';
  static const String ticketList = '/tickets';
  static const String ticketDetail = '/ticket/:id';
  static const String profile = '/profile';
  static const String notifications = '/notifications';

  static String ticketDetailRoute(String id) => '/ticket/$id';
}
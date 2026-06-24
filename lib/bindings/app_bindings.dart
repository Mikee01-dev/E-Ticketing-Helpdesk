import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/ticket_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/notification_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<TicketController>(TicketController(), permanent: true);
    Get.put<ThemeController>(ThemeController(), permanent: true);
    Get.put<UserController>(UserController(), permanent: true);
    Get.put<NotificationController>(NotificationController(), permanent: true);
  }
}
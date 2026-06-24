import 'package:get/get.dart';
import '../controllers/ticket_controller.dart';
import '../controllers/auth_controller.dart';

class HomeBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthController>(AuthController());
    Get.put<TicketController>(TicketController());
  }
}
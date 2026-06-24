import 'package:get/get.dart';
import '../controllers/ticket_controller.dart';

class TicketBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TicketController>(() => TicketController());
  }
}
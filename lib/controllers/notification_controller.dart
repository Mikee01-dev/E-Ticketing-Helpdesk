import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'auth_controller.dart';

class NotificationController extends GetxController {
  final RxList<Map<String, dynamic>> notifications = <Map<String, dynamic>>[].obs;
  final RxInt unreadCount = 0.obs;
  final supabase = SupabaseConfig.client;
  final AuthController authController = Get.find<AuthController>();

  @override
  void onInit() {
    super.onInit();
    if (authController.isAuthenticated.value) {
      fetchNotifications();
      subscribeToRealtimeNotifications();
    }
  }

  // ==================== FETCH NOTIFICATIONS ====================
  Future<void> fetchNotifications() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final response = await supabase
        .from('notifications')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    notifications.value = response.map((e) => {
      'id': e['id'],
      'title': e['title'],
      'message': e['message'],
      'type': e['type'],
      'ticketId': e['ticket_id'],
      'isRead': e['is_read'] ?? false,
      'createdAt': DateTime.parse(e['created_at'].toString().replaceFirst('Z', '')).toLocal(),
    }).toList();

    _updateUnreadCount();
  }

  // ==================== REALTIME ====================
  void subscribeToRealtimeNotifications() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    supabase
        .channel('notifications_channel')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        final newNotif = payload.newRecord;
        notifications.insert(0, {
          'id': newNotif['id'],
          'title': newNotif['title'],
          'message': newNotif['message'],
          'type': newNotif['type'],
          'ticketId': newNotif['ticket_id'],
          'isRead': false,
          'createdAt': DateTime.parse(newNotif['created_at']),
        });
        _updateUnreadCount();
      },
    )
        .subscribe();
  }

  // ==================== UPDATE UNREAD COUNT ====================
  void _updateUnreadCount() {
    unreadCount.value = notifications.where((n) => n['isRead'] == false).length;
  }

  // ==================== MARK AS READ ====================
  Future<void> markAsRead(String notificationId) async {
    print('📌 [START] markAsRead for ID: $notificationId');

    try {
      // Update database
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      print('📌 [DB] Update successful');

      // Update UI
      final index = notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        notifications[index]['isRead'] = true;
        notifications.refresh();
        _updateUnreadCount();
        print('📌 [UI] Updated index $index');
      }

      print('📌 [END] markAsRead completed');
    } catch (e) {
      print('❌ [ERROR] markAsRead: $e');
    }
  }

  // ==================== MARK ALL AS READ ====================
  void markAllAsRead() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId);

      for (var notification in notifications) {
        notification['isRead'] = true;
      }
      notifications.refresh();
      unreadCount.value = 0;

      Get.snackbar('Sukses', 'Semua notifikasi ditandai sudah dibaca');
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  // ==================== CLEAR ALL NOTIFICATIONS ====================
  void clearNotifications() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId);

      notifications.clear();
      unreadCount.value = 0;

      Get.snackbar('Sukses', 'Semua notifikasi dihapus');
    } catch (e) {
      print('❌ Error: $e');
      Get.snackbar('Error', 'Gagal menghapus notifikasi');
    }
  }

  // ==================== ADD NOTIFICATION ====================
  Future<void> addNotification({
    required String userId,
    required String ticketId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      await supabase.from('notifications').insert({
        'user_id': userId,
        'ticket_id': ticketId,
        'title': title,
        'message': message,
        'type': type,
        'created_at': DateTime.now().toIso8601String(),
      });
      print('✅ Notification added for user: $userId');
    } catch (e) {
      print('❌ Error adding notification: $e');
    }
  }
}
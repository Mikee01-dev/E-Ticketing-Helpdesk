import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import '../utils/date_formatter.dart';

class NotificationScreen extends StatelessWidget {
  NotificationScreen({super.key});

  final notificationController = Get.find<NotificationController>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () async {
              print('🔄 Manual refresh clicked');
              await notificationController.fetchNotifications();
              print('📊 After refresh: ${notificationController.notifications.length}');
            },
          ),
          IconButton(
            icon: const Icon(Icons.checklist),
            tooltip: 'Tandai semua sudah dibaca',
            onPressed: () {
              print('📌 Mark all as read clicked');
              notificationController.markAllAsRead();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Hapus semua notifikasi',
            onPressed: () {
              print('🗑️ Clear all clicked');
              notificationController.clearNotifications();
            },
          ),
        ],
      ),
      body: Obx(() {
        print('🔄 Obx rebuilding, notifications length: ${notificationController.notifications.length}');

        if (notificationController.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada notifikasi',
                  style: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: notificationController.notifications.length,
          itemBuilder: (context, index) {
            final notification = notificationController.notifications[index];
            final isUnread = notification['isRead'] == false;

            print('📋 Item $index: id=${notification['id']}, isRead=${notification['isRead']}, isUnread=$isUnread');

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isUnread
                    ? Colors.blue
                    : (isDark ? Colors.grey[800] : Colors.grey[300]),
                child: Icon(
                  notification['type'] == 'status_update'
                      ? Icons.update
                      : Icons.comment,
                  color: isUnread ? Colors.white : Colors.grey,
                  size: 20,
                ),
              ),
              title: Text(
                notification['title'],
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  color: isUnread ? Colors.blue : null,
                ),
              ),
              subtitle: Text(notification['message']),
              trailing: Text(
                DateFormatter.timeAgo(notification['createdAt']),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
              ),
              onTap: () async {
                print('📌 Tapped notification: ${notification['id']}, isUnread=$isUnread');

                if (isUnread) {
                  print('📌 Marking as read...');
                  await notificationController.markAsRead(notification['id']);
                  print('📌 Mark as read completed');
                }

                if (notification['ticketId'] != null) {
                  print('📌 Navigating to ticket: ${notification['ticketId']}');
                  Get.toNamed('/ticket/${notification['ticketId']}');
                }
              },
            );
          },
        );
      }),
    );
  }
}
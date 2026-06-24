import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ticket_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/ticket_log_model.dart';
import '../models/comment_model.dart';
import '../widgets/status_badge.dart';
import '../widgets/priority_badge.dart';
import '../widgets/loading_widget.dart';
import '../utils/date_formatter.dart';
import 'assign_ticket_screen.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final ticketController = Get.find<TicketController>();
  final authController = Get.find<AuthController>();
  final commentController = TextEditingController();

  final RxList<TicketLogModel> ticketLogs = <TicketLogModel>[].obs;
  final RxBool isLoadingLogs = false.obs;
  final RxString assignedToName = ''.obs;

  final RxList<CommentModel> comments = <CommentModel>[].obs;
  final RxBool isLoadingComments = false.obs;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadTicketLogs();
    _loadComments();
  }

  Future<void> _loadData() async {
    await ticketController.fetchTickets();

    final ticket = ticketController.tickets.firstWhereOrNull(
          (t) => t.id == widget.ticketId,
    );
    await _loadAssignedToName(ticket?.assignedTo);
  }

  Future<void> _loadAssignedToName(String? assignedToId) async {
    if (assignedToId != null && assignedToId.isNotEmpty) {
      final name = await ticketController.getAssignedToName(assignedToId);
      assignedToName.value = name ?? 'Helpdesk';
    } else {
      assignedToName.value = 'Belum diassign';
    }
  }

  Future<void> _loadTicketLogs() async {
    isLoadingLogs.value = true;
    try {
      final logs = await ticketController.getTicketLogs(widget.ticketId);
      ticketLogs.value = logs;
    } catch (e) {
      debugPrint('Error loading logs: $e');
    } finally {
      isLoadingLogs.value = false;
    }
  }

  Future<void> _loadComments() async {
    isLoadingComments.value = true;
    try {
      final data = await ticketController.getComments(widget.ticketId);
      comments.value = data;
    } catch (e) {
      debugPrint('Error loading comments: $e');
    } finally {
      isLoadingComments.value = false;
    }
  }

  Future<void> _sendComment() async {
    final message = commentController.text.trim();
    if (message.isEmpty) return;

    try {
      await ticketController.addComment(widget.ticketId, message);
      commentController.clear();
      await _loadComments();
    } catch (e) {
      Get.snackbar('Error', 'Gagal mengirim komentar');
    }
  }

  void _showUpdateStatusDialog(String ticketId, String currentStatus) {
    final selectedStatus = RxString(currentStatus);
    final noteController = TextEditingController();

    List<Map<String, String>> getAvailableStatuses() {
      switch (currentStatus) {
        case 'open':
          return [
            {'value': 'in_progress', 'label': 'In Progress'},
            {'value': 'resolved', 'label': 'Resolved'},
            {'value': 'closed', 'label': 'Closed'},
          ];
        case 'in_progress':
          return [
            {'value': 'resolved', 'label': 'Resolved'},
            {'value': 'closed', 'label': 'Closed'},
          ];
        case 'resolved':
          return [
            {'value': 'closed', 'label': 'Closed'},
          ];
        default:
          return [];
      }
    }

    final statuses = getAvailableStatuses();

    if (statuses.isEmpty) {
      Get.snackbar('Info', 'Tiket sudah ditutup, tidak dapat diubah lagi');
      return;
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Update Status Tiket'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih Status Baru:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Obx(() => Column(
              children: statuses.map((status) {
                return RadioListTile(
                  title: Text(status['label']!),
                  value: status['value'],
                  groupValue: selectedStatus.value,
                  onChanged: (value) => selectedStatus.value = value.toString(),
                  activeColor: status['value'] == 'resolved' ? Colors.green
                      : status['value'] == 'closed' ? Colors.red
                      : Colors.blue,
                );
              }).toList(),
            )),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Catatan (Opsional):',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: 'Masukkan catatan...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedStatus.value != currentStatus) {
                await ticketController.updateTicketStatus(
                  ticketId,
                  selectedStatus.value,
                  note: noteController.text.isNotEmpty ? noteController.text : null,
                );
                // Refresh data setelah update
                await _loadData();
                await _loadTicketLogs();
              }
              // Tutup dialog dengan Get.back()
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteTicket(String ticketId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Tiket'),
        content: const Text('Apakah Anda yakin ingin menghapus tiket ini?\n\nTindakan ini tidak dapat dibatalkan.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await ticketController.deleteTicket(ticketId);
      Navigator.pop(context);

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tiket berhasil dihapus')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = ticketController.tickets.firstWhereOrNull(
          (t) => t.id == widget.ticketId,
    );

    if (ticket == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Tiket')),
        body: const LoadingWidget(),
      );
    }

    final isAssignedToMe = ticket.assignedTo == authController.currentUser.value?.id;
    final isAdmin = authController.isAdmin();

    return Scaffold(
      appBar: AppBar(
        title: Text('Tiket ${ticket.ticketNumber}'),
        elevation: 0,
        actions: [
          // Tombol Assign - hanya Admin (untuk tiket yang belum diassign)
          if (isAdmin && ticket.assignedTo == null)
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Assign Tiket',
              onPressed: () => Get.to(
                () => AssignTicketScreen(
                  ticketId: ticket.id,
                  ticketNumber: ticket.ticketNumber,
                ),
              ),
            ),

          // Tombol Ganti Assignee - hanya Admin (untuk tiket yang sudah diassign)
          if (isAdmin && ticket.assignedTo != null)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Ganti Assignee',
              onPressed: () => Get.to(
                () => AssignTicketScreen(
                  ticketId: ticket.id,
                  ticketNumber: ticket.ticketNumber,
                ),
              ),
            ),

          // Tombol Hapus - hanya Admin
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus Tiket',
              onPressed: () => _confirmDeleteTicket(ticket.id),
            ),

          // Tombol Update Status - untuk Admin ATAU Helpdesk yang ditunjuk
          if ((authController.isHelpdesk() && isAssignedToMe) || isAdmin)
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: 'Update Status',
              onPressed: () => _showUpdateStatusDialog(ticket.id, ticket.status),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadData();
          await _loadTicketLogs();
          await _loadComments();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dibuat ${DateFormatter.timeAgo(ticket.createdAt)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusBadge(status: ticket.status),
                      const SizedBox(height: 4),
                      PriorityBadge(priority: ticket.priority),
                    ],
                  ),
                ],
              ),
              const Divider(height: 32),

              // Assigned info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ticket.assignedTo != null 
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      ticket.assignedTo != null ? Icons.person : Icons.person_outline,
                      color: ticket.assignedTo != null ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.assignedTo != null ? 'Ditangani oleh:' : 'Belum diassign',
                            style: TextStyle(
                              fontSize: 12,
                              color: ticket.assignedTo != null ? Colors.green : Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Obx(() => Text(
                            assignedToName.value,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Deskripsi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(ticket.description),

              if (ticket.imageUrl != null && ticket.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    ticket.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, size: 50),
                      );
                    },
                  ),
                ),
              ],

              const Divider(height: 32),

              const Text(
                'Riwayat Tiket',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Obx(() {
                if (isLoadingLogs.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (ticketLogs.isEmpty) {
                  return Text(
                    'Belum ada riwayat',
                    style: TextStyle(color: Colors.grey[600]),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ticketLogs.length,
                  itemBuilder: (context, index) {
                    final log = ticketLogs[index];
                    return _buildHistoryItem(log);
                  },
                );
              }),

              const Divider(height: 32),

              const Text(
                'Komentar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Obx(() {
                if (isLoadingComments.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (comments.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Belum ada komentar',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipOval(
                            child: Container(
                              width: 32,
                              height: 32,
                              color: Colors.grey[300],
                              child: comment.avatarUrl != null && comment.avatarUrl!.isNotEmpty
                                  ? Image.network(
                                      comment.avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Center(
                                          child: Text(
                                            comment.userName?.substring(0, 1).toUpperCase() ?? '?',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        );
                                      },
                                    )
                                  : Center(
                                      child: Text(
                                        comment.userName?.substring(0, 1).toUpperCase() ?? '?',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      comment.userName ?? 'User',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormatter.timeAgo(comment.createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(comment.message),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2C2C2C)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tulis komentar...',
                          hintStyle: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[500]
                                : Colors.grey[400],
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendComment(),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.send,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: _sendComment,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(TicketLogModel log) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: log.actionColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                log.actionIcon,
                size: 18,
                color: log.actionColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.actionText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Oleh: ${log.changedByName ?? log.changedBy}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  DateFormatter.formatDateTime(log.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                if (log.note != null && log.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2C2C2C)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Catatan : ${log.note}',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[300]
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
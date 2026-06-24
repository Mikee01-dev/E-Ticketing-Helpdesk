import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/ticket_model.dart';
import '../models/ticket_log_model.dart';
import '../models/comment_model.dart';
import 'auth_controller.dart';
import 'user_controller.dart';
import 'notification_controller.dart';

class TicketController extends GetxController {
  final RxList<TicketModel> tickets = <TicketModel>[].obs;
  final RxList<TicketModel> allTickets = <TicketModel>[].obs;
  final RxList<TicketModel> _allUserTickets = <TicketModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString filterStatus = 'all'.obs;
  final RxString filterPriority = 'all'.obs;

  final supabase = SupabaseConfig.client;
  final AuthController authController = Get.find<AuthController>();

  @override
  void onInit() {
    super.onInit();
    fetchTickets();
    subscribeToRealtimeUpdates();
  }

  Future<void> fetchTickets() async {
    isLoading.value = true;
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      late List<dynamic> response;

      if (authController.isAdmin()) {
        response = await supabase
            .from('tickets')
            .select('*, profiles!user_id(name)')
            .eq('is_deleted', false)
            .order('created_at', ascending: false);

        final ticketList = response.map((e) => TicketModel.fromMap(e)).toList();
        allTickets.value = ticketList;
        _allUserTickets.value = ticketList;
        tickets.value = ticketList;
      } 
      else if (authController.isHelpdesk()) {
        // Helpdesk hanya lihat tiket yang diassign ke dirinya
        response = await supabase
            .from('tickets')
            .select('*, profiles!user_id(name)')
            .eq('assigned_to', userId)
            .eq('is_deleted', false)
            .order('created_at', ascending: false);

        final ticketList = response.map((e) => TicketModel.fromMap(e)).toList();
        allTickets.value = ticketList;  // Simpan ke allTickets
        _allUserTickets.value = ticketList;
        tickets.value = ticketList;
      } 
      else {
        // User biasa hanya lihat tiket sendiri
        response = await supabase
            .from('tickets')
            .select('*, profiles!user_id(name)')
            .eq('user_id', userId)
            .eq('is_deleted', false)
            .order('created_at', ascending: false);
      }

      final ticketList = response.map((e) => TicketModel.fromMap(e)).toList();
      tickets.value = ticketList;
      allTickets.value = ticketList;
      _allUserTickets.value = ticketList;

      applyFilters();
    } catch (e) {
      debugPrint('Error fetching tickets: $e');
      Get.snackbar('Error', 'Gagal mengambil data tiket');
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== FILTERS ====================
  void setFilterStatus(String status) {
    filterStatus.value = status;
    applyFilters();
    tickets.refresh();
  }

  void setFilterPriority(String priority) {
    filterPriority.value = priority;
    applyFilters();
    tickets.refresh();
  }

  void applyFilters() {
    // Gunakan data asli berdasarkan role
    final sourceList = authController.isHelpdesk()
        ? allTickets.toList()
        : _allUserTickets.toList();

    var filtered = List<TicketModel>.from(sourceList);

    if (filterStatus.value != 'all') {
      filtered = filtered.where((t) => t.status == filterStatus.value).toList();
    }

    if (filterPriority.value != 'all') {
      filtered = filtered.where((t) => t.priority == filterPriority.value).toList();
    }

    tickets.value = filtered;

  }

  // ==================== CREATE TICKET ====================
  Future<void> createTicket({
    required String title,
    required String description,
    String? imageUrl,
    String? category,
    String priority = 'medium',
  }) async {
    isLoading.value = true;
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      await supabase.from('tickets').insert({
        'title': title,
        'description': description,
        'image_url': imageUrl,
        'category': category,
        'priority': priority,
        'user_id': userId,
        'status': 'open',
      });

      await fetchTickets();
      Get.back();
      Get.snackbar('Sukses', 'Tiket berhasil dibuat');
    } catch (e) {
      Get.snackbar('Error', 'Gagal membuat tiket: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== UPDATE STATUS ====================
  Future<void> updateTicketStatus(
    String ticketId,
    String newStatus, {
    String? note,
  }) async {
    if (!authController.isHelpdesk()) {
      Get.snackbar('Error', 'Anda tidak memiliki akses');
      return;
    }

    isLoading.value = true;
    try {
      final currentTicket = tickets.firstWhereOrNull((t) => t.id == ticketId);
      if (currentTicket == null) return;

      // CEK: Admin bisa update semua tiket
      // CEK: Helpdesk hanya bisa update tiket yang diassign ke dirinya
      if (!authController.isAdmin() && currentTicket.assignedTo != supabase.auth.currentUser?.id) {
        Get.snackbar('Error', 'Anda tidak memiliki akses ke tiket ini');
        return;
      }

      // CEK: Tiket sudah closed?
      if (currentTicket.status == 'closed') {
        Get.snackbar('Info', 'Tiket sudah ditutup, tidak dapat diubah lagi');
        return;
      }

      final currentStatus = currentTicket.status;

      await supabase
          .from('tickets')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', ticketId);

      // Insert ke ticket_logs
      final userId = supabase.auth.currentUser?.id;
      await supabase.from('ticket_logs').insert({
        'ticket_id': ticketId,
        'status_from': currentStatus,
        'status_to': newStatus,
        'changed_by': userId,
        'note': note ?? 'Status updated from $currentStatus to $newStatus',
        'created_at': DateTime.now().toIso8601String(),
      });

      // KIRIM NOTIFIKASI ke PEMILIK TIKET
      if (currentTicket.userId != userId) {
        final notificationController = Get.find<NotificationController>();
        await notificationController.addNotification(
          userId: currentTicket.userId,
          ticketId: ticketId,
          title: 'Status Tiket Berubah',
          message: 'Status tiket #${currentTicket.ticketNumber} berubah dari $currentStatus menjadi $newStatus',
          type: 'status_update',
        );
      }

      await fetchTickets();
      Get.snackbar('Sukses', 'Status tiket diperbarui menjadi ${_getStatusText(newStatus)}');
    } catch (e) {
      Get.snackbar('Error', 'Gagal update status: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== ASSIGN TICKET (HANYA ADMIN) ====================
  Future<void> assignTicket(String ticketId, String assignedToId) async {
    if (!authController.isAdmin()) {
      Get.snackbar('Error', 'Hanya admin yang dapat assign tiket');
      return;
    }

    isLoading.value = true;
    try {
      final userController = Get.find<UserController>();
      final helpdesk = await userController.getHelpdeskById(assignedToId);
      final helpdeskName = helpdesk?.name ?? 'Helpdesk';
      
      // Ambil data tiket sebelum update
      final currentTicket = tickets.firstWhereOrNull((t) => t.id == ticketId);
      if (currentTicket == null) return;

      // Update tiket
      await supabase
          .from('tickets')
          .update({
            'assigned_to': assignedToId,
            'status': 'in_progress',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', ticketId);

      // INSERT KE HISTORY (ticket_logs)
      final userId = supabase.auth.currentUser?.id;
      await supabase.from('ticket_logs').insert({
        'ticket_id': ticketId,
        'status_from': currentTicket.status,
        'status_to': 'in_progress',
        'changed_by': userId,
        'note': 'Tiket diassign ke $helpdeskName',
        'created_at': DateTime.now().toIso8601String(),
      });

      // KIRIM NOTIFIKASI ke pemilik tiket (jika bukan admin sendiri)
      if (currentTicket.userId != userId) {
        final notificationController = Get.find<NotificationController>();
        await notificationController.addNotification(
          userId: currentTicket.userId,
          ticketId: ticketId,
          title: 'Tiket Diassign',
          message: 'Tiket #${currentTicket.ticketNumber} telah diassign ke $helpdeskName',
          type: 'assigned',
        );
      }

      await fetchTickets();

      Get.back();
      Get.snackbar(
        'Sukses',
        'Tiket telah diassign ke $helpdeskName',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar('Error', 'Gagal assign tiket: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== GET ASSIGNED TO NAME ====================
  Future<String?> getAssignedToName(String assignedToId) async {
    print('🔍 getAssignedToName called with ID: $assignedToId');

    if (assignedToId.isEmpty) {
      print('⚠️ ID is empty');
      return null;
    }

    try {
      final response = await supabase
          .from('profiles')
          .select('name')
          .eq('id', assignedToId)
          .single();

      print('✅ Response from Supabase: $response');
      print('✅ Name found: ${response['name']}');

      return response['name'];
    } catch (e) {
      print('❌ Error: $e');
      return null;
    }
  }

  // ==================== REALTIME ====================
  void subscribeToRealtimeUpdates() {
    supabase
        .channel('tickets_channel')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'tickets',
      callback: (payload) {
        fetchTickets();
      },
    )
        .subscribe();
  }

  // ==================== GET SINGLE TICKET ====================
  Future<TicketModel?> getTicketById(String id) async {
    try {
      final response = await supabase
          .from('tickets')
          .select('*, profiles!user_id(name)')
          .eq('id', id)
          .single();

      return TicketModel.fromMap(response);
    } catch (e) {
      debugPrint('Error getting ticket by id: $e');
      return null;
    }
  }

  // ==================== STATISTICS ====================
  Map<String, dynamic> getTicketStats() {
    // Untuk Admin/Helpdesk pakai allTickets
    // Untuk User biasa pakai _allUserTickets
    final sourceList = authController.isHelpdesk() 
        ? allTickets.toList() 
        : _allUserTickets.toList();

    return {
      'total': sourceList.length,
      'open': sourceList.where((t) => t.status == 'open').length,
      'in_progress': sourceList.where((t) => t.status == 'in_progress').length,
      'resolved': sourceList.where((t) => t.status == 'resolved').length,
      'closed': sourceList.where((t) => t.status == 'closed').length,
    };
  }

  // ==================== HELPER ====================
  String _getStatusText(String status) {
    switch (status) {
      case 'open': return 'Open';
      case 'in_progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      case 'closed': return 'Closed';
      default: return status;
    }
  }

  // ==================== GET TICKET LOGS ====================
  Future<List<TicketLogModel>> getTicketLogs(String ticketId) async {
    try {
      final response = await supabase
          .from('ticket_logs')
          .select('*, profiles!fk_ticket_logs_changed_by(name)')
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true);

      return response.map((e) => TicketLogModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error getting ticket logs: $e');
      return [];
    }
  }

  // ==================== DELETE TICKET (Admin only) ====================
  Future<bool> deleteTicket(String ticketId) async {
    if (!authController.isAdmin()) {
      Get.snackbar('Error', 'Hanya admin yang dapat menghapus tiket');
      return false;
    }

    isLoading.value = true;
    try {
      // Soft delete
      await supabase.from('tickets').update({
        'deleted_at': DateTime.now().toIso8601String(),
        'is_deleted': true,
      }).eq('id', ticketId);

      await fetchTickets();
      Get.snackbar('Sukses', 'Tiket berhasil dihapus (soft delete)');
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Gagal menghapus tiket: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<CommentModel>> getComments(String ticketId) async {
    try {
      final response = await supabase
          .from('comments')
          .select('*')
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true);

      if (response.isEmpty) return [];

      final List<String> userIds = response.map((e) => e['user_id'] as String).toSet().toList();
      final Map<String, String> userNames = {};
      final Map<String, String> userAvatarUrls = {};

      if (userIds.isNotEmpty) {
        final profiles = await supabase
            .from('profiles')
            .select('id, name,avatar_url')
            .inFilter('id', userIds);

        for (var profile in profiles) {
          userNames[profile['id']] = profile['name'];
          userAvatarUrls[profile['id']] = profile['avatar_url'] ?? '';
        }
      }

      return response.map((e) {
        final userId = e['user_id'] as String;
        return CommentModel(
          id: e['id'] ?? '',
          ticketId: e['ticket_id'] ?? '',
          userId: userId,
          message: e['message'] ?? '',
          imageUrl: e['image_url'],
          avatarUrl: userAvatarUrls[userId],
          userName: userNames[userId],
          createdAt: DateTime.parse(e['created_at']).toLocal(),
        );
      }).toList();
    } catch (e) {
      print('❌ Error: $e');
      return [];
    }
  }

  // ==================== ADD COMMENT ====================
  Future<void> addComment(String ticketId, String message) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Ambil data tiket untuk tahu siapa pemiliknya
      final ticket = await supabase
          .from('tickets')
          .select('user_id, ticket_number')
          .eq('id', ticketId)
          .single();

      await supabase.from('comments').insert({
        'ticket_id': ticketId,
        'user_id': userId,
        'message': message,
      });

      // Kirim notifikasi ke pemilik tiket (jika bukan dia sendiri)
      if (ticket != null && ticket['user_id'] != userId) {
        final notificationController = Get.find<NotificationController>();
        await notificationController.addNotification(
          userId: ticket['user_id'],
          ticketId: ticketId,
          title: 'Komentar Baru',
          message: 'Ada komentar baru di tiket #${ticket['ticket_number']}',
          type: 'new_comment',
        );
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }
}
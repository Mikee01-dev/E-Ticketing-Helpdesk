import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ticket_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/user_controller.dart';
import '../widgets/ticket_card.dart';
import '../widgets/empty_state_widget.dart';
import '../models/user_model.dart';
import 'ticket_detail_screen.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  final ticketController = Get.find<TicketController>();
  final authController = Get.find<AuthController>();
  final userController = Get.find<UserController>();

  List<UserModel> helpdesks = [];

  @override
  void initState() {
    super.initState();
    ticketController.fetchTickets();
    _loadHelpdesks();
  }

  Future<void> _loadHelpdesks() async {
    if (authController.isAdmin()) {
      helpdesks = await userController.getAllHelpdesk();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = authController.isAdmin();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tiket'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ticketController.fetchTickets(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ticketController.fetchTickets(),
        child: Obx(() {
          if (ticketController.isLoading.value && ticketController.tickets.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (ticketController.tickets.isEmpty) {
            return EmptyStateWidget(
              title: 'Belum Ada Tiket',
              message: 'Buat tiket pertama Anda sekarang',
              icon: Icons.inbox,
              buttonText: 'Buat Tiket',
              onButtonPressed: () => Get.back(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: ticketController.tickets.length,
            itemBuilder: (context, index) {
              final ticket = ticketController.tickets[index];
              return TicketCard(
                ticket: ticket,
                onTap: () => Get.to(
                  () => TicketDetailScreen(ticketId: ticket.id),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  void _showFilterDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = authController.isAdmin();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Filter Tiket',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isAdmin) ...[
                    Text(
                      'Helpdesk',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        underline: const SizedBox(),
                        value: ticketController.filterHelpdesk.value,
                        dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('Semua Helpdesk'),
                          ),
                          ...helpdesks.map((h) {
                            return DropdownMenuItem<String>(
                              value: h.id,
                              child: Text(h.name),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            ticketController.setFilterHelpdesk(value);
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Filter Status
                  Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip('Semua', 'all', isDark),
                      _buildFilterChip('Open', 'open', isDark),
                      _buildFilterChip('In Progress', 'in_progress', isDark),
                      _buildFilterChip('Resolved', 'resolved', isDark),
                      _buildFilterChip('Closed', 'closed', isDark),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Filter Priority
                  Text(
                    'Prioritas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildPriorityFilterChip('Semua', 'all', isDark),
                      _buildPriorityFilterChip('Low', 'low', isDark),
                      _buildPriorityFilterChip('Medium', 'medium', isDark),
                      _buildPriorityFilterChip('High', 'high', isDark),
                      _buildPriorityFilterChip('Urgent', 'urgent', isDark),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Tombol Reset
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        ticketController.setFilterStatus('all');
                        ticketController.setFilterPriority('all');
                        if (isAdmin) {
                          ticketController.setFilterHelpdesk('all');
                        }
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: isDark ? Colors.grey[600]! : Colors.grey[400]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Reset Filter',
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = ticketController.filterStatus.value == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? Theme.of(context).primaryColor
              : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
      selected: isSelected,
      onSelected: (_) {
        ticketController.setFilterStatus(value);
        Navigator.pop(context);
      },
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildPriorityFilterChip(String label, String value, bool isDark) {
    final isSelected = ticketController.filterPriority.value == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? Theme.of(context).primaryColor
              : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
      selected: isSelected,
      onSelected: (_) {
        ticketController.setFilterPriority(value);
        Navigator.pop(context);
      },
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }
}
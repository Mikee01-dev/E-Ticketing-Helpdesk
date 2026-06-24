import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ticket_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../models/user_model.dart';

class AssignTicketScreen extends StatefulWidget {
  final String ticketId;
  final String ticketNumber;
  
  const AssignTicketScreen({
    super.key,
    required this.ticketId,
    required this.ticketNumber,
  });

  @override
  State<AssignTicketScreen> createState() => _AssignTicketScreenState();
}

class _AssignTicketScreenState extends State<AssignTicketScreen> {
  final ticketController = Get.find<TicketController>();
  final userController = Get.find<UserController>();
  final authController = Get.find<AuthController>();
  
  String? selectedHelpdeskId;
  String searchQuery = '';
  List<UserModel> filteredHelpdesks = [];
  List<UserModel> allHelpdesks = [];
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadHelpdesks();
  }
  
  Future<void> _loadHelpdesks() async {
    setState(() {
      isLoading = true;
    });
    
    allHelpdesks = await userController.getAllHelpdesk();
    filteredHelpdesks = allHelpdesks;
    
    setState(() {
      isLoading = false;
    });
  }
  
  void _filterHelpdesks(String query) {
    searchQuery = query;
    if (query.isEmpty) {
      filteredHelpdesks = allHelpdesks;
    } else {
      filteredHelpdesks = allHelpdesks.where((h) {
        return h.name.toLowerCase().contains(query.toLowerCase()) ||
            h.email.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    setState(() {});
  }
  
  Future<void> _handleAssign() async {
    if (selectedHelpdeskId != null) {
      await ticketController.assignTicket(
        widget.ticketId,
        selectedHelpdeskId!,
      );
      Get.back(result: true);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assign Tiket #${widget.ticketNumber}'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari helpdesk...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: _filterHelpdesks,
            ),
          ),
          
          // Helpdesk list
          Expanded(
            child: _buildHelpdeskList(),
          ),
          
          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }
  
  Widget _buildHelpdeskList() {
    if (isLoading) {
      return const Center(child: LoadingWidget(message: 'Memuat data helpdesk...'));
    }
    
    if (allHelpdesks.isEmpty) {
      return EmptyStateWidget(
        title: 'Tidak Ada Helpdesk',
        message: 'Belum ada helpdesk yang terdaftar. Hubungi admin.',
        icon: Icons.person_off,
      );
    }
    
    if (filteredHelpdesks.isEmpty) {
      return EmptyStateWidget(
        title: 'Helpdesk Tidak Ditemukan',
        message: 'Tidak ada helpdesk yang sesuai dengan pencarian "$searchQuery"',
        icon: Icons.search_off,
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredHelpdesks.length,
      itemBuilder: (context, index) {
        final helpdesk = filteredHelpdesks[index];
        final isSelected = selectedHelpdeskId == helpdesk.id;
        final isCurrentUser = helpdesk.id == authController.currentUser.value?.id;
        
        return _buildHelpdeskCard(helpdesk, isSelected, isCurrentUser);
      },
    );
  }
  
  // Menggunakan InkWell + Container (menghindari RadioListTile deprecated)
  Widget _buildHelpdeskCard(UserModel helpdesk, bool isSelected, bool isCurrentUser) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected 
              ? Theme.of(context).primaryColor 
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedHelpdeskId = helpdesk.id;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Radio button manual
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Avatar
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: Text(
                  helpdesk.initials,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      helpdesk.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      helpdesk.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (isCurrentUser)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Anda',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Check icon if selected
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Batal',
              isOutlined: true,
              onPressed: () => Get.back(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomButton(
              text: 'Assign Tiket',
              onPressed: selectedHelpdeskId == null
                  ? () {}
                  : () => _handleAssign(), // Perbaikan: pakai fungsi terpisah
            ),
          ),
        ],
      ),
    );
  }
}
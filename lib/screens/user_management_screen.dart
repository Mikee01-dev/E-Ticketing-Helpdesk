import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/user_controller.dart';
import '../models/user_model.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final userController = Get.find<UserController>();
  List<UserModel> users = [];
  List<UserModel> filteredUsers = [];
  bool isLoading = true;
  String searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }
  
  Future<void> _loadUsers() async {
    setState(() {
      isLoading = true;
    });
    
    final data = await userController.getAllUsersSafe();
    
    data.sort((a, b) {
      final roleOrder = {'admin': 0, 'helpdesk': 1, 'user': 2};
      final orderA = roleOrder[a.role] ?? 3;
      final orderB = roleOrder[b.role] ?? 3;
      if (orderA != orderB) return orderA.compareTo(orderB);
      return a.name.compareTo(b.name);
    });
    
    setState(() {
      users = data;
      filteredUsers = data;
      isLoading = false;
    });
  }
  
  void _filterUsers(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredUsers = users;
      } else {
        filteredUsers = users.where((user) {
          return user.name.toLowerCase().contains(query.toLowerCase()) ||
                 user.email.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }
  
  Future<void> _updateRole(UserModel user, String newRole) async {
    final success = await userController.updateUserRole(user.id, newRole);
    if (success) {
      await _loadUsers();
      Get.snackbar('Sukses', 'Role ${user.name} diubah menjadi $newRole');
    }
  }
  
  Future<void> _toggleActive(UserModel user) async {
    final success = await userController.toggleUserActive(user.id);
    if (success) {
      await _loadUsers();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final currentUser = userController.authController.currentUser.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola User'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari user...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
              onChanged: _filterUsers,
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'User "$searchQuery" tidak ditemukan',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final isCurrentUser = currentUser?.id == user.id;
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                            backgroundColor: user.avatarUrl == null || user.avatarUrl!.isEmpty
                                ? (user.role == 'admin' 
                                    ? Colors.red 
                                    : (user.role == 'helpdesk' ? Colors.blue : Colors.grey))
                                : null,
                            child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                                ? Text(user.name[0].toUpperCase())
                                : null,
                          ),
                          title: Text(
                            user.name,
                            style: TextStyle(
                              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text('${user.email} • Role: ${user.role}'),
                          trailing: isCurrentUser
                              ? Chip(
                                  label: Text(
                                    'Anda',
                                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                                  ),
                                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        user.isActive ? Icons.person_off : Icons.person,
                                        color: user.isActive ? Colors.red : Colors.green,
                                        size: 20,
                                      ),
                                      tooltip: user.isActive ? 'Nonaktifkan' : 'Aktifkan',
                                      onPressed: () => _toggleActive(user),
                                    ),
                                    DropdownButton<String>(
                                      value: user.role,
                                      dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black,
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'user', child: Text('User')),
                                        DropdownMenuItem(value: 'helpdesk', child: Text('Helpdesk')),
                                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                      ],
                                      onChanged: (newRole) {
                                        if (newRole != null && newRole != user.role) {
                                          _updateRole(user, newRole);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
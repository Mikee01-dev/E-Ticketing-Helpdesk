import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/auth_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/user_controller.dart';
import '../config/supabase_config.dart';
import '../utils/dialog_helper.dart';
import 'user_management_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final authController = Get.find<AuthController>();
  final themeController = Get.find<ThemeController>();
  final userController = Get.find<UserController>();

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final user = authController.currentUser.value;

    return Scaffold(
      appBar: _buildAppBar(),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Obx(() => _buildProfileContent(user)),
    );
  }

  // ==================== APP BAR ====================
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Profil'),
      elevation: 0,
      actions: [
        if (authController.isAdmin())
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Kelola User',
            onPressed: () => Get.to(() => const UserManagementScreen()),
          ),
      ],
    );
  }

  // ==================== PROFILE CONTENT ====================
  Widget _buildProfileContent(user) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAvatar(user),
        const SizedBox(height: 16),
        _buildUserInfo(user),
        const SizedBox(height: 24),
        _buildActionButtons(user),
        const SizedBox(height: 16),
        _buildSettingsMenu(),
        const Divider(),
        _buildLogoutButton(),
      ],
    );
  }

  // ==================== AVATAR ====================
  Widget _buildAvatar(user) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue,
            backgroundImage: authController.currentUser.value?.avatarUrl != null
                ? NetworkImage(authController.currentUser.value!.avatarUrl!)
                : null,
            child: authController.currentUser.value?.avatarUrl == null
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 40, color: Colors.white),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).primaryColor,
              child: IconButton(
                icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                onPressed: _pickAndUploadAvatar,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== USER INFO ====================
  Widget _buildUserInfo(user) {
    return Center(
      child: Column(
        children: [
          Text(
            authController.currentUser.value?.name ?? user.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.role.toUpperCase(),
              style: const TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ACTION BUTTONS ====================
  Widget _buildActionButtons(user) {
    return Column(
      children: [
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profil'),
            onPressed: () => _showEditDialog(user.name),
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.lock, color: Colors.blue),
          title: const Text('Ganti Password'),
          onTap: _showChangePasswordDialog,
        ),
      ],
    );
  }

  // ==================== SETTINGS MENU ====================
  Widget _buildSettingsMenu() {
    return ListTile(
      leading: const Icon(Icons.palette),
      title: const Text('Mode Gelap'),
      trailing: Obx(
        () => Switch(
          value: themeController.isDarkMode.value,
          onChanged: (_) => themeController.toggleTheme(),
        ),
      ),
    );
  }

  // ==================== LOGOUT ====================
  Widget _buildLogoutButton() {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text('Logout', style: TextStyle(color: Colors.red)),
      onTap: _confirmLogout,
    );
  }

  // ==================== PICK & UPLOAD AVATAR ====================
  Future<void> _pickAndUploadAvatar() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final supabase = SupabaseConfig.client;
      final userId = authController.currentUser.value?.id;
      final fileName = 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage.from('avatars').upload(fileName, File(pickedFile.path));
      final publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      await userController.updateProfile(avatarUrl: publicUrl);
      await authController.fetchCurrentUser();

      if (Get.isDialogOpen ?? false) Get.back();
      setState(() {});
      Get.snackbar('Sukses', 'Avatar berhasil diupdate');
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('Error', 'Gagal upload avatar: $e');
    }
  }

  // ==================== EDIT PROFILE ====================
  void _showEditDialog(String currentName) async {
    final newName = await DialogHelper.showEditProfileDialog(currentName);
    if (newName != null && newName != currentName) {
      DialogHelper.showLoading(message: 'Menyimpan...');
      final success = await userController.updateProfile(name: newName);
      DialogHelper.hideLoading();
      if (success) {
        await authController.fetchCurrentUser();
        setState(() {});
        Get.snackbar('Sukses', 'Profil berhasil diupdate');
      }
    }
  }

  // ==================== CHANGE PASSWORD ====================
  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final isLoading = false.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('Ganti Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPasswordField(oldPasswordController, 'Password Lama', Icons.lock_outline),
            const SizedBox(height: 12),
            _buildPasswordField(newPasswordController, 'Password Baru (min 6 karakter)', Icons.lock),
            const SizedBox(height: 12),
            _buildPasswordField(confirmPasswordController, 'Konfirmasi Password', Icons.lock_outline),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: isLoading.value
                  ? null
                  : () => _handleChangePassword(
                      oldPasswordController,
                      newPasswordController,
                      confirmPasswordController,
                      isLoading,
                    ),
              child: isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update'),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PASSWORD FIELD ====================
  Widget _buildPasswordField(TextEditingController controller, String label, IconData icon) {
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      obscureText: true,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
        prefixIcon: Icon(icon, color: isDark ? Colors.grey[400] : Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
      ),
    );
  }

  // ==================== HANDLE CHANGE PASSWORD ====================
  Future<void> _handleChangePassword(
    TextEditingController oldPassword,
    TextEditingController newPassword,
    TextEditingController confirmPassword,
    RxBool isLoading,
  ) async {
    if (newPassword.text.length < 6) {
      Get.snackbar('Error', 'Password minimal 6 karakter');
      return;
    }
    if (newPassword.text != confirmPassword.text) {
      Get.snackbar('Error', 'Password baru tidak cocok');
      return;
    }

    isLoading.value = true;
    try {
      await authController.changePassword(
        oldPassword.text,
        newPassword.text,
      );
      Get.back();
      Get.snackbar('Sukses', 'Password berhasil diubah');
    } catch (e) {
      Get.snackbar('Error', 'Gagal: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== CONFIRM LOGOUT ====================
  void _confirmLogout() async {
    final confirm = await DialogHelper.showConfirmDialog(
      title: 'Konfirmasi',
      message: 'Apakah Anda yakin ingin logout?',
      confirmText: 'Logout',
      cancelText: 'Batal',
      confirmColor: Colors.red,
    );
    if (confirm == true) {
      await authController.logout();
    }
  }
}
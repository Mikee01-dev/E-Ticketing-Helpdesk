import 'package:get/get.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'auth_controller.dart';

class UserController extends GetxController {
  final RxBool isLoading = false.obs;
  final supabase = SupabaseConfig.client;
  final AuthController authController = Get.find<AuthController>();

  // Update profile user
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    isLoading.value = true;
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await supabase
          .from('profiles')
          .update(updates)
          .eq('id', userId);

      await authController.fetchCurrentUser();
      Get.snackbar('Sukses', 'Profile berhasil diperbarui');
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Gagal update profile: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Get all helpdesk staff (untuk assign ticket)
  Future<List<UserModel>> getAllHelpdesk() async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .inFilter('role', ['helpdesk', 'admin']);

      return response.map((e) => UserModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error getting helpdesk: $e');
      return [];
    }
  }

  Future<UserModel?> getHelpdeskById(String id) async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return UserModel.fromMap(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting helpdesk by id: $e');
      return null;
    }
  }

  // Update user role (admin only)
  Future<bool> updateUserRole(String userId, String newRole) async {
    if (!authController.isAdmin()) {
      Get.snackbar('Error', 'Unauthorized');
      return false;
    }

    isLoading.value = true;
    try {
      await supabase
          .from('profiles')
          .update({'role': newRole})
          .eq('id', userId);

      Get.snackbar('Sukses', 'Role user diperbarui');
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Gagal update role: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<UserModel>> getAllUsersSafe() async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      return response.map((e) => UserModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];  // Return kosong, tidak crash
    }
  }
}
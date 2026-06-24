import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../config/supabase_config.dart';
import '../config/routes.dart';  // ✅ Import routes
import '../models/user_model.dart';

class AuthController extends GetxController {
  final RxBool isLoading = false.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isAuthenticated = false.obs;

  final supabase = SupabaseConfig.client;

  @override
  void onInit() {
    super.onInit();
    supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        isAuthenticated.value = true;
        fetchCurrentUser();
      } else {
        isAuthenticated.value = false;
        currentUser.value = null;
      }
    });

    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final session = supabase.auth.currentSession;
    if (session != null) {
      isAuthenticated.value = true;
      await fetchCurrentUser();
    } else {
      isAuthenticated.value = false;
    }
  }

  Future<void> fetchCurrentUser() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      final email = supabase.auth.currentUser?.email;
      if (userId == null) return;

      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        currentUser.value = UserModel.fromMap({
          ...response,
          'email': email,
        });
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    isLoading.value = true;
    try { // Request Body
      final response = await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user != null) { // Response Success
        await fetchCurrentUser();
        isAuthenticated.value = true;
        Get.snackbar(
          'Sukses',
          'Selamat datang ${currentUser.value?.name ?? "User"}',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );
        return true;
      }
      return false;
    } on AuthException catch (e) { // Response Error
      Get.snackbar(
        'Login Gagal',
        e.message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    isLoading.value = true;
    try { // Request Body
      final response = await supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'name': name.trim()},
      );

      if (response.user != null) { // Response Success
        Get.snackbar(
          'Sukses',
          'Registrasi berhasil! Silakan login.',
          snackPosition: SnackPosition.TOP,
        );
        return true;
      }
      return false;
    } on AuthException catch (e) { // Response Error
      Get.snackbar('Registrasi Gagal', e.message);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

Future<void> resetPassword(String email) async {
  isLoading.value = true;
  try {
    // ✅ Tambahkan redirect ke halaman update password di Flutter
    await supabase.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'http://localhost:56022/update-password', // Ganti dengan URL kamu
    );
    Get.back();
    Get.snackbar(
      'Sukses',
      'Email reset password telah dikirim. Silakan cek email Anda.',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );
  } catch (e) {
    Get.snackbar('Error', 'Gagal mengirim email reset password: $e');
  } finally {
    isLoading.value = false;
  }
}

Future<void> changePassword(String oldPassword, String newPassword) async {
  isLoading.value = true;
  try {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Verifikasi password lama dengan login ulang
    try {
      await supabase.auth.signInWithPassword(
        email: user.email!,
        password: oldPassword,
      );
    } catch (e) {
      throw Exception('Password lama salah');
    }

    // Update password
    await supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );

    Get.snackbar('Sukses', 'Password berhasil diubah');
  } catch (e) {
    Get.snackbar('Error', 'Gagal mengubah password: ${e.toString()}');
    rethrow;
  } finally {
    isLoading.value = false;
  }
}

  Future<void> logout() async {
    isLoading.value = true;
    try {
      await supabase.auth.signOut();
      currentUser.value = null;
      isAuthenticated.value = false;

      Get.offAllNamed(AppRoutes.login);

      Get.snackbar('Sukses', 'Logout berhasil');
    } catch (e) {
      Get.snackbar('Error', 'Gagal logout: $e');
    } finally {
      isLoading.value = false;
    }
  }

  bool isAdmin() {
    return currentUser.value?.role == 'admin';
  }

  bool isHelpdesk() {
    return currentUser.value?.role == 'helpdesk' || isAdmin();
  }

  bool isUser() {
    return currentUser.value?.role == 'user';
  }
}
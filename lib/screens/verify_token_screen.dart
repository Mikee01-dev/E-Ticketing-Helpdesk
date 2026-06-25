import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../widgets/custom_button.dart';

class VerifyTokenScreen extends StatelessWidget {
  VerifyTokenScreen({super.key});

  final emailController = TextEditingController();
  final tokenController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final isLoading = false.obs;
  final supabase = SupabaseConfig.client;

  Future<void> _resetPassword() async {
    final email = emailController.text.trim();
    final token = tokenController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmController.text.trim();

    // Validasi
    if (email.isEmpty) {
      Get.snackbar('Error', 'Email tidak boleh kosong');
      return;
    }
    if (token.isEmpty || token.length != 8) { // ✅ 8 digit
      Get.snackbar('Error', 'Masukkan kode 8 digit dari email');
      return;
    }
    if (password.length < 6) {
      Get.snackbar('Error', 'Password minimal 6 karakter');
      return;
    }
    if (password != confirm) {
      Get.snackbar('Error', 'Password tidak cocok');
      return;
    }

    isLoading.value = true;
    try {
      await supabase.auth.verifyOTP(
        type: OtpType.recovery,
        token: token,
        email: email,
      );

      await supabase.auth.updateUser(
        UserAttributes(password: password),
      );

      Get.snackbar('Sukses', 'Password berhasil diubah!');
      await supabase.auth.signOut();
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar('Error', 'Gagal: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi & Reset Password'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Icon(Icons.verified, size: 60, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'Masukkan email, kode 8 digit, dan password baru',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Email
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            // OTP 8 digit
            TextField(
              controller: tokenController,
              decoration: const InputDecoration(
                labelText: 'Kode OTP (8 digit)',
                prefixIcon: Icon(Icons.pin),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 8, // 8 digit
            ),
            const SizedBox(height: 16),
            // Password Baru
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password Baru (min 6 karakter)',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Konfirmasi Password
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Konfirmasi Password',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Obx(
              () => CustomButton(
                text: 'Reset Password',
                onPressed: _resetPassword,
                isLoading: isLoading.value,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Get.offAllNamed('/login'),
              child: const Text('Kembali ke Login'),
            ),
          ],
        ),
      ),
    );
  }
}
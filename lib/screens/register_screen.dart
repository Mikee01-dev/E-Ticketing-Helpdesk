import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../utils/validator.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final authController = Get.find<AuthController>();
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Nama Lengkap',
                  hint: 'Masukkan nama lengkap',
                  controller: nameController,
                  prefixIcon: Icons.person,
                  validator: Validator.validateName,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Email',
                  hint: 'Masukkan email',
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email,
                  validator: Validator.validateEmail,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Password',
                  hint: 'Minimal 6 karakter',
                  controller: passwordController,
                  obscureText: true,
                  prefixIcon: Icons.lock,
                  validator: Validator.validatePassword,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Konfirmasi Password',
                  hint: 'Ulangi password',
                  controller: confirmPasswordController,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (value) => Validator.validateConfirmPassword(
                    value,
                    passwordController.text,
                  ),
                ),
                const SizedBox(height: 32),
                Obx(
                  () => CustomButton(
                    text: 'Register',
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final success = await authController.register(
                          nameController.text,
                          emailController.text,
                          passwordController.text,
                        );
                        if (success) {
                          Get.offAllNamed('/login');// Kembali ke login
                        }
                      }
                    },
                    isLoading: authController.isLoading.value,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
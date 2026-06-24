import 'dart:async';  // 🆕 Tambahkan ini untuk Timer
import 'package:flutter/material.dart';

class Helpers {
  // Show snackbar
  static void showSnackBar(
    BuildContext context, {
    required String message,
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show loading dialog
  static void showLoadingDialog(BuildContext context, {String message = 'Loading...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  // Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  // Debounce function (DIPERBAIKI dengan tipe yang jelas)
  static void Function() debounce(Duration duration, void Function() callback) {
    Timer? timer;
    return () {
      if (timer?.isActive == true) {
        timer?.cancel();
      }
      timer = Timer(duration, callback);
    };
  }

  // Debounce untuk fungsi dengan parameter
  static Function(T) debounceWithParam<T>(Duration duration, void Function(T) callback) {
    Timer? timer;
    return (T param) {
      if (timer?.isActive == true) {
        timer?.cancel();
      }
      timer = Timer(duration, () => callback(param));
    };
  }

  // Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Generate random string (DIPERBAIKI dengan Random)
  static String generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String result = '';
    for (int i = 0; i < length; i++) {
      result += chars[(random + i) % chars.length];
    }
    return result;
  }

  // Format number with separator (contoh: 1000000 -> 1,000,000)
  static String formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // Truncate text with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
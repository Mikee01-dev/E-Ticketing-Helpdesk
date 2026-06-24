import 'dart:io';
import 'package:flutter/foundation.dart';  // 🆕 Tambahkan ini untuk debugPrint
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  // Pilih gambar dari galeri
  static Future<File?> pickImageFromGallery({
    double maxWidth = 1200,
    double maxHeight = 1200,
    int quality = 75,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: quality,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  // Ambil foto dari kamera
  static Future<File?> pickImageFromCamera({
    double maxWidth = 1200,
    double maxHeight = 1200,
    int quality = 75,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: quality,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error taking photo: $e');
      return null;
    }
  }

  // Kompres gambar
  static Future<File?> compressImage(File file, {int quality = 70}) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: 800,
        minHeight: 800,
      );

      if (result != null) {
        return File(result.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return file;
    }
  }

  // Cek ukuran file (dalam MB)
  static Future<double> getFileSizeInMB(File file) async {
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  }

  // Validasi apakah gambar terlalu besar (> maxMB)
  static Future<bool> isImageTooLarge(File file, {int maxMB = 2}) async {
    final sizeInMB = await getFileSizeInMB(file);
    return sizeInMB > maxMB;
  }

  // Hapus file temporary
  static Future<void> deleteTempFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }
}
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart' show kIsWeb;

class Base64ImageService {
  final ImagePicker _picker = ImagePicker();

  // Chọn và convert ảnh sang Base64
  Future<String?> pickAndConvertToBase64() async {
    try {
      // Chọn ảnh
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,  // Giảm kích thước để tiết kiệm
        maxHeight: 400,
        imageQuality: 70, // Nén 70%
      );

      if (image == null) return null;

      // Đọc bytes
      final Uint8List imageBytes = await image.readAsBytes();

      // Nén thêm bằng package image
      final img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return null;

      // Resize về 200x200 (đủ cho avatar)
      final img.Image resizedImage = img.copyResize(
        originalImage,
        width: 200,
        height: 200,
      );

      // Encode sang JPG với chất lượng 80%
      final List<int> compressedBytes = img.encodeJpg(resizedImage, quality: 80);

      // Kiểm tra kích thước
      final sizeInKB = compressedBytes.length / 1024;
      print('📊 Kích thước ảnh: ${sizeInKB.toStringAsFixed(2)} KB');

      if (sizeInKB > 500) {
        print('⚠️ Ảnh quá lớn, nén thêm...');
        // Nén mạnh hơn nếu > 500KB
        final moreCompressed = img.encodeJpg(resizedImage, quality: 60);
        final base64String = base64Encode(moreCompressed);
        return 'data:image/jpeg;base64,$base64String';
      }

      // Convert sang Base64
      final base64String = base64Encode(compressedBytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      print('❌ Lỗi convert ảnh: $e');
      return null;
    }
  }

  // Validate Base64 string
  bool isValidBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) return false;
    return base64String.startsWith('data:image/');
  }

  // Lấy size của Base64 (KB)
  double getBase64Size(String base64String) {
    final bytes = base64String.length;
    return bytes / 1024;
  }
}
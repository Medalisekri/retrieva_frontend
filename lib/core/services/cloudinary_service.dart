import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  final Dio _dio = Dio();
  final ImagePicker _picker = ImagePicker();

  static const String _baseUrl = 'https://api.cloudinary.com/v1_1';

  Future<String?> pickAndUploadImage({
    required ImageSource source,
    String folder = 'retrieva',
  }) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
      );
      if (picked == null) return null;
      return await uploadFile(File(picked.path), folder: folder);
    } catch (e) {
      return null;
    }
  }
  Future<String?> uploadBytes(
      Uint8List bytes, {
        String folder = 'retrieva',
        String filename = 'image.jpg',
      }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
        ),
        'upload_preset': 'retrieva_uploads',
        'folder': folder,
      });

      final response = await _dio.post(
        '$_baseUrl/dylq9vfo/image/upload',
        data: formData,
      );

      debugPrint('CLOUDINARY STATUS: ${response.statusCode}');
      debugPrint('CLOUDINARY RESPONSE: ${response.data}');

      return response.data['secure_url'] as String?;
    } on DioException catch (e) {
      debugPrint('CLOUDINARY ERROR STATUS: ${e.response?.statusCode}');
      debugPrint('CLOUDINARY ERROR BODY: ${e.response?.data}');
      return null;
    } catch (e) {
      debugPrint('CLOUDINARY UNKNOWN ERROR: $e');
      return null;
    }
  }
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Optional: compresses the image slightly to save bandwidth
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      // Handle any platform-specific exceptions
      print('Error picking image: $e');
    }
    return null;
  }
  Future<String?> uploadFile(File file, {String folder = 'retrieva'}) async {
    try {
      debugPrint('FILE PATH: ${file.path}');
      debugPrint('FILE EXISTS: ${await file.exists()}');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        'upload_preset': 'retrieva_uploads',
        'folder': folder,
      });

      final response = await _dio.post(
        '$_baseUrl/dylq9vfo/image/upload',
        data: formData,
      );

      debugPrint('CLOUDINARY STATUS: ${response.statusCode}');
      debugPrint('CLOUDINARY RESPONSE: ${response.data}');

      return response.data['secure_url'] as String?;
    } on DioException catch (e) {
      debugPrint('CLOUDINARY ERROR STATUS: ${e.response?.statusCode}');
      debugPrint('CLOUDINARY ERROR BODY: ${e.response?.data}');
      return null;
    } catch (e) {
      debugPrint('CLOUDINARY UNKNOWN ERROR: $e');
      return null;
    }
  }

  Future<List<String>> pickAndUploadMultiple({
    int maxImages = 5,
    String folder = 'retrieva',
  }) async {
    try {
      final picked = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1024,
      );
      if (picked.isEmpty) return [];

      final limited = picked.take(maxImages).toList();
      final urls = <String>[];

      for (final image in limited) {
        final url =
        await uploadFile(File(image.path), folder: folder);
        if (url != null) urls.add(url);
      }

      return urls;
    } catch (e) {
      return [];
    }
  }
}
import 'dart:typed_data';
import 'package:dio/dio.dart';

class CloudinaryService {
  final Dio _dio = Dio();

  static const String _baseUrl = 'https://api.cloudinary.com/v1_1';

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


      return response.data['secure_url'] as String?;
    }
     catch (e) {
      print(e);
      return null;
    }
  }

}
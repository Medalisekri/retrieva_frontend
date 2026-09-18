import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:retrieva/core/helper/auth_helper.dart';

class ContactRepository {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: dotenv.env['URL']!,
    headers: {'Content-Type': 'application/json'},
  ))..interceptors.add(AuthInterceptor());



  Future<void> sendMessage({
    required String name,
    required String email,
    required String message,
  }) async {
    try {
      final response = await _dio.post(
        '/accounts/contact/',
        data: {
          'name': name,
          'email': email,
          'message': message,
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          response.data['error'] ?? 'Failed to send message',
        );
      }
    } on DioException catch (e) {
      final error = e.response?.data?['error'] ?? e.message;
      throw Exception(error);
    }
  }
}
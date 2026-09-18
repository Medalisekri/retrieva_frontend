import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:retrieva/core/helper/auth_helper.dart';
import 'package:retrieva/models/profile_model.dart';

class AuthRepository {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: dotenv.env['URL']!,
    headers: {'Content-Type': 'application/json'},
  ))..interceptors.add(AuthInterceptor());


  Future<void> signUp(String email, String password, String fullName) async {
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
    await credential.user?.sendEmailVerification();

    try {
      final token = await credential.user?.getIdToken();
      await _dio.patch(
        '/accounts/profile/',
        data: {'full_name': fullName},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      await FirebaseAuth.instance.signOut();
      throw Exception('Account created, but profile setup failed. Please try again.');
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email, password: password);
      if (!credential.user!.emailVerified) {
        await FirebaseAuth.instance.signOut();
        throw Exception('Please verify your email first');
      }

      await _dio.patch(
        '/accounts/profile/',
        data: {'is_verified': true},

      );
    } on DioException catch (e) {
      print(e.response?.statusCode);
      print(e.response?.data);
    }
  }

  Future<void> saveOneSignalId(String onesignalId) async {
    try {
      await _dio.patch(
        '/accounts/profile/',
        data: {'onesignal_id': onesignalId},

      );
    } on DioException catch (e) {
      print('[AUTH] Failed to save OneSignal ID: ${e.response?.statusCode}');
      print('[AUTH] Error: ${e.response?.data}');
    }
  }

  Future<void> signInWithGoogle() async {
    try { await GoogleSignIn().disconnect(); }
    catch (_) {}

    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

    try {
      await _dio.patch(
        '/accounts/profile/',
        data: {'full_name': userCredential.user?.displayName ?? ''},
      );
    } catch (e) {
      debugPrint('[AUTH] Profile update failed (non-fatal): $e');
    }
  }

  Future<ProfileModel> fetchProfile() async {
    final response = await _dio.get(
      '/accounts/profile/',

    );
    return ProfileModel.fromJson(response.data);
  }

  Future<void> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on DioException catch (e) {
      print(e.response?.statusCode);
      print(e.response?.data);
    }
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      throw Exception('Something went wrong: $e');
    }
  }
}



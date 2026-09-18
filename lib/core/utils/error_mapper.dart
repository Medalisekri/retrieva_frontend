import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ErrorMapper {
  static String toFriendly(Object error) {
    debugPrint('[ERROR] $error');

    // 1. Firebase Auth errors
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'email-already-in-use':
          return 'This email is already registered. Try logging in.';
        case 'weak-password':
          return 'Password is too weak. Use at least 7 characters.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'network-request-failed':
          return 'No internet connection.';
        case 'operation-not-allowed':
          return 'Google sign-in is not enabled for this app.';
        default:
          return 'Sign-in failed. Please try again.';
      }
    }

    // 2. Dio / network errors
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timed out. Check your internet.';
        case DioExceptionType.connectionError:
          return 'No internet connection.';
        case DioExceptionType.badResponse:
          final status = error.response?.statusCode;
          switch (status) {
            case 401: return 'Session expired. Please sign in again.';
            case 403: return "You don't have permission for that.";
            case 429: return error.response?.data['error'] ?? 'Too many posts today.';
            case 500: return 'Server error. Try again later.';
            default:  return 'Something went wrong.';
          }
        default:
          return 'Something went wrong.';
      }
    }

    // 3. Custom exceptions with a message (e.g. "Please verify your email first")
    final msg = error.toString();
    if (msg.startsWith('Exception: ')) {
      final clean = msg.replaceFirst('Exception: ', '');
      if (clean.isNotEmpty) return clean;
    }

    return 'Something went wrong. Please try again.';
  }
}
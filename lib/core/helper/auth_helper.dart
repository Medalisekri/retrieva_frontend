import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Automatically attach token to every request
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // If 401 Unauthorized, token is likely expired
    if (err.response?.statusCode == 401) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          // Force refresh the token
          final newToken = await user.getIdToken(true);

          // Update the failed request with the new token
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newToken';

          // Retry the request
          final response = await Dio().fetch(options);
          return handler.resolve(response);
        } catch (_) {
          // If refresh fails, let the error pass through (user needs to re-login)
        }
      }
    }
    super.onError(err, handler);
  }
}
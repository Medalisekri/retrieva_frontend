import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:retrieva/models/item_model.dart';
import 'package:retrieva/models/profile_model.dart';
class AuthRepository {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: dotenv.env['ITEM_URL']!,
    headers: {'Content-Type': 'application/json'},
  ));
  Future<Options> get _authOptions async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    print('PROFILE TOKEN: $token');
    return Options(headers: {
      if (token != null) 'Authorization': 'Bearer $token',
    });
  }
  //item.firebaseUid == FirebaseAuth.instance.currentUser?.uid
  Future<void> getCurrentUser() async{
    final auth = FirebaseAuth.instance;
    try{
      final   user = auth.currentUser?.uid;
    }catch(e){
      throw Exception(e);
    }
  }
Future<void> signUp(String email , String password , String fullName) async{
  try{
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email, password: password);
    final token = await credential.user?.getIdToken();
      await credential.user?.sendEmailVerification();
    await _dio.patch(
      'accounts/profile/',
      data: {'full_name': fullName},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

   
  }catch (e) {
  if (e is DioException) {
  print('STATUS: ${e.response?.statusCode}');
  print('BODY: ${e.response?.data}');
  }
  }
}

Future<void> signIn(String email , String password) async {
  try {
  final credential =   await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email, password: password);
    if (!credential.user!.emailVerified) {
      await FirebaseAuth.instance.signOut();
      throw Exception('Please verify your email first');
    }

    final response = await _dio.get('accounts/profile' , options: await _authOptions);
    final profile = ProfileModel.fromJson(response.data);
    await _dio.patch(
    'accounts/profile/',
    data: {'is_verified': true},
    options: await _authOptions,
  );
  }on DioException catch (e) {
    print(e.response?.statusCode);
    print(e.response?.data);
  }
}

Future<void> signInWithGoogle() async{
    try {

      final googleUser = await GoogleSignIn().signIn();
      final googleAuth = await googleUser?.authentication;
      final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth?.accessToken,
          idToken: googleAuth?.idToken
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential);
      final options = await _authOptions;
      print('AFTER LOGIN HEADERS: ${options.headers}');
      await _dio.patch('accounts/profile/',
          data: {'full_name': userCredential.user?.displayName ?? ''},
          options: await _authOptions );

    }catch(e){
       throw Exception('Something went wrong: $e');
    }
    }
    Future<void> resetPassword(String email) async{
    try{
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    }on DioException catch (e) {
      print(e.response?.statusCode);
      print(e.response?.data);
    }
    }
Future<void> signOut() async{
    try{
      await FirebaseAuth.instance.signOut();
    }catch(e){
      throw Exception('Something went wrong: $e');
    }
}
}
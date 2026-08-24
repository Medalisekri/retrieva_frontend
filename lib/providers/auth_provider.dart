import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:retrieva/repositories/auth_repository.dart';

class AuthProvider extends StateNotifier<AsyncValue> {
   final AuthRepository _repository;
  AuthProvider(this._repository): super(const AsyncValue.data(null));

  void signUp(String email , String password , String fullName) async {
    state = const AsyncValue.loading();
    try{
     await _repository.signUp(email, password, fullName);
    }catch(e){
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
   void signIn(String email , String password) async {
     state = const AsyncValue.loading();
     try{
       await _repository.signIn(email, password);
     }catch(e){
       state = AsyncValue.error(e, StackTrace.current);
     }
   }
   void signInWithGoogle() async {
     state = const AsyncValue.loading();
     try{
       await _repository.signInWithGoogle();
     }catch(e){
       state = AsyncValue.error(e, StackTrace.current);
     }
   }
   void resetPassword(String email) async{
    state = const AsyncValue.loading();
    try{
      await _repository.resetPassword(email);
    }catch(e){
      state = AsyncValue.error(e, StackTrace.current);
    }
   }
   void signOut() async{
     state = const AsyncValue.loading();
     try{
       await _repository.signOut();
     }catch(e){
       state = AsyncValue.error(e, StackTrace.current);
     }
   }
}
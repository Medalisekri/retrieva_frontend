import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:retrieva/repositories/auth_repository.dart';
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});
class AuthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {

  }

   AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> signUp({required String email , required String password , required String fullName}) async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {
  try {
    await _repository.signUp(email, password, fullName);
  } catch (e) {
    state = AsyncValue.error(e, StackTrace.current);
  }
  });
  }
   Future<void> signIn({required String email , required String password}) async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {
     try{
       await _repository.signIn(email, password);
     }catch(e){
       state = AsyncValue.error(e, StackTrace.current);
     }});
   }
  Future<void> signInWithGoogle() async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {
     state = const AsyncValue.loading();
     try{
       await _repository.signInWithGoogle();
     }catch(e){
       state = AsyncValue.error(e, StackTrace.current);
     }});
   }
  Future<void> resetPassword({required String email}) async{
  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {
    try{
      await _repository.resetPassword(email);
    }catch(e){
      state = AsyncValue.error(e, StackTrace.current);
    }});
   }
  Future<void> signOut() async{
  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {
     try{
       await _repository.signOut();
     }catch(e){
       state = AsyncValue.error(e, StackTrace.current);
     }});
   }


} final authProvider = AsyncNotifierProvider<AuthNotifier , void>(
    AuthNotifier.new);

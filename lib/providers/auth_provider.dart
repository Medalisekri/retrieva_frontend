import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:retrieva/models/profile_model.dart';
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

    await _repository.signUp(email, password, fullName);
  }

    );
  }
   Future<void> signIn({required String email , required String password}) async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {

       await _repository.signIn(email, password);
       final profile = await _repository.fetchProfile();
       ref.read(profileProvider.notifier).state = profile;
     }

     );
   }
  Future<void> signInWithGoogle() async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {


       await _repository.signInWithGoogle();
       final profile = await _repository.fetchProfile();
       ref.read(profileProvider.notifier).state = profile;

     });
   }
  Future<void> resetPassword({required String email}) async{
  state = await AsyncValue.guard(() async {

      await _repository.resetPassword(email);
    }

    );
   }
  Future<void> signOut() async{
  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {

       await _repository.signOut();
     }

     );
   }


} final authNotifier = AsyncNotifierProvider<AuthNotifier , void>(
    AuthNotifier.new);
final profileProvider = StateProvider<ProfileModel?>((ref)=>null);

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrieva/models/profile_model.dart';
import 'package:retrieva/repositories/auth_repository.dart';
import '../core/services/onesignal_service.dart';
import 'chat_provider.dart';
import 'item_provider.dart';
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});
class AuthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {

  }

   AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> signUp({required String email , required String password , required String fullName}) async {
  state = await AsyncValue.guard(() async {
    await _repository.signUp(email, password, fullName);
  }

    );
  }
   Future<void> signIn({required String email , required String password}) async {
    state = const AsyncValue.loading();
  state = await AsyncValue.guard(() async {

       await _repository.signIn(email, password);
       final uid = FirebaseAuth.instance.currentUser?.uid;
       if (uid != null) {
         OneSignalService.loginWithUserId(uid);
       }
       ref.invalidate(profileProvider);
       ref.invalidate(itemNotifier);
       ref.invalidate(conversationNotifier);
       ref.invalidate(messageNotifier);
     }

     );
   }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
  state = await AsyncValue.guard(() async {
       await _repository.signInWithGoogle();
       final uid = FirebaseAuth.instance.currentUser?.uid;
       if (uid != null) {
         OneSignalService.loginWithUserId(uid);
       }
       ref.invalidate(profileProvider);
       ref.invalidate(itemNotifier);
       ref.invalidate(conversationNotifier);
       ref.invalidate(messageNotifier);
     });
   }

  Future<void> resetPassword({required String email}) async{
  state = await AsyncValue.guard(() async {

      await _repository.resetPassword(email);
    }

    );
   }

  Future<void> signOut() async{
  state = await AsyncValue.guard(() async {
       await _repository.signOut();
       ref.invalidate(profileProvider);
       ref.invalidate(itemNotifier);
       ref.invalidate(conversationNotifier);
       ref.invalidate(messageNotifier);
     }

     );
   }


} final authNotifier = AsyncNotifierProvider<AuthNotifier , void>(
    AuthNotifier.new);
final profileProvider = FutureProvider<ProfileModel?>((ref) async {
  final user = FirebaseAuth.instance.currentUser;   // ← direct Firebase check
  if (user == null) return null;
  try {
    return await ref.read(authRepositoryProvider).fetchProfile();
  } catch (e) {
    debugPrint('fetchProfile failed: $e');
    return null;
  }
});

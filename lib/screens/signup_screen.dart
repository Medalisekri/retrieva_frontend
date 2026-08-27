import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retrieva/core/router/app_routes.dart';
import 'package:retrieva/providers/auth_provider.dart';
import '../core/theme/apptheme.dart';
import '../core/widgets/labled_field.dart';
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscurePass = true, _obscureConfirm = true;

  @override
  void dispose() {
    for (var c in [_fullName, _email, _pass, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifier);
  ref.listen(authNotifier, (prev , next) {
  next.whenOrNull(error: (e ,_)=>ScaffoldMessenger.of(context).showSnackBar
  (SnackBar(content: Text(e.toString())),));});
    return Scaffold(
      body: Column(
        children: [
          // ── Header ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.navy, AppColors.navyLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text('Create Account',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ),

          // ── Form ──
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      LabeledField(
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                        label: 'Full Name',
                        controller: _fullName,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.trim().length < 3) return 'Name must be at least 3 characters';
                          if (v.contains(RegExp(r'[0-9]'))) return 'Name must contain only letters';
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),
                      LabeledField(label: 'Email', controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.mail_outlined, size: 20),
                          validator: (v) {
                            if (v!.isEmpty) return 'Required';
                            if (!v.contains('@')) return 'Invalid email';
                            return null;
                          }),
                      const SizedBox(height: 18),
                      LabeledField(
                        prefixIcon: const Icon(Icons.lock_outlined, size: 20),
                        label: 'Password', controller: _pass,
                        obscureText: _obscurePass,
                        suffix: IconButton(
                          icon: Icon(_obscurePass
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                              size: 18, color: AppColors.textSecondary),
                          onPressed: () =>
                              setState(() => _obscurePass = !_obscurePass),
                        ),
                        validator: (v) {
                          if (v!.isEmpty) return 'Required';
                          if (v.length < 7) return 'Min 7 characters';
                          if (!v.contains(RegExp(r'[A-Z]'))) {
                            return 'At least 1 uppercase letter (A-Z).';
                          }
                          if (!v.contains(RegExp(r'[a-z]'))) {
                            return 'At least 1 lowercase letter (a-z).';
                          }
                          if (!v.contains(RegExp(r'[0-9]'))) {
                            return 'At least 1 number (0-9).';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      LabeledField(
                        prefixIcon: const Icon(Icons.lock_outlined, size: 20),
                        label: 'Confirm Password', controller: _confirm,
                        obscureText: _obscureConfirm,
                        suffix: IconButton(
                          icon: Icon(_obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                              size: 18, color: AppColors.textSecondary),
                          onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                        ),
                        validator: (v) {
                          if (v!.isEmpty) return 'Required';
                          if (v != _pass.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      ElevatedButton(
                        onPressed: authState.isLoading ?null : _submit,
                        child: authState.isLoading?

                             const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                            : const Text('Create Account'),
                     ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: (){
                          ref.read(authNotifier.notifier).signInWithGoogle();
                      }   ,
                        child: authState.isLoading?

                        const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                            : const Text('Continue with google'),
                      ),
                      const SizedBox(height: 20),

                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('Already have an account? ',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.login),
                          child: const Text('Login',
                              style: TextStyle(
                                  color: AppColors.teal,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  void _submit() async {

    if (!_formKey.currentState!.validate()) return;

    await ref.read(authNotifier.notifier).signUp(
        email: _email.text.trim(),
        fullName: _fullName.text.trim(),
        password: _pass.text,
      );
            if(mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mark_email_unread_outlined,
                            size: 48, color: AppColors.teal),
                        const SizedBox(height: 16),
                        const Text('Check your email',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        Text(
                          'We sent a verification link to\n${_email.text.trim()}\n\nVerify your email then log in.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                        ),
                      ],
                    ),
                    actions: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                           context.push(AppRoutes.login);// go to login
                          },
                          child: const Text('Go to Login'),
                        ),
                      ),
                    ],
                  ),
                );
      }
   }
}
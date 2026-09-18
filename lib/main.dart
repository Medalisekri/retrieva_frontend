import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:retrieva/models/profile_model.dart';
import 'package:retrieva/providers/auth_provider.dart';
import 'package:retrieva/core/services/onesignal_service.dart';
import 'package:retrieva/providers/chat_provider.dart';
import 'package:retrieva/providers/item_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final prefs = await SharedPreferences.getInstance();
  final seen = prefs.getBool('onboarding_complete') ?? false;
  await OneSignalService.initialize();
  OneSignalService.setupNotificationClicks();
  runApp(ProviderScope(
      overrides: [
    showOnboardingProvider.overrideWithValue(!seen),
  ],
      child: const RetrievaApp()));

}

class RetrievaApp extends ConsumerStatefulWidget {
  const RetrievaApp({super.key});

  @override
  ConsumerState<RetrievaApp> createState() => _RetrievaAppState();
}

class _RetrievaAppState extends ConsumerState<RetrievaApp> {

@override
  void initState() {
    super.initState();
    _setupNotificationNavigation();
  }
  void _setupNotificationNavigation() {
    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      if (data == null) return;
      _handleNotificationData(Map<String, dynamic>.from(data));
    });
  }
  // ── Main router for notification taps ───────────────
  Future<void> _handleNotificationData(Map<String, dynamic> data) async {
    // Wait for Firebase auth to restore (important on cold start)
    await _waitForAuth();

    final type = data['type'];

    switch (type) {
      case 'chat_message':
        final id = _parseInt(data['conversation_id']);
        if (id != null) await _openChat(id);
        break;

      case 'match_found':
        final id = _parseInt(data['item_id']);
        if (id != null) await _openItem(id);
        break;
    }
  }

  // ── Open a chat conversation ────────────────────────
  Future<void> _openChat(int conversationId) async {
    try {
      final conversation = await ref
          .read(chatRepositoryProvider)
          .getConversation(conversationId);

      if (!mounted) return;
      ref.read(appRouterProvider).push(AppRoutes.message, extra: conversation);
    } catch (e) {
      debugPrint('[NAV] Failed to open chat: $e');
    }
  }

  // ── Open an item detail (for match alerts) ─────────
  Future<void> _openItem(int itemId) async {
    try {
      final item = await ref
          .read(myItemsNotifier.notifier)
          .loadItemDetail(itemId);

      if (!mounted) return;
      ref.read(appRouterProvider).push(AppRoutes.detail, extra: item);
    } catch (e) {
      debugPrint('[NAV] Failed to open item: $e');
    }
  }

  // ── Helpers ─────────────────────────────────────────
  int? _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value');
  }

  Future<void> _waitForAuth({int timeoutSeconds = 8}) async {
    final start = DateTime.now();
    while (FirebaseAuth.instance.currentUser == null) {
      if (DateTime.now().difference(start).inSeconds > timeoutSeconds) {
        debugPrint('[NAV] Timed out waiting for auth');
        return;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }
  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Retrieva',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}


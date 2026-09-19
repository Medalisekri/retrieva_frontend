import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OneSignalService {
  static Future<void> initialize() async {
    final appId = dotenv.env['ONE_SI'];
    if (appId == null || appId.isEmpty) {
      return;
    }

    OneSignal.initialize(appId);
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.notification.display();
    });

    await OneSignal.Notifications.requestPermission(true);
  }

  // Call this AFTER Firebase login succeeds
  static void loginWithUserId(String firebaseUid) {
    OneSignal.login(firebaseUid);
  }
  static void setupNotificationClicks() {
    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      final type = data?['type'];

      if (type == 'chat_message') {
        final conversationId = data?['conversation_id'];
        print('[ONESIGNAL] Tapped chat notification → conversation $conversationId');
      }
    });
  }
}
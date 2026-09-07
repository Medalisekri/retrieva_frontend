import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/material.dart';

class OneSignalService {
  static const String appId = "6bcfa5de-7fc2-4478-a590-b9bb72c6bf62";
  static bool _dialogShown = false;

  static void init(BuildContext context) {
    // Debugging
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    // Initialize
    OneSignal.initialize(appId);

    // Push Subscription Observer
    OneSignal.User.pushSubscription.addObserver((state) {
      final id = state.current.id;
      if (id != null && id.isNotEmpty && !id.startsWith("local-")) {
        // Run on next frame to ensure context is valid if this is called during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showVerificationDialog(context);
        });
      }
    });
  }

  static void _showVerificationDialog(BuildContext context) {
    if (_dialogShown) return;
    _dialogShown = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Your OneSignal SDK integration is complete!"),
        content: const Text(
          "You can now send Push Notifications & In-App Messages through OneSignal. Tap below to enable push notifications."
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              OneSignal.Notifications.requestPermission(true);
            },
            child: const Text("Got it"),
          ),
        ],
      ),
    );
  }

  static void login(String externalId) {
    OneSignal.login(externalId);
  }

  static void logout() {
    OneSignal.logout();
  }

  static void addTag(String key, String value) {
    OneSignal.User.addTagWithKey(key, value);
  }

  static void addEmail(String email) {
    OneSignal.User.addEmail(email);
  }

  static void addSms(String sms) {
    OneSignal.User.addSms(sms);
  }
}

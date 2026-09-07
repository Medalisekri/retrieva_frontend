import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrieva/screens/browse_screen.dart';
import 'package:retrieva/services/onesignal_service.dart';

import 'core/router/app_router.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(ProviderScope(child:  RetrievaApp(
    )));
}
class RetrievaApp extends ConsumerWidget {
  const RetrievaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Retrieva',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      builder: (context, child) {
        return OneSignalInitializer(child: child!);
      },
    );
  }
}

class OneSignalInitializer extends StatefulWidget {
  final Widget child;
  const OneSignalInitializer({super.key, required this.child});

  @override
  State<OneSignalInitializer> createState() => _OneSignalInitializerState();
}

class _OneSignalInitializerState extends State<OneSignalInitializer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OneSignalService.init(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}






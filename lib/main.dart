import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'routes.dart';
import 'services/notification_service.dart';

import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);
    await FirestoreService.initialize();
    
    // Initialize notification service but catch any errors (e.g. permission dialogs failing before runApp)
    try {
      await NotificationService.initialize();
    } catch (e) {
      debugPrint('Notification initialization failed: $e');
    }
    
    runApp(
      const ProviderScope(
        child: TraceApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('Initialization error: $e\n$stackTrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Failed to initialize app: $e', style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    );
  }
}

class TraceApp extends ConsumerWidget {
  const TraceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'TRACE — Transparent Records & Attendance for Campus Events',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: router,
    );
  }
}

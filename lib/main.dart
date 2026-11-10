import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turf_app/core/services/notification_service.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/firebase_options.dart';
import 'package:turf_app/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    const ProviderScope(
      child: TurfApp(),
    ),
  );
}

class TurfApp extends ConsumerWidget {
  const TurfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch to initialize the notification service
    ref.watch(notificationServiceProvider);
    
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Turf Booking',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}

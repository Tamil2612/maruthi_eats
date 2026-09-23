import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'providers/cart_provider.dart';
import 'providers/address_provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'firebase_options.dart';

// Must be a top-level (or static) function — the OS can invoke this in a
// separate isolate when a push notification arrives while the app is
// fully backgrounded/terminated. Keep it minimal; anything heavier
// (navigating, updating UI) belongs in the foreground handler instead.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // Required on iOS and Android 13+ before any notification will show.
  // Safe to call even if already granted/denied earlier.
  await FirebaseMessaging.instance.requestPermission();

  runApp(const MaruthiEatsApp());
}

class MaruthiEatsApp extends StatelessWidget {
  const MaruthiEatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => AddressProvider()),
          ],
          child: MaterialApp(
            title: 'Maruthi Eats',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const SplashScreen(),
          ),
        );
      },
    );
  }
}
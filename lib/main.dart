import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'providers/cart_provider.dart';
import 'providers/address_provider.dart';
import 'providers/restaurant_provider.dart';
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

// Use a registered App Check debug token only for a dedicated test build.
// Production/release builds use Play Integrity on Android and DeviceCheck on
// Apple platforms.
const bool _useDebugAppCheck =
    bool.fromEnvironment('USE_DEBUG_APP_CHECK', defaultValue: false);
const String _webRecaptchaSiteKey = String.fromEnvironment(
  'APP_CHECK_WEB_RECAPTCHA_SITE_KEY',
  defaultValue: '6LdDD20tAAAAAOzELBUSgYE3PKsBdzKprh8gJ5rv',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    providerWeb: ReCaptchaV3Provider(_webRecaptchaSiteKey),
    providerAndroid: (kDebugMode || _useDebugAppCheck)
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: (kDebugMode || _useDebugAppCheck)
        ? const AppleDebugProvider()
        : const AppleDeviceCheckProvider(), // Or const AppleAppAttestWithDeviceCheckFallbackProvider()
  );

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
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
            ChangeNotifierProvider(create: (_) => RestaurantProvider()),
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

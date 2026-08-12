import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'providers/cart_provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';

void main() async {
  // Capture all Flutter-level errors
  FlutterError.onError = (details) {
    print("[BOOTSTRAP ERROR] FlutterError: ${details.exception}");
    FlutterError.presentError(details);
  };

  // Capture errors that happen outside of the Flutter framework (e.g. async/timers)
  PlatformDispatcher.instance.onError = (error, stack) {
    print("[BOOTSTRAP ERROR] PlatformDispatcher: $error");
    return true;
  };

  print("[BOOTSTRAP] 1: main() started");

  try {
    WidgetsFlutterBinding.ensureInitialized();
    print("[BOOTSTRAP] 2: WidgetsFlutterBinding initialized");

    print("[BOOTSTRAP] 3: Starting Firebase initialization");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("[BOOTSTRAP] 4: Firebase initialized successfully");

    runApp(const MaruthiEatsApp());
    print("[BOOTSTRAP] 5: runApp executed");
  } catch (e, stack) {
    print("[BOOTSTRAP CRASH]: $e");
    print(stack);
  }
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
        return ChangeNotifierProvider(
          create: (_) => CartProvider(),
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

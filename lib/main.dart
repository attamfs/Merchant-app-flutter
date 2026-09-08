import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/mobile_verification_screen.dart';
import 'screens/auth/set_pin_screen.dart';
import 'screens/auth/forgot_pin_screen.dart';
import 'screens/auth/forgot_pin_reset_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'widgets/app_lock_wrapper.dart';
import 'widgets/auto_logout_wrapper.dart';
import 'screens/splash/splash_screen.dart';
import 'package:provider/provider.dart';
import 'providers/language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }
  // Force sign out on startup so user always sees login page
  await FirebaseAuth.instance.signOut();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final isRtl = languageProvider.currentLanguage == 'ar' || languageProvider.currentLanguage == 'ur';
        final textDirection = isRtl ? TextDirection.rtl : TextDirection.ltr;

        return MaterialApp(
          title: 'ATTA Merchant App',
          theme: AppTheme.lightTheme,
          home: const SplashScreen(),
          builder: (context, child) {
            return Directionality(
              textDirection: textDirection,
              child: AutoLogoutWrapper(
                child: AppLockWrapper(child: child!),
              ),
            );
          },
          routes: {
            '/auth': (context) => const AuthWrapper(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const MobileVerificationScreen(),
            '/forgot-pin': (context) => const ForgotPinScreen(),
            '/forgot-pin/reset': (context) => const ForgotPinResetScreen(),
            '/set-pin': (context) => const SetPinScreen(),
            '/dashboard': (context) => const DashboardScreen(),
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const DashboardScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

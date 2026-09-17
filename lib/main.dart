import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/mobile_verification_screen.dart';
import 'screens/auth/merchant_registration_screen.dart';
import 'screens/auth/set_pin_screen.dart';
import 'screens/auth/forgot_pin_screen.dart';
import 'screens/auth/forgot_pin_reset_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'widgets/app_lock_wrapper.dart';
import 'widgets/auto_logout_wrapper.dart';
import 'screens/splash/splash_screen.dart';
import 'package:provider/provider.dart';
import 'providers/language_provider.dart';
import 'providers/translation_provider.dart';

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
        ChangeNotifierProxyProvider<LanguageProvider, TranslationProvider>(
          create: (_) => TranslationProvider(),
          update: (_, languageProvider, translationProvider) =>
              translationProvider!..updateLanguage(languageProvider),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final isRtl = languageProvider.currentLanguage == 'ar' || languageProvider.currentLanguage == 'ur';
        final textDirection = isRtl ? TextDirection.rtl : TextDirection.ltr;

        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'ATTA Merchant App',
          theme: AppTheme.lightTheme,
          home: SplashScreen(),
          builder: (context, child) {
            return GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              behavior: HitTestBehavior.opaque,
              child: Directionality(
                textDirection: textDirection,
                child: AutoLogoutWrapper(
                  child: AppLockWrapper(child: child!),
                ),
              ),
            );
          },
          routes: {
            '/auth': (context) => AuthWrapper(),
            '/login': (context) => LoginScreen(),
            '/register': (context) => MobileVerificationScreen(),
            '/register-form': (context) => const MerchantRegistrationScreen(),
            '/forgot-pin': (context) => ForgotPinScreen(),
            '/forgot-pin/reset': (context) => ForgotPinResetScreen(),
            '/set-pin': (context) => SetPinScreen(),
            '/dashboard': (context) => DashboardScreen(),
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return DashboardScreen();
        }
        return LoginScreen();
      },
    );
  }
}

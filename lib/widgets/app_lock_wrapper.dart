import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/translation_extension.dart';

class AppLockWrapper extends StatefulWidget {
  final Widget child;

  AppLockWrapper({super.key, required this.child});

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper> with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _showPin = false;
  bool _isVerifying = false;
  late TextEditingController _pinController;
  
  String? _userPin;
  int _gracePeriod = 500; // default 500ms
  
  StreamSubscription? _userSub;
  StreamSubscription? _settingsSub;
  
  DateTime? _lastBackgroundTime;

  bool _wasLoggedInAtStartup = false;

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController();
    _wasLoggedInAtStartup = FirebaseAuth.instance.currentUser != null;
    WidgetsBinding.instance.addObserver(this);
    _initListeners();
    _checkInitialLockState();
  }

  Future<void> _checkInitialLockState() async {
    // Check initial state
  }

  void _initListeners() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _userSub?.cancel();
      _settingsSub?.cancel();

      if (user != null) {
        _userSub = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((snap) async {
          if (snap.exists && snap.data() != null && snap.data()!.containsKey('pin') && snap.data()!['pin'] != null && snap.data()!['pin'].toString().isNotEmpty) {
            final oldPin = _userPin;
            _userPin = snap.data()!['pin'].toString();
            
            final prefs = await SharedPreferences.getInstance();
            final isUnlocked = prefs.getBool('app_unlocked') ?? false;
            
            // If they were already logged in at startup, and we aren't unlocked, lock the app
            if (_wasLoggedInAtStartup && !isUnlocked && oldPin == null) {
              _lockApp();
            } 
            // If they just logged in during this session, don't lock them! Mark as unlocked.
            else if (!_wasLoggedInAtStartup && oldPin == null) {
              await prefs.setBool('app_unlocked', true);
            }
          } else {
            _userPin = null;
            if (_isLocked) {
              setState(() { _isLocked = false; });
            }
          }
        });

        _settingsSub = FirebaseFirestore.instance.collection('settings').doc('session').snapshots().listen((snap) {
          if (snap.exists && snap.data() != null && snap.data()!.containsKey('merchantAppLockGracePeriodMs')) {
            _gracePeriod = int.tryParse(snap.data()!['merchantAppLockGracePeriodMs'].toString()) ?? 500;
          }
        });
      } else {
        _userPin = null;
        setState(() {
          _isLocked = false;
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.hidden) {
      if (_lastBackgroundTime == null) {
        _lastBackgroundTime = DateTime.now();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_lastBackgroundTime != null) {
        final backgroundDuration = DateTime.now().difference(_lastBackgroundTime!).inMilliseconds;
        if (backgroundDuration > _gracePeriod) {
          _lockApp();
        }
        _lastBackgroundTime = null;
      }
    }
  }

  Future<void> _lockApp() async {
    if (_userPin == null || _userPin!.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_unlocked', false);
    
    if (!_isLocked) {
      setState(() {
        _isLocked = true;
        _pinController.clear();
      });
    }
  }

  Future<void> _unlockApp() async {
    if (_userPin == null) return;
    
    setState(() { _isVerifying = true; });
    
    await Future.delayed(Duration(milliseconds: 300));
    
    if (_pinController.text == _userPin) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_unlocked', true);
      setState(() {
        _isLocked = false;
        _pinController.clear();
      });
    } else {
      setState(() {
        _pinController.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Incorrect PIN'.tr(context)), backgroundColor: Colors.red),
        );
      }
    }
    
    setState(() { _isVerifying = false; });
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_unlocked', false);
    setState(() {
      _isLocked = false;
      _pinController.clear();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _userSub?.cancel();
    _settingsSub?.cancel();
    super.dispose();
  }

  Widget _buildLockScreen() {
    return Scaffold(
      backgroundColor: Colors.white.withOpacity(0.95),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.lock, size: 40, color: Theme.of(context).primaryColor),
                      ),
                      SizedBox(height: 24),
                      Text('App Locked'.tr(context),
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('Please enter your PIN to continue.'.tr(context),
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32),
                      TextField(
                        controller: _pinController,
                        onChanged: (val) {
                          setState(() {});
                        },
                        obscureText: !_showPin,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        textAlign: TextAlign.center,
                        enabled: !_isVerifying,
                        style: TextStyle(fontSize: 24, letterSpacing: 8),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: 'Enter 4-digit PIN',
                          hintStyle: TextStyle(fontSize: 16, letterSpacing: 0),
                          suffixIcon: IconButton(
                            icon: Icon(_showPin ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _showPin = !_showPin),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: (_pinController.text.length == 4 && !_isVerifying) ? _unlockApp : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isVerifying
                              ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text('Unlock App'.tr(context), style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      SizedBox(height: 24),
                      Divider(),
                      SizedBox(height: 16),
                      TextButton(
                        onPressed: _signOut,
                        child: Text('Sign Out'.tr(context), style: TextStyle(color: Colors.grey)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isLocked)
          Positioned.fill(
            child: _buildLockScreen(),
          ),
      ],
    );
  }
}

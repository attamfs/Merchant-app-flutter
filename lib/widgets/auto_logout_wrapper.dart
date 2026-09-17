import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart' as main_app;

class AutoLogoutWrapper extends StatefulWidget {
  final Widget child;

  AutoLogoutWrapper({super.key, required this.child});

  @override
  State<AutoLogoutWrapper> createState() => _AutoLogoutWrapperState();
}

class _AutoLogoutWrapperState extends State<AutoLogoutWrapper> {
  Timer? _idleTimer;
  int? _timeoutMs;
  StreamSubscription? _settingsSub;

  @override
  void initState() {
    super.initState();
    _initListener();
  }

  void _initListener() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _settingsSub?.cancel();
      _idleTimer?.cancel();

      if (user != null) {
        _settingsSub = FirebaseFirestore.instance
            .collection('settings')
            .doc('session')
            .snapshots()
            .listen((snap) {
              if (snap.exists && snap.data() != null) {
                final data = snap.data()!;
                int ms = 0;
                if (data.containsKey('merchantAppTimeoutValue') &&
                    data.containsKey('merchantAppTimeoutUnit')) {
                  final val =
                      double.tryParse(
                        data['merchantAppTimeoutValue'].toString(),
                      ) ??
                      0;
                  final unit = data['merchantAppTimeoutUnit']
                      .toString()
                      .toLowerCase();
                  if (unit == 'seconds')
                    ms = (val * 1000).toInt();
                  else if (unit == 'minutes')
                    ms = (val * 60 * 1000).toInt();
                  else if (unit == 'hours')
                    ms = (val * 60 * 60 * 1000).toInt();
                } else if (data.containsKey('merchantAppTimeoutMinutes')) {
                  final val =
                      double.tryParse(
                        data['merchantAppTimeoutMinutes'].toString(),
                      ) ??
                      0;
                  ms = (val * 60 * 1000).toInt();
                }

                if (ms > 0) {
                  _timeoutMs = ms;
                  _resetTimer();
                } else {
                  _timeoutMs = null;
                  _idleTimer?.cancel();
                }
              }
            });
      } else {
        _timeoutMs = null;
        _idleTimer?.cancel();
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          main_app.MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil('/auth', (route) => false);
        });
      }
    });
  }

  void _resetTimer() {
    if (_timeoutMs == null || FirebaseAuth.instance.currentUser == null) return;

    _idleTimer?.cancel();
    _idleTimer = Timer(Duration(milliseconds: _timeoutMs!), _logOutUser);
  }

  void _logOutUser() async {
    _idleTimer?.cancel();
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_unlocked', false);
  }

  void _handleUserInteraction([_]) {
    _resetTimer();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _settingsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handleUserInteraction,
      onPointerMove: _handleUserInteraction,
      onPointerUp: _handleUserInteraction,
      child: widget.child,
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _imageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSplash();
  }

  Future<void> _loadSplash() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUrl = prefs.getString('merchantSplashUrl');
    
    if (cachedUrl != null) {
      setState(() {
        _imageUrl = cachedUrl;
        _isLoading = false;
      });
    }

    try {
      final docSnap = await FirebaseFirestore.instance.collection('settings').doc('display').get();
      if (docSnap.exists) {
        final data = docSnap.data();
        if (data != null && data.containsKey('merchantAppSplashScreenUrl') && data.containsKey('merchantAppSplashScreenDuration')) {
          final url = data['merchantAppSplashScreenUrl'];
          final durationStr = data['merchantAppSplashScreenDuration'];
          
          if (url != null && durationStr != null) {
            prefs.setString('merchantSplashUrl', url);
            
            if (cachedUrl == null) {
              setState(() {
                _imageUrl = url;
                _isLoading = false;
              });
            }
            
            final durationSeconds = int.tryParse(durationStr.toString()) ?? 0;
            if (durationSeconds > 0) {
              await Future.delayed(Duration(seconds: durationSeconds));
              _navigateNext();
              return;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading splash: $e");
    }

    if (cachedUrl == null) {
      await Future.delayed(Duration(seconds: 1));
    } else {
      await Future.delayed(Duration(seconds: 3));
    }
    _navigateNext();
  }

  void _navigateNext() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : _imageUrl != null
                ? Image.network(
                    _imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
                  )
                : CircularProgressIndicator(),
      ),
    );
  }
}

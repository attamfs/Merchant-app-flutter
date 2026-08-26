import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/merchant_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  Future<MerchantUser?> getMerchantUser(User user) async {
    final firestore = FirebaseFirestore.instance;
    try {
      // 1. Check if Supervisor (roles_merchants)
      final supervisorDoc = await firestore.collection('roles_merchants').doc(user.uid).get();
      if (supervisorDoc.exists) {
        return MerchantUser(
          uid: user.uid,
          merchantId: supervisorDoc.data()?['merchantId'] ?? user.uid,
          role: MerchantRole.supervisor,
        );
      }

      // 2. Check if Cashier (via collectionGroup)
      final cashiersQuery = await firestore
          .collectionGroup('cashiers')
          .where('id', isEqualTo: user.uid)
          .get();

      if (cashiersQuery.docs.isNotEmpty) {
        final cashierData = cashiersQuery.docs.first.data();
        return MerchantUser(
          uid: user.uid,
          merchantId: cashierData['merchantId'],
          role: MerchantRole.cashier,
          cashierData: cashierData,
        );
      }

      // 3. Fallback for email login (crNumber-employeeNumber@dualverse.app)
      if (user.email != null && user.email!.endsWith('@dualverse.app')) {
        final localPart = user.email!.split('@')[0];
        final lastDash = localPart.lastIndexOf('-');
        if (lastDash > 0) {
          final crNumber = localPart.substring(0, lastDash);
          
          final merchantsQuery = await firestore
              .collection('merchants')
              .where('crNumber', isEqualTo: crNumber)
              .get();
              
          if (merchantsQuery.docs.isNotEmpty) {
             return MerchantUser(
                uid: user.uid,
                merchantId: merchantsQuery.docs.first.id,
                role: MerchantRole.cashier,
             );
          }
        }
      }

      // Unauthorized
      return MerchantUser(
        uid: user.uid,
        merchantId: '',
        role: MerchantRole.unauthorized,
      );
    } catch (e) {
      debugPrint('Error getting merchant role: $e');
      return MerchantUser(uid: user.uid, merchantId: '', role: MerchantRole.unauthorized);
    }
  }

  // Login with phone and pin (Legacy/Customer fallback)
  Future<UserCredential> loginWithPhoneAndPin({
    required String countryCode,
    required String phone,
    required String pin,
  }) async {
    // Format identifier: remove '+' from country code
    final cleanCountryCode = countryCode.replaceAll('+', '');
    final identifier = '$cleanCountryCode$phone';
    final password = '$identifier-$pin';

    try {
      debugPrint('Attempting login with: $identifier@customer.app');
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: '$identifier@customer.app',
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential' || e.code == 'user-not-found') {
        // Fallback for legacy dualverse accounts
        debugPrint('Fallback login with: $identifier@dualverse.app');
        return await _auth.signInWithEmailAndPassword(
          email: '$identifier@dualverse.app',
          password: password,
        );
      }
      rethrow;
    }
  }

  // Supervisor Login
  Future<UserCredential> loginSupervisor({
    required String crNumber,
    required String pin,
  }) async {
    final cleanCr = crNumber.trim();
    final email = '$cleanCr@dualverse.app';
    final password = '$cleanCr-$pin';

    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Cashier Login
  Future<UserCredential> loginCashier({
    required String crNumber,
    required String employeeNumber,
    required String password,
  }) async {
    final cleanCr = crNumber.trim();
    final cleanEmp = employeeNumber.trim();
    final email = '$cleanCr-$cleanEmp@dualverse.app';

    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}

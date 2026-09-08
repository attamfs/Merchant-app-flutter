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
    
    // 1. Check if Supervisor (roles_merchants)
    try {
      final supervisorDoc = await firestore.collection('roles_merchants').doc(user.uid).get();
      if (supervisorDoc.exists) {
        return MerchantUser(
          uid: user.uid,
          merchantId: supervisorDoc.data()?['merchantId'] ?? user.uid,
          role: MerchantRole.supervisor,
        );
      }
    } catch (e) {
      debugPrint('Error checking supervisor role: $e');
    }

    String? foundMerchantId;
    String? employeeNumber;

    // Determine CR Number from email if available
    if (user.email != null && user.email!.endsWith('@dualverse.app')) {
      final localPart = user.email!.split('@')[0];
      final lastDash = localPart.lastIndexOf('-');
      if (lastDash > 0) {
        final crNumber = localPart.substring(0, lastDash);
        employeeNumber = localPart.substring(lastDash + 1);
        
        try {
          final merchantsQuery = await firestore
              .collection('merchants')
              .where('crNumber', isEqualTo: crNumber)
              .get();
              
          if (merchantsQuery.docs.isNotEmpty) {
             foundMerchantId = merchantsQuery.docs.first.id;
          }
        } catch (e) {
          debugPrint('Error looking up merchant by CR Number: $e');
        }
      }
    }

    // 2. Try direct lookup if we have foundMerchantId
    if (foundMerchantId != null) {
      try {
        final cashierDoc = await firestore
            .collection('merchants')
            .doc(foundMerchantId)
            .collection('cashiers')
            .doc(user.uid)
            .get();

        if (cashierDoc.exists) {
          final cashierData = cashierDoc.data();
          return MerchantUser(
            uid: user.uid,
            merchantId: foundMerchantId,
            role: MerchantRole.cashier,
            cashierData: cashierData,
          );
        }
      } catch (e) {
        debugPrint('Error with direct cashier lookup: $e');
      }

      if (employeeNumber != null) {
        try {
          final cashiersQuery = await firestore
              .collection('merchants')
              .doc(foundMerchantId)
              .collection('cashiers')
              .where('employeeNumber', isEqualTo: employeeNumber)
              .get();

          if (cashiersQuery.docs.isNotEmpty) {
            final cashierData = cashiersQuery.docs.first.data();
            return MerchantUser(
              uid: user.uid,
              merchantId: foundMerchantId,
              role: MerchantRole.cashier,
              cashierData: cashierData,
            );
          }
        } catch (e) {
          debugPrint('Error with employee number cashier lookup: $e');
        }
      }
    }

    // 3. Try collectionGroup if direct lookups failed
    try {
      final cashiersQuery = await firestore
          .collectionGroup('cashiers')
          .where('id', isEqualTo: user.uid)
          .get();

      if (cashiersQuery.docs.isNotEmpty) {
        final cashierDoc = cashiersQuery.docs.first;
        final cashierData = cashierDoc.data();
        
        final parentMerchantId = cashierDoc.reference.parent.parent?.id ?? '';
        final merchantId = (cashierData['merchantId']?.toString().isNotEmpty == true) 
            ? cashierData['merchantId'] 
            : parentMerchantId;

        return MerchantUser(
          uid: user.uid,
          merchantId: merchantId,
          role: MerchantRole.cashier,
          cashierData: cashierData,
        );
      }
    } catch (e) {
      debugPrint('Error with collectionGroup cashier lookup: $e');
    }

    // 4. Ultimate Fallback for Cashier
    if (foundMerchantId != null) {
      return MerchantUser(
        uid: user.uid,
        merchantId: foundMerchantId,
        role: MerchantRole.cashier,
        cashierData: {
          'id': user.uid,
          'merchantId': foundMerchantId,
          'employeeNumber': employeeNumber ?? 'Unknown',
          'name': 'Cashier ${employeeNumber ?? ''}'.trim(),
          'status': 'Active',
        },
      );
    }

    // Unauthorized
    return MerchantUser(
      uid: user.uid,
      merchantId: '',
      role: MerchantRole.unauthorized,
    );
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

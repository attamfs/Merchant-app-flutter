import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/merchant_user.dart';

class MerchantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<DocumentSnapshot> streamMerchant(String merchantId) {
    return _firestore.collection('merchants').doc(merchantId).snapshots();
  }

  Future<double> getBhdValuePerPoint() async {
    try {
      final doc = await _firestore.collection('settings').doc('loyalty').get();
      if (doc.exists && doc.data() != null) {
        return (doc.data()!['bhdValuePerPoint'] ?? 0.01).toDouble();
      }
    } catch (e) {
      print('Error fetching bhdValuePerPoint: $e');
    }
    return 0.01; // fallback default
  }

  Stream<List<DocumentSnapshot>> streamTodaysTransactions(MerchantUser user) {
    final todayStart = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    
    Query query = _firestore.collection('transactions')
        .where('merchantId', isEqualTo: user.merchantId)
        .where('status', isEqualTo: 'Completed');
        
    if (user.role == MerchantRole.cashier) {
      query = query.where('cashierId', isEqualTo: user.uid);
    }
    
    return query.snapshots().map((snapshot) {
      // Filter out transactions not from today
      return snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null || !data.containsKey('date')) return false;
        final dateStr = data['date'] as String?;
        if (dateStr == null) return false;
        final txDate = DateTime.tryParse(dateStr);
        if (txDate == null) return false;
        return txDate.isAfter(todayStart) || txDate.isAtSameMomentAs(todayStart);
      }).toList();
    });
  }

  Stream<List<DocumentSnapshot>> streamActiveOrders(MerchantUser user) {
    Query query = _firestore.collection('orders')
        .where('merchantId', isEqualTo: user.merchantId);
        
    return query.snapshots().map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return false;
        final status = data['status'] as String?;
        return status != 'Delivered' && status != 'Cancelled';
      }).toList();
    });
  }
}

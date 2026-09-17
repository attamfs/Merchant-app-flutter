import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../../providers/translation_extension.dart';

class EndOfDayScreen extends StatefulWidget {
  final String merchantId;
  final Map<String, dynamic>? cashierData;

  EndOfDayScreen({
    super.key,
    required this.merchantId,
    this.cashierData,
  });

  @override
  State<EndOfDayScreen> createState() => _EndOfDayScreenState();
}

class _EndOfDayScreenState extends State<EndOfDayScreen> {
  bool _isLoading = true;
  bool _isClosing = false;
  double _totalDigitalSales = 0.0;
  int _transactionCount = 0;
  Map<String, double> _paymentBreakdown = {};

  final _notesController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _calculateSales();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _calculateSales() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final startOfDay = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);

      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('merchantId', isEqualTo: widget.merchantId)
          .where('cashierId', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      double total = 0.0;
      int count = 0;
      Map<String, double> breakdown = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString();
        if (status == 'Completed' || status == 'Paid') {
          final amount = (data['totalAmount'] ?? data['amount'] ?? 0).toDouble();
          total += amount;
          count++;

          if (data['paymentMethods'] is List) {
            for (var pm in data['paymentMethods']) {
              final method = pm['method']?.toString() ?? 'Unknown';
              final amt = (pm['amount'] ?? 0).toDouble();
              breakdown[method] = (breakdown[method] ?? 0) + amt;
            }
          } else if (data['payload']?['paymentMethodsPayload'] is List) {
            for (var pm in data['payload']['paymentMethodsPayload']) {
              final method = pm['method']?.toString() ?? 'Unknown';
              final amt = (pm['amount'] ?? 0).toDouble();
              breakdown[method] = (breakdown[method] ?? 0) + amt;
            }
          } else if (data['paymentMethod'] != null) {
            final method = data['paymentMethod'].toString();
            breakdown[method] = (breakdown[method] ?? 0) + amount;
          }
        }
      }

      if (mounted) {
        setState(() {
          _totalDigitalSales = total;
          _transactionCount = count;
          _paymentBreakdown = breakdown;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading sales: $e'.tr(context))));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _closeShift() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isClosing = true);

    try {
      final closingId = 'close_${DateTime.now().millisecondsSinceEpoch}';
      final closingRef = FirebaseFirestore.instance
          .collection('merchants')
          .doc(widget.merchantId)
          .collection('shiftClosings')
          .doc(closingId);

      await closingRef.set({
        'id': closingId,
        'cashierId': user.uid,
        'cashierName': widget.cashierData?['name'] ?? 'Unknown',
        'merchantId': widget.merchantId,
        'closingTime': DateTime.now().toIso8601String(),
        'totalDigitalSales': _totalDigitalSales,
        'transactionCount': _transactionCount,
        'status': 'Closed',
        'counterNumber': widget.cashierData?['counterNumber']?.toString(),
        'paymentBreakdown': _paymentBreakdown,
        'notes': _notesController.text.trim(),
      });

      await _authService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to close shift: $e'.tr(context))));
        setState(() => _isClosing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('End of Day'.tr(context)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Text('Total Digital Sales Today'.tr(context), style: TextStyle(fontSize: 16, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('${_totalDigitalSales.toStringAsFixed(3)} BHD',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  SizedBox(height: 4),
                  Text("$_transactionCount ${'Transactions'.tr(context)}", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            SizedBox(height: 24),
            if (_paymentBreakdown.isNotEmpty) ...[
              Text('Payment Breakdown'.tr(context), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: _paymentBreakdown.entries.map((e) {
                    return ListTile(
                      title: Text(e.key),
                      trailing: Text('${e.value.toStringAsFixed(3)} BHD', style: TextStyle(fontWeight: FontWeight.bold)),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 24),
            ],
            Text('Notes (Optional)'.tr(context), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Any discrepancies or comments...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isClosing ? null : _closeShift,
                child: _isClosing
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Close Shift & Logout'.tr(context), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

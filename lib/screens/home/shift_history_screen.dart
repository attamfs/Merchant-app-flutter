import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ShiftHistoryScreen extends StatefulWidget {
  final bool isCashier;
  final String? merchantId;

  const ShiftHistoryScreen({
    super.key,
    this.isCashier = false,
    this.merchantId,
  });

  @override
  State<ShiftHistoryScreen> createState() => _ShiftHistoryScreenState();
}

class _ShiftHistoryScreenState extends State<ShiftHistoryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final targetMerchantId = widget.isCashier ? (widget.merchantId ?? user.uid) : user.uid;
    Query streamQuery = _firestore
        .collection('merchants')
        .doc(targetMerchantId)
        .collection('shiftClosings');
        
    if (widget.isCashier) {
      streamQuery = streamQuery.where('cashierId', isEqualTo: user.uid);
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Shift History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: streamQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final shifts = snapshot.data?.docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            data['id'] = d.id;
            return data;
          }).toList() ?? [];

          shifts.sort((a, b) {
            final aTime = (a['closingTime'] as String?) ?? '';
            final bTime = (b['closingTime'] as String?) ?? '';
            return bTime.compareTo(aTime);
          });

          if (shifts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No Shift History Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('There are no closed shift records in the history.', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: shifts.length,
            itemBuilder: (context, index) {
              final shift = shifts[index];
              return _ShiftItem(shift: shift, merchantId: targetMerchantId);
            },
          );
        },
      ),
    );
  }
}

class _ShiftItem extends StatefulWidget {
  final Map<String, dynamic> shift;
  final String merchantId;

  const _ShiftItem({required this.shift, required this.merchantId});

  @override
  State<_ShiftItem> createState() => _ShiftItemState();
}

class _ShiftItemState extends State<_ShiftItem> {
  bool _isExpanded = false;
  bool _isLoading = false;
  Map<String, double> _breakdown = {};
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    if (widget.shift['paymentBreakdown'] != null) {
      _breakdown = Map<String, double>.from(
          (widget.shift['paymentBreakdown'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())));
    }
  }

  Future<void> _fetchDetails() async {
    if (_transactions.isNotEmpty || _isLoading) return;

    setState(() => _isLoading = true);
    try {
      final closingStr = widget.shift['closingTime'] as String?;
      if (closingStr == null) return;
      
      final closingDate = DateTime.parse(closingStr);
      final startOfDay = DateTime(closingDate.year, closingDate.month, closingDate.day);
      
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('merchantId', isEqualTo: widget.merchantId)
          .where('cashierId', isEqualTo: widget.shift['cashierId'])
          .get();

      final txs = <Map<String, dynamic>>[];
      final newBreakdown = <String, double>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final txDate = (data['date'] as Timestamp?)?.toDate();
        if (txDate != null && txDate.isAfter(startOfDay) && txDate.isBefore(closingDate) || txDate == closingDate) {
           if (data['status'] == 'Completed' || data['status'] == 'Paid') {
             data['id'] = doc.id;
             txs.add(data);
             
             final amount = (data['totalAmount'] ?? data['amount'] ?? 0).toDouble();
             
             final payload = data['payload'];
             final isPayloadMap = payload is Map;
             
             final methodsList = (data['paymentMethods'] ?? (isPayloadMap ? payload['paymentMethodsPayload'] : null) ?? []);
             final methods = methodsList is List ? methodsList : [];

             if (methods.isNotEmpty) {
               for (var pm in methods) {
                 if (pm is Map) {
                   final method = pm['method']?.toString() ?? 'Unknown';
                   final amt = (pm['amount'] ?? 0).toDouble();
                   newBreakdown[method] = (newBreakdown[method] ?? 0) + amt;
                 }
               }
             } else if (data['paymentMethod'] != null) {
               final method = data['paymentMethod'].toString();
               newBreakdown[method] = (newBreakdown[method] ?? 0) + amount;
             }
           }
        }
      }

      txs.sort((a, b) {
        final aDate = (a['date'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bDate = (b['date'] as Timestamp?)?.toDate() ?? DateTime.now();
        return bDate.compareTo(aDate);
      });

      setState(() {
        _transactions = txs;
        if (_breakdown.isEmpty) {
          _breakdown = newBreakdown;
        }
      });
    } catch (e) {
      debugPrint('Error fetching shift details: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final closingTimeStr = widget.shift['closingTime'] as String?;
    final closingTime = closingTimeStr != null ? DateTime.parse(closingTimeStr) : DateTime.now();
    final totalSales = (widget.shift['totalDigitalSales'] ?? 0).toDouble();
    final count = widget.shift['transactionCount'] ?? 0;
    final cashierName = widget.shift['cashierName'] ?? 'Unknown';
    final counterNumber = widget.shift['counterNumber'];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (expanded) {
            setState(() => _isExpanded = expanded);
            if (expanded) {
              _fetchDetails();
            }
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM d, yyyy • h:mm a').format(closingTime),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(cashierName, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        if (counterNumber != null) ...[
                          const SizedBox(width: 8),
                          Text('Counter: $counterNumber', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${totalSales.toStringAsFixed(3)} BHD', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
                  Text('$count Txns', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                ],
              ),
            ],
          ),
          children: [
            Container(
              color: Colors.grey[50],
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Total Sales Block
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                    child: Column(
                      children: [
                        Text('${totalSales.toStringAsFixed(3)} BHD', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Total Digital Sales', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Breakdown Block
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payment Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 12),
                        if (_isLoading)
                          const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                        else if (_breakdown.isEmpty)
                          Text('No payment breakdown available.', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic))
                        else
                          ..._breakdown.entries.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(e.key, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                    Text('${e.value.toStringAsFixed(3)} BHD', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                              )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Transactions Block
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Transactions List', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 12),
                        if (_isLoading)
                          const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                        else if (_transactions.isEmpty)
                          Text('No transactions recorded for this shift.', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic))
                        else
                          ..._transactions.map((tx) {
                            final txDate = (tx['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                            final amount = (tx['totalAmount'] ?? tx['amount'] ?? 0).toDouble();
                            final payload = tx['payload'];
                            final isPayloadMap = payload is Map;
                            final methodsList = (tx['paymentMethods'] ?? (isPayloadMap ? payload['paymentMethodsPayload'] : null) ?? []);
                            final methods = methodsList is List ? methodsList : [];
                            
                            String methodsStr = tx['paymentMethod']?.toString() ?? 'Digital Payment';
                            if (methods.isNotEmpty) {
                              methodsStr = methods.whereType<Map>().map((m) => "${m['method']}").join(', ');
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Customer', 
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                      Text('${amount.toStringAsFixed(3)} BHD', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          methodsStr,
                                          style: TextStyle(color: Colors.grey[500], fontSize: 10),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(DateFormat('hh:mm a').format(txDate), style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

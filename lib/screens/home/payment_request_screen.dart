import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'create_payment_request_screen.dart';

class PaymentRequestScreen extends StatefulWidget {
  final bool isCashier;
  final String? merchantId;

  const PaymentRequestScreen({
    super.key,
    this.isCashier = false,
    this.merchantId,
  });

  @override
  State<PaymentRequestScreen> createState() => _PaymentRequestScreenState();
}

class _PaymentRequestScreenState extends State<PaymentRequestScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, Map<String, dynamic>> _userCache = {};

  void _cancelRequest(String requestId) async {
    // Show dialog to confirm cancellation
    final reasonController = TextEditingController();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment Request?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This will notify the customer that the request is no longer valid. This action cannot be undone.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation (required)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Active'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Confirm Cancellation'),
          ),
        ],
      ),
    );

    if (confirm == true && reasonController.text.trim().isNotEmpty) {
      await _firestore.collection('paymentRequests').doc(requestId).update({
        'status': 'cancelled',
        'rejectionReason': reasonController.text.trim(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final targetMerchantId = widget.isCashier ? (widget.merchantId ?? user.uid) : user.uid;
    Query streamQuery = _firestore
        .collection('paymentRequests')
        .where('merchantId', isEqualTo: targetMerchantId);
        
    if (widget.isCashier) {
      streamQuery = streamQuery.where('cashierId', isEqualTo: user.uid);
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Payment Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreatePaymentRequestScreen(
                  merchantId: widget.merchantId ?? _auth.currentUser?.uid ?? '',
                  isCashier: widget.isCashier,
                  cashierId: widget.isCashier ? _auth.currentUser?.uid : null,
                )),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: streamQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading requests: ${snapshot.error}'));
          }

          final requests = snapshot.data?.docs.toList() ?? [];

          requests.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            
            DateTime parseDate(dynamic d) {
              if (d is Timestamp) return d.toDate();
              if (d is String) return DateTime.tryParse(d)?.toLocal() ?? DateTime.now();
              if (d is int) return DateTime.fromMillisecondsSinceEpoch(d);
              return DateTime.now();
            }
            
            final aDate = parseDate(aData['date']);
            final bDate = parseDate(bData['date']);
            return bDate.compareTo(aDate);
          });

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No Requests Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('You haven\'t sent any payment requests yet.', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CreatePaymentRequestScreen(
                          merchantId: widget.merchantId ?? _auth.currentUser?.uid ?? '',
                          isCashier: widget.isCashier,
                          cashierId: widget.isCashier ? _auth.currentUser?.uid : null,
                        )),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create First Request'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final status = data['status'] ?? 'pending';
              final amount = (data['amount'] ?? 0).toDouble();
              DateTime parseDate(dynamic d) {
                if (d is Timestamp) return d.toDate();
                if (d is String) return DateTime.tryParse(d)?.toLocal() ?? DateTime.now();
                if (d is int) return DateTime.fromMillisecondsSinceEpoch(d);
                return DateTime.now();
              }
              final date = parseDate(data['date']);
              
              Color statusColor;
              IconData statusIcon;
              if (status == 'paid') {
                statusColor = Colors.green;
                statusIcon = Icons.check_circle;
              } else if (status == 'cancelled') {
                statusColor = Colors.grey;
                statusIcon = Icons.cancel;
              } else {
                statusColor = Colors.orange;
                statusIcon = Icons.access_time;
              }

              final customerId = data['customerId']?.toString() ?? '';
              final merchantId = data['merchantId']?.toString() ?? '';
              final isPayer = customerId == _auth.currentUser?.uid;
              final otherPartyId = isPayer ? merchantId : customerId;
              
              Map<String, dynamic> userProfile = {
                'name': 'Unknown',
                'imageUrl': null,
              };

              if (otherPartyId.isNotEmpty) {
                if (_userCache.containsKey(otherPartyId)) {
                  userProfile = _userCache[otherPartyId]!;
                } else {
                  // Fire off request
                  // Try users first
                  _firestore.collection('users').doc(otherPartyId).get().then((userDoc) {
                    if (userDoc.exists && mounted) {
                      final uData = userDoc.data();
                      setState(() {
                        _userCache[otherPartyId] = {
                          'name': uData?['name']?.toString() ?? 'Unknown',
                          'imageUrl': (uData?['imageUrl'] ?? uData?['avatarUrl'] ?? uData?['photoURL'])?.toString(),
                        };
                      });
                    } else if (mounted) {
                      // Try merchants
                      _firestore.collection('merchants').doc(otherPartyId).get().then((merchantDoc) {
                        if (merchantDoc.exists && mounted) {
                          final mData = merchantDoc.data();
                          setState(() {
                            _userCache[otherPartyId] = {
                              'name': mData?['businessName']?.toString() ?? mData?['name']?.toString() ?? 'Unknown',
                              'imageUrl': (mData?['imageUrl'] ?? mData?['avatarUrl'] ?? mData?['photoURL'])?.toString(),
                            };
                          });
                        }
                      });
                    }
                  });
                }
              }

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (userProfile['imageUrl'] != null && userProfile['imageUrl'].toString().isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.network(
                                userProfile['imageUrl'],
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const CircleAvatar(radius: 20, child: Icon(Icons.person)),
                              ),
                            )
                          else
                            const CircleAvatar(radius: 20, child: Icon(Icons.person)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              userProfile['name']?.toString() ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'BHD ${amount.toStringAsFixed(3)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                Icon(statusIcon, size: 14, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  status.toUpperCase(),
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Date: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(DateFormat('dd-MMM hh:mm a').format(date)),
                        ],
                      ),
                      if (data['notes'] != null && data['notes'].toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('Details: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(data['notes']),
                          ],
                        ),
                      ],
                      if (status == 'pending') ...[
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _cancelRequest(doc.id),
                              icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                              label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Show QR code dialog
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Payment QR', textAlign: TextAlign.center),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('Ask customer to scan this QR code to complete the payment.', textAlign: TextAlign.center),
                                        const SizedBox(height: 24),
                                        // A placeholder for QR generation in Flutter
                                        Container(
                                          width: 200,
                                          height: 200,
                                          color: Colors.grey[200],
                                          child: const Center(child: Text('QR CODE')),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.qr_code, size: 18),
                              label: const Text('Show QR'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

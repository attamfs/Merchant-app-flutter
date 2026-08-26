import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class ManageCashiersScreen extends StatefulWidget {
  const ManageCashiersScreen({super.key});

  @override
  State<ManageCashiersScreen> createState() => _ManageCashiersScreenState();
}

class _ManageCashiersScreenState extends State<ManageCashiersScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  String _employeeName = '';
  String _employeeNumber = '';
  String _password = '';
  bool _isCreating = false;

  final TextEditingController _countersController = TextEditingController();
  bool _isSavingCounters = false;

  @override
  void initState() {
    super.initState();
    _loadCounters();
  }

  Future<void> _loadCounters() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final doc = await _firestore.collection('merchants').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final numCounters = data['numberOfCounters'];
      if (numCounters != null) {
        _countersController.text = numCounters.toString();
      }
    }
  }

  Future<void> _saveCounters() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final num = int.tryParse(_countersController.text);
    if (num == null || num < 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid number of counters')));
      return;
    }

    setState(() => _isSavingCounters = true);
    try {
      await _firestore.collection('merchants').doc(user.uid).update({
        'numberOfCounters': num,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Counters updated successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update counters: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingCounters = false);
      }
    }
  }

  Future<void> _createCashier() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isCreating = true);
    try {
      final merchantDoc = await _firestore.collection('merchants').doc(user.uid).get();
      final crNumber = merchantDoc.data()?['crNumber'] as String?;
      
      if (crNumber == null) {
        throw Exception('Merchant CR Number not found.');
      }

      final email = '${crNumber.trim()}-${_employeeNumber.trim()}@dualverse.app';

      // Use secondary app to not sign out current user
      FirebaseApp? secondaryApp;
      try {
        secondaryApp = Firebase.app('Secondary');
      } catch (e) {
        secondaryApp = await Firebase.initializeApp(
          name: 'Secondary',
          options: Firebase.app().options,
        );
      }

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(email: email, password: _password);
      
      await secondaryAuth.signOut();

      final newUid = userCredential.user!.uid;

      await _firestore.collection('merchants').doc(user.uid).collection('cashiers').doc(newUid).set({
        'id': newUid,
        'merchantId': user.uid,
        'employeeNumber': _employeeNumber.trim(),
        'name': _employeeName.trim(),
        'status': 'Active',
        'dateAdded': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cashier created successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _showAddCashierDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Cashier'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Employee Name'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      onSaved: (v) => _employeeName = v ?? '',
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Employee Number (e.g. 1001)'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      onSaved: (v) => _employeeNumber = v ?? '',
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Password (Min 6 chars)'),
                      obscureText: true,
                      validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null,
                      onSaved: (v) => _password = v ?? '',
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isCreating ? null : () async {
                    setDialogState(() => _isCreating = true);
                    await _createCashier();
                    setDialogState(() => _isCreating = false);
                  },
                  child: _isCreating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _toggleStatus(String cashierId, String currentStatus) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('merchants').doc(user.uid).collection('cashiers').doc(cashierId).update({
        'status': currentStatus == 'Active' ? 'Inactive' : 'Active',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Manage Cashiers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCashierDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Store Configuration
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.monitor, size: 20, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      const Text('Store Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Checkout Counters', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 40,
                              child: TextField(
                                controller: _countersController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                  hintText: 'e.g. 3',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: _isSavingCounters ? null : _saveCounters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isSavingCounters ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Cashiers List
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('merchants').doc(user.uid).collection('cashiers').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final cashiers = snapshot.data?.docs ?? [];

                if (cashiers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('No cashiers found.', style: TextStyle(color: Colors.grey[600])),
                          Text('Click the + button above to add one.', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cashiers.length,
                  itemBuilder: (context, index) {
                    final doc = cashiers[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Unknown';
                    final employeeNumber = data['employeeNumber'] ?? '';
                    final status = data['status'] ?? 'Active';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.people, color: Colors.green, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Emp: $employeeNumber', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: status == 'Active' ? Colors.green[100] : Colors.red[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: status == 'Active' ? Colors.green[700] : Colors.red[700],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 28,
                                child: OutlinedButton(
                                  onPressed: () => _toggleStatus(doc.id, status),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  child: const Text('Toggle Status', style: TextStyle(fontSize: 10)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

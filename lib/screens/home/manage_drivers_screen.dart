import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../widgets/drivers/driver_earnings_sheet.dart';
import 'package:provider/provider.dart';
import '../../providers/translation_extension.dart';

class ManageDriversScreen extends StatefulWidget {
  ManageDriversScreen({super.key});

  @override
  State<ManageDriversScreen> createState() => _ManageDriversScreenState();
}

class _ManageDriversScreenState extends State<ManageDriversScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  String _firstName = '';
  String _middleName = '';
  String _lastName = '';
  String _email = '';
  String _countryCode = '+973';
  String _phone = '';
  String _pin = '';
  String _vehicleDetails = '';
  String _vehicleType = 'Car';
  
  bool _isCreating = false;
  String? _editingDriverId;

  Future<void> _submitDriver() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isCreating = true);
    try {
      final merchantId = user.uid;
      final fullPhone = '$_countryCode${_phone.trim()}';
      final fullName = '${_firstName.trim()} ${_middleName.trim().isNotEmpty ? _middleName.trim() + ' ' : ''}${_lastName.trim()}';

      if (_editingDriverId != null) {
        // Update existing driver
        final updates = {
          'name': fullName,
          'firstName': _firstName.trim(),
          'middleName': _middleName.trim(),
          'lastName': _lastName.trim(),
          'email': _email.trim(),
          'phone': fullPhone,
          'vehicleDetails': _vehicleDetails.trim(),
          'vehicleType': _vehicleType,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('drivers').doc(_editingDriverId).update(updates);
        try {
          await _firestore.collection('users').doc(_editingDriverId).update(updates);
        } catch (e) {
          // User doc might not exist or permission denied, ignore
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Driver updated successfully!'.tr(context))));
          _resetForm();
        }
      } else {
        // Create new driver using Secondary Auth App
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
        
        final identifier = fullPhone.replaceAll('+', '');
        final authEmail = '$identifier@dualverse.app';
        final authPassword = '$identifier-${_pin.trim()}';

        final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
          email: authEmail,
          password: authPassword,
        );

        final driverUid = userCredential.user!.uid;
        await secondaryAuth.signOut(); // sign out the secondary app

        final driverData = {
          'id': driverUid,
          'merchantId': merchantId,
          'name': fullName,
          'firstName': _firstName.trim(),
          'middleName': _middleName.trim(),
          'lastName': _lastName.trim(),
          'email': _email.trim(),
          'phone': fullPhone,
          'pin': _pin.trim(),
          'vehicleDetails': _vehicleDetails.trim(),
          'vehicleType': _vehicleType,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'role': 'driver',
        };

        // Create driver doc
        await _firestore.collection('drivers').doc(driverUid).set(driverData);
        // Create user doc
        await _firestore.collection('users').doc(driverUid).set(driverData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Driver registered successfully!'.tr(context))));
          _resetForm();
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Authentication error occurred')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save driver: $e'.tr(context))));
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _resetForm() {
    setState(() {
      _editingDriverId = null;
      _firstName = '';
      _middleName = '';
      _lastName = '';
      _email = '';
      _phone = '';
      _pin = '';
      _vehicleDetails = '';
      _vehicleType = 'Car';
    });
    _formKey.currentState?.reset();
  }

  void _editDriver(Map<String, dynamic> driverData, String docId) {
    setState(() {
      _editingDriverId = docId;
      _firstName = driverData['firstName'] ?? '';
      _middleName = driverData['middleName'] ?? '';
      _lastName = driverData['lastName'] ?? '';
      _email = driverData['email'] ?? '';
      
      String phoneRaw = driverData['phone'] ?? '';
      if (phoneRaw.startsWith('+')) {
        // Very basic parsing for UI mapping
        _countryCode = phoneRaw.substring(0, 4);
        _phone = phoneRaw.length > 4 ? phoneRaw.substring(4) : '';
      } else {
        _phone = phoneRaw;
      }
      
      _vehicleDetails = driverData['vehicleDetails'] ?? '';
      _vehicleType = driverData['vehicleType'] ?? 'Car';
      _pin = ''; // Require them to type new pin if they want to change it? (Web app resets it to empty)
    });
  }

  Future<void> _deleteDriver(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Driver'.tr(context)),
        content: Text('Are you sure you want to delete this driver?'.tr(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'.tr(context)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'.tr(context)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _firestore.collection('drivers').doc(docId).delete();
      try {
        await _firestore.collection('users').doc(docId).delete();
      } catch (e) {
        // ignore
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Driver deleted'.tr(context))));
        if (_editingDriverId == docId) {
          _resetForm();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e'.tr(context))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final merchantId = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Drivers'.tr(context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: merchantId == null
          ? Center(child: Text('Not authenticated'.tr(context)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildForm(),
                  SizedBox(height: 32),
                  Text('Your Drivers'.tr(context),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  _buildDriversList(merchantId),
                ],
              ),
            ),
    );
  }

  Widget _buildForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _editingDriverId != null ? 'Edit Driver' : 'Register New Driver',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _firstName,
                      decoration: InputDecoration(labelText: 'First Name', border: OutlineInputBorder()),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      onSaved: (val) => _firstName = val ?? '',
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: _middleName,
                      decoration: InputDecoration(labelText: 'Middle Name (Opt)', border: OutlineInputBorder()),
                      onSaved: (val) => _middleName = val ?? '',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: _lastName,
                decoration: InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => _lastName = val ?? '',
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: _email,
                decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                onSaved: (val) => _email = val ?? '',
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: TextFormField(
                      initialValue: _countryCode,
                      decoration: InputDecoration(labelText: 'Code', border: OutlineInputBorder()),
                      onSaved: (val) => _countryCode = val ?? '+973',
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: _phone,
                      decoration: InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                      keyboardType: TextInputType.phone,
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      onSaved: (val) => _phone = val ?? '',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              if (_editingDriverId == null) ...[
                TextFormField(
                  initialValue: _pin,
                  decoration: InputDecoration(labelText: '4-Digit PIN', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  validator: (val) => val == null || val.length != 4 ? 'Enter 4 digit PIN' : null,
                  onSaved: (val) => _pin = val ?? '',
                ),
                SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _vehicleType,
                      decoration: InputDecoration(labelText: 'Vehicle Type', border: OutlineInputBorder()),
                      items: ['Car', 'Motorcycle', 'Van', 'Truck']
                          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _vehicleType = val);
                      },
                      onSaved: (val) => _vehicleType = val ?? 'Car',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: _vehicleDetails,
                decoration: InputDecoration(labelText: 'Vehicle Details (e.g. Plate #)', border: OutlineInputBorder()),
                onSaved: (val) => _vehicleDetails = val ?? '',
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  if (_editingDriverId != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _resetForm,
                        child: Text('Cancel Edit'.tr(context)),
                      ),
                    ),
                    SizedBox(width: 16),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _submitDriver,
                      child: _isCreating
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_editingDriverId != null ? 'Update Driver' : 'Register Driver'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriversList(String merchantId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('drivers').where('merchantId', isEqualTo: merchantId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading drivers'.tr(context)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Card(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.0),
              child: Text('No drivers found. Register one above.'.tr(context),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            return Card(
              margin: EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Icon(Icons.local_shipping, color: Theme.of(context).primaryColor),
                ),
                title: Text(data['name'] ?? 'Unknown Driver', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text('${data['vehicleType']} • ${data['vehicleDetails'] ?? 'No details'}'),
                    Text('${data['phone']}'),
                  ],
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.account_balance_wallet, color: Colors.green),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => DriverEarningsSheet(
                            driverId: doc.id,
                            driverName: data['name'] ?? 'Unknown Driver',
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editDriver(data, doc.id),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteDriver(doc.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

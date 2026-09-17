import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async';
import 'send_payment_request_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/translation_extension.dart';

class CreatePaymentRequestScreen extends StatefulWidget {
  final String merchantId;
  final bool isCashier;
  final String? cashierId;
  final String? counterNumber;

  CreatePaymentRequestScreen({
    super.key,
    required this.merchantId,
    this.isCashier = false,
    this.cashierId,
    this.counterNumber,
  });

  @override
  State<CreatePaymentRequestScreen> createState() => _CreatePaymentRequestScreenState();
}

class _CreatePaymentRequestScreenState extends State<CreatePaymentRequestScreen> {
  final _phoneController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  
  bool _isSearching = false;
  bool _isScanning = true;
  String _countryCode = '+973';
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounce;

  final List<String> _countryCodes = ['+973', '+966', '+974', '+965', '+968', '+971'];

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _scannerController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: 600), () {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    final query = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (query.length < 3) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final fullNumberWithCode = _countryCode + query;
      
      final usersQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isGreaterThanOrEqualTo: fullNumberWithCode)
          .where('phone', isLessThanOrEqualTo: '$fullNumberWithCode\uf8ff')
          .get();
          
      final merchantsQuery = await FirebaseFirestore.instance
          .collection('merchants')
          .where('phone', isGreaterThanOrEqualTo: fullNumberWithCode)
          .where('phone', isLessThanOrEqualTo: '$fullNumberWithCode\uf8ff')
          .get();

      final List<Map<String, dynamic>> results = [];
      
      for (var doc in usersQuery.docs) {
        final data = doc.data();
        results.add({
          'id': doc.id,
          'name': data['name'] ?? 'Unknown User',
          'phone': data['phone'] ?? '',
          'imageUrl': data['imageUrl'] ?? data['avatarUrl'] ?? data['photoURL'],
          'type': 'customer'
        });
      }
      
      for (var doc in merchantsQuery.docs) {
        final data = doc.data();
        results.add({
          'id': doc.id,
          'name': data['businessName'] ?? data['name'] ?? 'Unknown Merchant',
          'phone': data['phone'] ?? '',
          'imageUrl': data['imageUrl'] ?? data['avatarUrl'] ?? data['photoURL'],
          'type': 'merchant'
        });
      }

      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {
      debugPrint("Search error: $e");
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _selectTarget(String id, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SendPaymentRequestScreen(
          merchantId: widget.merchantId,
          targetId: id,
          targetType: type,
          isCashier: widget.isCashier,
          cashierId: widget.cashierId,
          counterNumber: widget.counterNumber,
        ),
      ),
    );
  }

  void _handleQRScan(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final data = barcode.rawValue!;
        
        setState(() => _isScanning = false);

        if (data.startsWith('customer:')) {
          _selectTarget(data.split(':')[1], 'customer');
        } else if (data.startsWith('merchant:')) {
          _selectTarget(data.split(':')[1], 'merchant');
        } else if (!data.contains(':')) {
          // Fallback for old QR codes (assumes customer)
          _selectTarget(data, 'customer');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid QR Code'.tr(context))),
          );
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) setState(() => _isScanning = true);
          });
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Match web app background
      appBar: AppBar(
        title: Text('New Payment Request'.tr(context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Search Bar Section
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _countryCode,
                      items: _countryCodes.map((String code) {
                        return DropdownMenuItem<String>(
                          value: code,
                          child: Text('${{'+973':'🇧🇭','+966':'🇸🇦','+974':'🇶🇦','+965':'🇰🇼','+968':'🇴🇲','+971':'🇦🇪'}[code] ?? ""} \u200E$code', textDirection: TextDirection.ltr),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _countryCode = newValue;
                          });
                          _performSearch();
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Enter Contact Number',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      suffixIcon: Icon(Icons.search, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Search Results
          if (_phoneController.text.trim().length >= 3)
            Expanded(
              child: _isSearching
                  ? Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? Center(child: Text('No results found.'.tr(context), style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final result = _searchResults[index];
                            final imageUrl = result['imageUrl'];
                            final type = result['type'];
                            
                            return Card(
                              elevation: 0,
                              margin: EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey[200]!),
                              ),
                              child: ListTile(
                                onTap: () => _selectTarget(result['id'], type),
                                leading: imageUrl != null && imageUrl.toString().isNotEmpty
                                    ? CircleAvatar(backgroundImage: NetworkImage(imageUrl))
                                    : CircleAvatar(child: Icon(Icons.person)),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        result['name'],
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (type == 'merchant')
                                      Container(
                                        margin: EdgeInsets.only(left: 8),
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text('Merchant'.tr(context), style: TextStyle(color: Colors.green, fontSize: 10)),
                                      ),
                                  ],
                                ),
                                subtitle: Text(result['phone'], style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ),
                            );
                          },
                        ),
            )
          else
            // QR Scanner
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Or scan QR Code to Send Request'.tr(context),
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: _isScanning
                          ? MobileScanner(
                              controller: _scannerController,
                              onDetect: _handleQRScan,
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, color: Colors.white, size: 48),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isScanning = true;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                  ),
                                  child: Text('Start Camera'.tr(context)),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Merchant Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: user == null
          ? const Center(child: Text('Not authenticated'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('merchants').doc(user!.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Profile not found'));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                
                final String businessName = data['businessName'] ?? 'Unknown Business';
                final String imageUrl = data['imageUrl'] ?? '';
                final String contactEmail = data['contactEmail'] ?? '';
                final String contactName = data['contactName'] ?? '';
                final String crNumber = data['crNumber'] ?? '';
                final String branchNumber = data['branchNumber']?.toString() ?? '';
                final String vatNumber = data['taxRegistrationNumber'] ?? '';
                final String phone = data['phone'] ?? '';
                final String dateJoined = data['dateJoined'] ?? '';
                final String businessType = data['businessType'] ?? '';
                final String category = data['category'] ?? '';
                final String priceRange = data['priceRange'] ?? '';
                final String deliveryModel = data['deliveryPricingModel'] ?? 'flat';
                final double deliveryPrice = (data['deliveryPrice'] ?? 0.0).toDouble();

                final address = data['address'] as Map<String, dynamic>? ?? {};

                final String fullCr = branchNumber.isNotEmpty ? '$crNumber-$branchNumber' : crNumber;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Header
                      Column(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: const Color(0xFF1EBB5E).withOpacity(0.1),
                            backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                            child: imageUrl.isEmpty
                                ? Text(businessName.isNotEmpty ? businessName[0].toUpperCase() : 'M', 
                                    style: const TextStyle(fontSize: 32, color: Color(0xFF1EBB5E), fontWeight: FontWeight.bold))
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(businessName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text(contactEmail, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Primary Information
                      _buildInfoCard('Primary Information', [
                        _buildInfoRow(Icons.business_center, 'Business Name', businessName),
                        _buildInfoRow(Icons.numbers, 'CR Number', fullCr),
                        if (vatNumber.isNotEmpty)
                          _buildInfoRow(Icons.receipt_long, 'VAT Registration Number', vatNumber),
                        _buildInfoRow(Icons.person, 'Contact Person', contactName),
                        _buildInfoRow(Icons.email, 'Contact Email', contactEmail),
                        _buildInfoRow(Icons.phone, 'Mobile Number', phone),
                        _buildInfoRow(Icons.calendar_today, 'Date Joined', dateJoined, isLast: true),
                      ]),
                      const SizedBox(height: 24),

                      // Business Details
                      _buildInfoCard('Business Details', [
                        _buildInfoRow(Icons.store, 'Merchant Type', businessType),
                        _buildInfoRow(Icons.category, 'Category / Cuisine', category),
                        _buildInfoRow(Icons.attach_money, 'Price Range', priceRange),
                        if (deliveryModel == 'hybrid')
                          _buildInfoRow(Icons.delivery_dining, 'Delivery Model', 'Hybrid Dynamic (Zone + Distance)', isLast: true)
                        else
                          _buildInfoRow(Icons.delivery_dining, 'Delivery Price', '${deliveryPrice.toStringAsFixed(3)} BHD', isLast: true),
                      ]),
                      const SizedBox(height: 24),

                      // Address
                      _buildInfoCard('Address', [
                        _buildInfoRow(Icons.home_work, 'Shop No.', address['flat']?.toString() ?? ''),
                        _buildInfoRow(Icons.apartment, 'Building', address['building']?.toString() ?? ''),
                        _buildInfoRow(Icons.add_road, 'Street', address['street']?.toString() ?? ''),
                        _buildInfoRow(Icons.map, 'Block', address['block']?.toString() ?? ''),
                        _buildInfoRow(Icons.location_city, 'Area', address['city']?.toString() ?? ''),
                        _buildInfoRow(Icons.public, 'Country', address['country']?.toString() ?? '', isLast: address['googleMapLink'] == null || address['googleMapLink'].toString().isEmpty),
                        if (address['googleMapLink'] != null && address['googleMapLink'].toString().isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Divider(),
                              ),
                              const Text('Saved Map', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: GestureDetector(
                                  onTap: () async {
                                    final urlStr = address['googleMapLink'].toString();
                                    if (urlStr.isNotEmpty) {
                                      final uri = Uri.parse(urlStr);
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      }
                                    }
                                  },
                                  child: SizedBox(
                                    height: 140,
                                    child: Stack(
                                      children: [
                                        SavedMapPreview(googleMapLink: address['googleMapLink'].toString()),
                                        Container(
                                          color: Colors.transparent,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ], onEdit: () {
                        _showEditAddressDialog(context, address, user!.uid);
                      }),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onEdit}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0, right: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (onEdit != null)
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 16, color: Colors.black87),
              label: const Text('Edit', style: TextStyle(color: Colors.black87)),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _showEditAddressDialog(BuildContext context, Map<String, dynamic> currentAddress, String uid) {
    final flatController = TextEditingController(text: currentAddress['flat']?.toString());
    final buildingController = TextEditingController(text: currentAddress['building']?.toString());
    final streetController = TextEditingController(text: currentAddress['street']?.toString());
    final blockController = TextEditingController(text: currentAddress['block']?.toString());
    final cityController = TextEditingController(text: currentAddress['city']?.toString());
    final countryController = TextEditingController(text: currentAddress['country']?.toString());
    final mapLinkController = TextEditingController(text: currentAddress['googleMapLink']?.toString());

    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Edit Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text('Update your location', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Shop No.', flatController)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField('Building', buildingController)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Street', streetController)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField('Block', blockController)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Area', cityController)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField('Country', countryController)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField('Google Map Link', mapLinkController),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: isSaving ? null : () async {
                              setState(() => isSaving = true);
                              final updatedAddress = {
                                'flat': flatController.text.trim(),
                                'building': buildingController.text.trim(),
                                'street': streetController.text.trim(),
                                'block': blockController.text.trim(),
                                'city': cityController.text.trim(),
                                'country': countryController.text.trim(),
                                'googleMapLink': mapLinkController.text.trim(),
                              };
                              try {
                                await FirebaseFirestore.instance.collection('merchants').doc(uid).update({
                                  'address': updatedAddress,
                                });
                                if (context.mounted) Navigator.pop(context);
                              } catch (e) {
                                setState(() => isSaving = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \$e')));
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: isSaving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Save Changes', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children, {VoidCallback? onEdit}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onEdit != null)
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 16, color: Colors.black87),
                  label: const Text('Edit', style: TextStyle(color: Colors.black87)),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value.isEmpty ? '-' : value, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SavedMapPreview extends StatefulWidget {
  final String googleMapLink;
  const SavedMapPreview({super.key, required this.googleMapLink});

  @override
  State<SavedMapPreview> createState() => _SavedMapPreviewState();
}

class _SavedMapPreviewState extends State<SavedMapPreview> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    
    // Extract lat/lng
    String lat = '';
    String lng = '';
    final RegExp regex = RegExp(r'query=([-.\d]+),([-.\d]+)');
    final match = regex.firstMatch(widget.googleMapLink);
    if (match != null) {
      lat = match.group(1) ?? '';
      lng = match.group(2) ?? '';
    }

    final String htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
          body { margin: 0; padding: 0; overflow: hidden; background-color: #f5f5f5; }
          iframe { width: 100vw; height: 100vh; border: 0; }
        </style>
      </head>
      <body>
        <iframe src="https://maps.google.com/maps?q=$lat,$lng&hl=en&z=15&output=embed" frameborder="0" style="border:0;" allowfullscreen="" aria-hidden="false" tabindex="0"></iframe>
      </body>
      </html>
    ''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('intent://') || (!request.url.startsWith('http') && !request.url.startsWith('about:blank'))) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}

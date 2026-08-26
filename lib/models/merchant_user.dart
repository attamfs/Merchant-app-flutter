enum MerchantRole { supervisor, cashier, unauthorized }

class MerchantUser {
  final String uid;
  final String merchantId;
  final MerchantRole role;
  final Map<String, dynamic>? cashierData;

  MerchantUser({
    required this.uid,
    required this.merchantId,
    required this.role,
    this.cashierData,
  });
}

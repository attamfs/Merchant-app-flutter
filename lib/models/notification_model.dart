import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String? message;
  final String? body;
  final String? description;
  final double? cashbackToUser;
  final double? points;
  final double? amount;
  final String? userName;
  final String? merchantName;
  final String? cardName;
  final String? tierName;
  final String type;
  final bool read;
  final bool isRead;
  final DateTime? createdAt;
  final String? merchantId;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    this.message,
    this.body,
    this.description,
    this.cashbackToUser,
    this.points,
    this.amount,
    this.userName,
    this.merchantName,
    this.cardName,
    this.tierName,
    required this.type,
    this.read = false,
    this.isRead = false,
    this.createdAt,
    this.merchantId,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    DateTime? parsedDate;
    if (data['createdAt'] is Timestamp) {
      parsedDate = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] != null) {
      try {
        parsedDate = DateTime.parse(data['createdAt'].toString());
      } catch (e) {
        parsedDate = null;
      }
    }

    return NotificationModel(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      title: data['title']?.toString() ?? 'Notification',
      message: data['message']?.toString(),
      body: data['body']?.toString(),
      description: data['description']?.toString(),
      cashbackToUser: double.tryParse(data['cashbackToUser']?.toString() ?? ''),
      points: double.tryParse(data['points']?.toString() ?? ''),
      amount: double.tryParse(data['amount']?.toString() ?? ''),
      userName: data['userName']?.toString(),
      merchantName: data['merchantName']?.toString(),
      cardName: data['cardName']?.toString(),
      tierName: data['tierName']?.toString(),
      type: data['type']?.toString() ?? 'SYSTEM',
      read: data['read'] == true,
      isRead: data['isRead'] == true,
      createdAt: parsedDate,
      merchantId: data['merchantId']?.toString(),
    );
  }

  bool get isEffectivelyRead => read == true || isRead == true;

  String getDisplayTitle(Map<String, dynamic>? settings) {
    String t = title;
    String typeKey = type;
    if (typeKey == 'TIER_UPGRADE') typeKey = 'tierUpgrade';
    
    final typeSetting = settings?[typeKey];
    if (typeSetting != null && typeSetting['enabled'] == true) {
      t = typeSetting['title']?.toString() ?? t;
    } else if (type == 'LOYALTY_AWARD' && merchantId == 'admin_console' && settings?['systemLoyaltyAward']?['enabled'] == true) {
      t = settings!['systemLoyaltyAward']['title']?.toString() ?? t;
    }
    return t;
  }

  String getDisplayMessage(Map<String, dynamic>? settings) {
    String msg = message ?? body ?? '';
    String typeKey = type;
    if (typeKey == 'TIER_UPGRADE') typeKey = 'tierUpgrade';
    
    final typeSetting = settings?[typeKey];
    if (typeSetting != null && typeSetting['enabled'] == true) {
      String template = typeSetting['template']?.toString() ?? '';
      
      final pts = cashbackToUser ?? points ?? 0.0;
      final amt = amount ?? 0.0;
      
      msg = template
        .replaceAll('{points}', pts.toStringAsFixed(1))
        .replaceAll('{description}', description ?? '')
        .replaceAll('{userName}', userName ?? 'User')
        .replaceAll('{merchantName}', merchantName ?? 'Merchant')
        .replaceAll('{amount}', amt.toStringAsFixed(3))
        .replaceAll('{cardName}', cardName ?? 'Card')
        .replaceAll('{tierName}', tierName ?? 'Tier');
    } else if (type == 'LOYALTY_AWARD' && merchantId == 'admin_console' && settings?['systemLoyaltyAward']?['enabled'] == true) {
      String template = settings!['systemLoyaltyAward']['template']?.toString() ?? '';
      final pts = cashbackToUser ?? 0.0;
      msg = template
        .replaceAll('{points}', pts.toStringAsFixed(1))
        .replaceAll('{description}', description ?? '');
    }
    return msg;
  }
}

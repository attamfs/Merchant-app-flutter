import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/translation_extension.dart';
import '../../models/notification_model.dart';
import '../../models/merchant_user.dart';

class NotificationsScreen extends StatefulWidget {
  final String merchantId;
  const NotificationsScreen({super.key, required this.merchantId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Map<String, dynamic>? _settings;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('notifications')
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _settings = doc.data();
        });
      }
    } catch (e) {
      debugPrint('Error fetching notification settings: $e');
    }
  }

  Future<void> _markAllAsRead(
    List<NotificationModel> notifications,
    String merchantId,
  ) async {
    if (notifications.isEmpty) return;

    final unread = notifications.where((n) => !n.isEffectivelyRead).toList();
    if (unread.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No unread notifications.'.tr(context))),
      );
      return;
    }

    final batch = FirebaseFirestore.instance.batch();
    for (var n in unread) {
      final ref = FirebaseFirestore.instance
          .collection('merchants')
          .doc(merchantId)
          .collection('notifications')
          .doc(n.id);
      batch.update(ref, {'read': true, 'isRead': true});
    }

    try {
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All notifications marked as read.'.tr(context)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking notifications as read.'.tr(context)),
          ),
        );
      }
    }
  }

  Future<void> _markAsRead(
    NotificationModel notification,
    String merchantId,
  ) async {
    if (notification.isEffectivelyRead) return;

    final ref = FirebaseFirestore.instance
        .collection('merchants')
        .doc(merchantId)
        .collection('notifications')
        .doc(notification.id);

    try {
      await ref.update({'read': true, 'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.merchantId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Notifications'.tr(context))),
        body: Center(child: Text('Not logged in'.tr(context))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'.tr(context)),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('merchants')
                .doc(widget.merchantId)
                .collection('notifications')
                .snapshots(),
            builder: (context, snapshot) {
              final List<NotificationModel> notifications = [];
              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  notifications.add(NotificationModel.fromFirestore(doc));
                }
              }
              return TextButton(
                onPressed: () => _markAllAsRead(notifications, widget.merchantId),
                child: Text(
                  'Mark all as read'.tr(context),
                  style: TextStyle(color: Colors.white),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('merchants')
            .doc(widget.merchantId)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('merchants')
                  .doc(widget.merchantId)
                  .collection('notifications')
                  .snapshots(),
              builder: (context, fallbackSnapshot) {
                if (fallbackSnapshot.hasError) {
                  return Center(
                    child: Text('Something went wrong'.tr(context)),
                  );
                }
                if (fallbackSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final docs = fallbackSnapshot.data!.docs;
                final notifications = docs
                    .map((d) => NotificationModel.fromFirestore(d))
                    .toList();

                notifications.sort((a, b) {
                  final dateA = a.createdAt ?? DateTime(1970);
                  final dateB = b.createdAt ?? DateTime(1970);
                  return dateB.compareTo(dateA);
                });

                return _buildList(notifications, widget.merchantId);
              },
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!.docs
              .map((d) => NotificationModel.fromFirestore(d))
              .toList();
          return _buildList(notifications, widget.merchantId);
        },
      ),
    );
  }

  Widget _buildList(List<NotificationModel> notifications, String merchantId) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 24),
            Text(
              'No new notifications'.tr(context),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'You\'re all caught up!'.tr(context),
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notif = notifications[index];
        final isRead = notif.isEffectivelyRead;
        final title = notif.getDisplayTitle(_settings);
        final message = notif.getDisplayMessage(_settings);

        String timeStr = 'just now'.tr(context);
        if (notif.createdAt != null) {
          timeStr = timeago.format(notif.createdAt!);
        }

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          color: isRead ? Colors.white : Colors.blue.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isRead
                ? BorderSide.none
                : BorderSide(color: Colors.blue.shade200, width: 1),
          ),
          child: InkWell(
            onTap: () => _markAsRead(notif, merchantId),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isRead)
                    Container(
                      margin: EdgeInsets.only(top: 6, right: 12),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (isRead) SizedBox(width: 22),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              timeStr,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (message.isNotEmpty) ...[
                          SizedBox(height: 6),
                          Text(
                            message,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

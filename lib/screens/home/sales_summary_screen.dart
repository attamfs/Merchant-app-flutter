import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
class UserSalesData {
  String id;
  String name;
  bool isSupervisor;
  double totalSales = 0;
  int completedRequestsCount = 0;
  double completedRequestsAmount = 0;
  int pendingRequestsCount = 0;
  double pendingRequestsAmount = 0;
  double eodSalesToday = 0;
  String eodStatusToday = 'No Shift Closed';
  Map<String, double> paymentMethods = {};

  UserSalesData({required this.id, required this.name, this.isSupervisor = false});
}

class SalesSummaryScreen extends StatefulWidget {
  const SalesSummaryScreen({super.key});

  @override
  State<SalesSummaryScreen> createState() => _SalesSummaryScreenState();
}

class _SalesSummaryScreenState extends State<SalesSummaryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _timeframe = 'week';
  DateTime _customFromDate = DateTime.now();
  DateTime _customToDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Sales Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('transactions').where('merchantId', isEqualTo: user.uid).snapshots(),
        builder: (context, txSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('paymentRequests').where('merchantId', isEqualTo: user.uid).snapshots(),
            builder: (context, reqSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('merchants').doc(user.uid).collection('cashiers').snapshots(),
                builder: (context, cashiersSnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('merchants').doc(user.uid).collection('shiftClosings').snapshots(),
                    builder: (context, shiftSnapshot) {
                      final isLoading = txSnapshot.connectionState == ConnectionState.waiting ||
                          reqSnapshot.connectionState == ConnectionState.waiting ||
                          cashiersSnapshot.connectionState == ConnectionState.waiting ||
                          shiftSnapshot.connectionState == ConnectionState.waiting;

                      if (isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final transactions = txSnapshot.data?.docs.map((d) => d.data() as Map<String, dynamic>).toList() ?? [];
                      final requests = reqSnapshot.data?.docs.map((d) => d.data() as Map<String, dynamic>).toList() ?? [];
                      final cashiers = cashiersSnapshot.data?.docs.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        data['id'] = d.id;
                        return data;
                      }).toList() ?? [];
                      final shiftClosings = shiftSnapshot.data?.docs.map((d) => d.data() as Map<String, dynamic>).toList() ?? [];

                      return _buildContent(transactions, requests, cashiers, shiftClosings);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> transactions, List<Map<String, dynamic>> requests, List<Map<String, dynamic>> cashiers, List<Map<String, dynamic>> shiftClosings) {
    final now = DateTime.now();
    DateTime startInterval;
    DateTime endInterval;

    switch (_timeframe) {
      case 'day':
        startInterval = DateTime(now.year, now.month, now.day);
        endInterval = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        break;
      case 'week':
        startInterval = now.subtract(Duration(days: now.weekday % 7));
        startInterval = DateTime(startInterval.year, startInterval.month, startInterval.day);
        endInterval = startInterval.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        break;
      case 'month':
        startInterval = DateTime(now.year, now.month, 1);
        endInterval = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        break;
      case 'year':
        startInterval = DateTime(now.year, 1, 1);
        endInterval = DateTime(now.year, 12, 31, 23, 59, 59, 999);
        break;
      case 'custom':
      default:
        startInterval = DateTime(_customFromDate.year, _customFromDate.month, _customFromDate.day);
        endInterval = DateTime(_customToDate.year, _customToDate.month, _customToDate.day, 23, 59, 59, 999);
        break;
    }

    final filteredTransactions = transactions.where((tx) {
      final dateVal = tx['date'];
      DateTime date = DateTime.now();
      if (dateVal is Timestamp) {
        date = dateVal.toDate();
      } else if (dateVal is String) {
        date = DateTime.tryParse(dateVal) ?? DateTime.now();
      }
      return date.isAfter(startInterval) && date.isBefore(endInterval);
    }).toList();
    
    final filteredRequests = requests.where((req) {
      final dateVal = req['date'];
      DateTime date = DateTime.now();
      if (dateVal is Timestamp) {
        date = dateVal.toDate();
      } else if (dateVal is String) {
        date = DateTime.tryParse(dateVal) ?? DateTime.now();
      }
      return date.isAfter(startInterval) && date.isBefore(endInterval);
    }).toList();

    Map<String, UserSalesData> cashierMap = {};
    for (var c in cashiers) {
      cashierMap[c['id']] = UserSalesData(id: c['id'], name: c['name'] ?? 'Cashier');
    }

    UserSalesData supervisorData = UserSalesData(id: 'supervisor', name: 'Supervisor', isSupervisor: true);

    double totalSales = 0;
    int totalTransactions = 0;
    
    double vouchersSoldAmount = 0;
    int vouchersSoldCount = 0;
    double vouchersUsedAmount = 0;
    int vouchersUsedCount = 0;

    for (final tx in filteredTransactions) {
      final status = tx['status'] ?? '';
      if (status != 'Completed' && status != 'Paid') continue;
      
      totalTransactions++;
      final amount = (tx['totalAmount'] ?? tx['amount'] ?? 0).toDouble();
      totalSales += amount;

      final payload = tx['payload'];
      final isPayloadMap = payload is Map;

      if (tx['purchaseType'] == 'voucher') {
        vouchersSoldAmount += amount;
        vouchersSoldCount += (isPayloadMap ? (payload['voucherQuantity'] ?? 1) as num : 1).toInt();
      }

      final methodsList = tx['paymentMethods'] ?? (isPayloadMap ? payload['paymentMethodsPayload'] : null) ?? [];
      final methods = methodsList is List ? methodsList : [];

      for (final pm in methods) {
        if (pm is Map) {
          final method = pm['method']?.toString().toLowerCase() ?? '';
          if (method.contains('voucher')) {
            vouchersUsedAmount += (pm['amount'] ?? 0).toDouble();
            vouchersUsedCount++;
          }
        }
      }
      
      final cId = tx['cashierId'];
      UserSalesData targetData = (cId != null && cashierMap.containsKey(cId)) ? cashierMap[cId]! : supervisorData;
      
      targetData.totalSales += amount;
      if (methods.isNotEmpty) {
        for (var pm in methods) {
          if (pm is Map) {
            final m = pm['method']?.toString() ?? 'Other';
            final a = (pm['amount'] ?? 0).toDouble();
            targetData.paymentMethods[m] = (targetData.paymentMethods[m] ?? 0) + a;
          }
        }
      } else if (tx['paymentMethod'] != null) {
        final m = tx['paymentMethod'].toString();
        targetData.paymentMethods[m] = (targetData.paymentMethods[m] ?? 0) + amount;
      }
    }

    for (final req in filteredRequests) {
      final amount = (req['amount'] ?? 0).toDouble();
      final status = req['status'];
      
      final cId = req['cashierId'];
      UserSalesData targetData = (cId != null && cashierMap.containsKey(cId)) ? cashierMap[cId]! : supervisorData;
      
      if (status == 'paid') {
        targetData.completedRequestsCount++;
        targetData.completedRequestsAmount += amount;
      } else if (status == 'pending') {
        targetData.pendingRequestsCount++;
        targetData.pendingRequestsAmount += amount;
      }
    }
    
    final startOfToday = DateTime(now.year, now.month, now.day);
    for (final sc in shiftClosings) {
      final ct = sc['closingTime'];
      DateTime closingDate = now;
      if (ct is Timestamp) {
        closingDate = ct.toDate();
      } else if (ct is String) {
        closingDate = DateTime.tryParse(ct) ?? now;
      }
      
      if (closingDate.isAfter(startOfToday) || closingDate.isAtSameMomentAs(startOfToday)) {
        final cId = sc['cashierId'];
        if (cId != null && cashierMap.containsKey(cId)) {
          cashierMap[cId]!.eodSalesToday = (sc['totalDigitalSales'] ?? 0).toDouble();
          cashierMap[cId]!.eodStatusToday = sc['status']?.toString() ?? 'Closed';
        }
      }
    }

    final outstandingVouchersBalance = vouchersSoldAmount - vouchersUsedAmount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTimeframeSelector(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Sales', '${totalSales.toStringAsFixed(3)} BHD', Icons.monetization_on_outlined)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Total Transactions', totalTransactions.toString(), Icons.receipt_long_outlined)),
            ],
          ),
          const SizedBox(height: 16),
          _buildSalesChart(filteredTransactions, startInterval, endInterval),
          const SizedBox(height: 16),
          _buildStaffSalesComparison(supervisorData, cashierMap.values.toList()),
          const SizedBox(height: 16),
          _buildVouchersPerformance(vouchersSoldCount, vouchersSoldAmount, vouchersUsedCount, vouchersUsedAmount, outstandingVouchersBalance),
          const SizedBox(height: 16),
          _buildSupervisorSummary(supervisorData),
          const SizedBox(height: 16),
          _buildCashierPerformance(cashierMap.values.toList()),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text('FILTER TIMEFRAME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['day', 'week', 'month', 'year', 'custom'].map((mode) {
                final isSelected = _timeframe == mode;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () => setState(() => _timeframe = mode),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.green : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? Colors.green : Colors.grey[300]!),
                      ),
                      child: Text(
                        mode.toUpperCase(),
                        style: TextStyle(color: isSelected ? Colors.white : Colors.grey[800], fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }

  Widget _buildSalesChart(List<Map<String, dynamic>> transactions, DateTime start, DateTime end) {
    List<BarChartGroupData> barGroups = [];
    List<String> titles = [];
    double maxTotal = 0;

    if (_timeframe == 'day') {
      List<String> blocks = ['12 AM', '3 AM', '6 AM', '9 AM', '12 PM', '3 PM', '6 PM', '9 PM'];
      List<double> blockTotals = List.filled(8, 0);

      for (var tx in transactions) {
        if (tx['status'] != 'Completed' && tx['status'] != 'Paid') continue;
        final dateVal = tx['date'];
        DateTime date = dateVal is Timestamp ? dateVal.toDate() : (DateTime.tryParse(dateVal?.toString() ?? '') ?? DateTime.now());
        final hour = date.hour;
        final blockIdx = (hour / 3).floor();
        blockTotals[blockIdx] += (tx['totalAmount'] ?? tx['amount'] ?? 0).toDouble();
      }

      for (int i = 0; i < blocks.length; i++) {
        titles.add(blocks[i]);
        barGroups.add(BarChartGroupData(x: i, barRods: [BarChartRodData(toY: blockTotals[i], color: Colors.green, width: 16, borderRadius: BorderRadius.circular(4))]));
        if (blockTotals[i] > maxTotal) maxTotal = blockTotals[i];
      }
    } else if (_timeframe == 'week') {
      List<DateTime> days = [];
      for (int i = 0; i < 7; i++) {
        days.add(start.add(Duration(days: i)));
      }
      List<double> dailyTotals = List.filled(7, 0);

      for (var tx in transactions) {
        if (tx['status'] != 'Completed' && tx['status'] != 'Paid') continue;
        final dateVal = tx['date'];
        DateTime date = dateVal is Timestamp ? dateVal.toDate() : (DateTime.tryParse(dateVal?.toString() ?? '') ?? DateTime.now());
        int diff = date.difference(start).inDays;
        if (diff >= 0 && diff < 7) {
          dailyTotals[diff] += (tx['totalAmount'] ?? tx['amount'] ?? 0).toDouble();
        }
      }

      for (int i = 0; i < 7; i++) {
        titles.add(DateFormat('EEE').format(days[i]));
        barGroups.add(BarChartGroupData(x: i, barRods: [BarChartRodData(toY: dailyTotals[i], color: Colors.green, width: 16, borderRadius: BorderRadius.circular(4))]));
        if (dailyTotals[i] > maxTotal) maxTotal = dailyTotals[i];
      }
    } else if (_timeframe == 'month' || _timeframe == 'custom') {
      List<double> weekTotals = List.filled(5, 0);
      for (var tx in transactions) {
        if (tx['status'] != 'Completed' && tx['status'] != 'Paid') continue;
        final dateVal = tx['date'];
        DateTime date = dateVal is Timestamp ? dateVal.toDate() : (DateTime.tryParse(dateVal?.toString() ?? '') ?? DateTime.now());
        final day = date.day;
        if (day <= 7) weekTotals[0] += (tx['totalAmount'] ?? tx['amount'] ?? 0).toDouble();
        else if (day <= 14) weekTotals[1] += (tx['totalAmount'] ?? tx['amount'] ?? 0).toDouble();
        else if (day <= 21) weekTotals[2] += (tx['totalAmount'] ?? tx['amount'] ?? 0).toDouble();
        else if (day <= 28) weekTotals[3] += (tx['totalAmount'] ?? tx['amount'] ?? 0).toDouble();
        else weekTotals[4] += (tx['totalAmount'] ?? tx['amount'] ?? 0).toDouble();
      }
      List<String> wTitles = ['W1', 'W2', 'W3', 'W4', 'W5'];
      for (int i = 0; i < 5; i++) {
        titles.add(wTitles[i]);
        barGroups.add(BarChartGroupData(x: i, barRods: [BarChartRodData(toY: weekTotals[i], color: Colors.green, width: 16, borderRadius: BorderRadius.circular(4))]));
        if (weekTotals[i] > maxTotal) maxTotal = weekTotals[i];
      }
    } else if (_timeframe == 'year') {
      List<double> monthTotals = List.filled(12, 0);
      for (var tx in transactions) {
        if (tx['status'] != 'Completed' && tx['status'] != 'Paid') continue;
        final dateVal = tx['date'];
        DateTime date = dateVal is Timestamp ? dateVal.toDate() : (DateTime.tryParse(dateVal?.toString() ?? '') ?? DateTime.now());
        monthTotals[date.month - 1] += (tx['totalAmount'] ?? tx['amount'] ?? 0).toDouble();
      }
      List<String> mTitles = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      for (int i = 0; i < 12; i++) {
        titles.add(mTitles[i]);
        barGroups.add(BarChartGroupData(x: i, barRods: [BarChartRodData(toY: monthTotals[i], color: Colors.green, width: 16, borderRadius: BorderRadius.circular(4))]));
        if (monthTotals[i] > maxTotal) maxTotal = monthTotals[i];
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_timeframe[0].toUpperCase()}${_timeframe.substring(1)}ly Sales Performance', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Sales breakdown for the selected timeframe.', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: (transactions.isEmpty || maxTotal == 0)
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text('No sales data for this timeframe.', style: TextStyle(color: Colors.grey[500])),
                  ],
                ))
              : BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < titles.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(titles[value.toInt()], style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  barGroups: barGroups,
                ),
              ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStaffSalesComparison(UserSalesData supervisor, List<UserSalesData> cashiers) {
    List<BarChartGroupData> barGroups = [];
    int index = 0;
    
    // Add supervisor
    barGroups.add(
      BarChartGroupData(
        x: index++, 
        barRods: [BarChartRodData(toY: supervisor.totalSales, color: Colors.green, width: 20, borderRadius: BorderRadius.circular(4))]
      )
    );
    
    // Add cashiers
    for (var c in cashiers) {
      barGroups.add(
        BarChartGroupData(
          x: index++, 
          barRods: [BarChartRodData(toY: c.totalSales, color: Colors.green, width: 20, borderRadius: BorderRadius.circular(4))]
        )
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Staff Sales Comparison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Compare sales totals between supervisor and cashiers.', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: (supervisor.totalSales == 0 && cashiers.every((c) => c.totalSales == 0))
              ? Center(child: Text('No sales data', style: TextStyle(color: Colors.grey[500])))
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() == 0) return Padding(padding: const EdgeInsets.only(top: 8), child: Text('Supervisor', style: TextStyle(fontSize: 10, color: Colors.grey[600])));
                            if (value.toInt() - 1 < cashiers.length) {
                              return Padding(padding: const EdgeInsets.only(top: 8), child: Text(cashiers[value.toInt() - 1].name.split(' ')[0], style: TextStyle(fontSize: 10, color: Colors.grey[600])));
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                    ),
                    barGroups: barGroups,
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildVouchersPerformance(int count, double amount, int usedCount, double usedAmount, double balance) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: Colors.indigo, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.confirmation_num, color: Colors.indigo, size: 20),
              const SizedBox(width: 8),
              const Text('Vouchers Performance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Vouchers sold, used and outstanding balance.', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 16),
          _buildRow('Vouchers Sold:', '$count sold (${amount.toStringAsFixed(3)} BHD)', Colors.black),
          const Divider(),
          _buildRow('Vouchers Redeemed:', '$usedCount used (${usedAmount.toStringAsFixed(3)} BHD)', Colors.green),
          const Divider(),
          _buildRow('Outstanding Balance:', '${balance.toStringAsFixed(3)} BHD', Colors.indigo, isBold: true),
        ],
      ),
    );
  }

  Widget _buildSupervisorSummary(UserSalesData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: Colors.green, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Text('Supervisor Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          _buildRow('Own Sales:', '${data.totalSales.toStringAsFixed(3)} BHD', Colors.black, isBold: true),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Completed Requests:', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.green, size: 14),
                          const SizedBox(width: 4),
                          Text('${data.completedRequestsCount} (${data.completedRequestsAmount.toStringAsFixed(3)} BHD)', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pending Requests:', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.orange, size: 14),
                          const SizedBox(width: 4),
                          Text('${data.pendingRequestsCount} (${data.pendingRequestsAmount.toStringAsFixed(3)} BHD)', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Payment Methods Breakdown:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 8),
          if (data.paymentMethods.isEmpty)
            Text('No sales recorded yet.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[500], fontSize: 12))
          else
            ...data.paymentMethods.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _buildRow('${e.key}:', '${e.value.toStringAsFixed(3)} BHD', Colors.grey[700]!),
            )),
        ],
      ),
    );
  }

  Widget _buildCashierPerformance(List<UserSalesData> cashiers) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: Colors.blue, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text('Cashier Performance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          if (cashiers.isEmpty)
            Center(child: Text('No cashiers registered.', style: TextStyle(color: Colors.grey[500], fontSize: 14)))
          else
            ...cashiers.map((c) => _buildCashierItem(c)),
        ],
      ),
    );
  }

  Widget _buildCashierItem(UserSalesData c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                child: Text('Total: ${c.totalSales.toStringAsFixed(3)} BHD', style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Today's End of Day Sales:", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.eodStatusToday == 'Closed' ? Colors.green : Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('${c.eodSalesToday.toStringAsFixed(3)} BHD (${c.eodStatusToday})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Completed Requests:', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.green, size: 14),
                          const SizedBox(width: 4),
                          Text('${c.completedRequestsCount} (${c.completedRequestsAmount.toStringAsFixed(3)} BHD)', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pending Requests:', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.orange, size: 14),
                          const SizedBox(width: 4),
                          Text('${c.pendingRequestsCount} (${c.pendingRequestsAmount.toStringAsFixed(3)} BHD)', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Payment Methods Breakdown:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 8),
          if (c.paymentMethods.isEmpty)
            Text('No sales recorded yet.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[500], fontSize: 12))
          else
            ...c.paymentMethods.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _buildRow('${e.key}:', '${e.value.toStringAsFixed(3)} BHD', Colors.grey[700]!),
            )),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, Color valueColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(value, style: TextStyle(color: valueColor, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:libra_go/screens/add_expense_screen.dart';
import 'package:libra_go/services/supabase_service.dart';

class CulinaryDetailScreen extends StatefulWidget {
  final String? tripId;
  final int? month;
  final int? year;
  const CulinaryDetailScreen({super.key, this.tripId, this.month, this.year});

  @override
  State<CulinaryDetailScreen> createState() => _CulinaryDetailScreenState();
}

class _CulinaryDetailScreenState extends State<CulinaryDetailScreen> {
  final _supabase = SupabaseService();
  List<Map<String, dynamic>> _expenses = [];
  int _total = 0;
  bool _isLoading = true;
  String? _activeTripId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      List<Map<String, dynamic>> expenses = [];
      
      if (widget.month != null && widget.year != null) {
        expenses = await _supabase.getMonthlyExpensesByCategory('culinary', widget.month!, widget.year!);
      } else {
        if (widget.tripId != null) {
          _activeTripId = widget.tripId;
        } else {
          final trips = await _supabase.getTrips();
          final activeTrip = trips.firstWhere((t) => t['status'] == 'active', orElse: () => <String, dynamic>{});
          _activeTripId = activeTrip.isNotEmpty ? activeTrip['id'].toString() : null;
        }
        expenses = await _supabase.getExpensesByCategory('culinary', tripId: _activeTripId);
      }
      
      int total = 0;
      for (var e in expenses) {
        total += (e['amount'] as num).toInt();
      }
      if (mounted) {
        setState(() {
          _expenses = expenses;
          _total = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatRupiah(int amount) {
    String result = amount.toString();
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    result = result.replaceAllMapped(regex, (Match m) => '${m[1]}.');
    return 'Rp $result';
  }

  Future<void> _deleteAllHistory() async {
    if (_expenses.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat'),
        content: const Text('Apakah Anda yakin ingin menghapus semua riwayat pengeluaran kuliner untuk perjalanan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _supabase.deleteExpensesByCategory('culinary', tripId: _activeTripId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua riwayat kuliner telah dihapus')));
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyAvg = _expenses.isNotEmpty ? _total ~/ 30 : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0D1B2A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detail Kuliner', style: TextStyle(color: Color(0xFF0D1B2A), fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF0D1B2A)),
            onSelected: (value) {
              if (value == 'delete_all') {
                _deleteAllHistory();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'delete_all',
                  child: Text('Hapus Riwayat Perjalanan Ini', style: TextStyle(color: Colors.red)),
                ),
              ];
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [const Color(0xFFE8F0FE), const Color(0xFFF7F9FB)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOTAL SPENT', style: TextStyle(color: Color(0xFF596273), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        const SizedBox(height: 8),
                        Text(_formatRupiah(_total), style: const TextStyle(color: Color(0xFF0D1B2A), fontSize: 36, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_expenses.length} transactions', style: const TextStyle(color: Color(0xFF596273), fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        Expanded(child: _buildStatCard(icon: Icons.restaurant, title: 'Total Items', value: '${_expenses.length}', subtitle: 'this trip')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatCard(icon: Icons.money, title: 'Daily Avg', value: _formatRupiah(dailyAvg), subtitle: 'Based on 30 days', iconColor: const Color(0xFF1E8F82))),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Recent Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                        Text('View All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E8F82))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_expenses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        width: double.infinity, padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
                        child: Column(children: const [Icon(Icons.receipt_long, color: Color(0xFFE8ECEF), size: 40), SizedBox(height: 8), Text('Belum ada transaksi kuliner', style: TextStyle(color: Color(0xFF596273)))]),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: _expenses.map((expense) {
                          final date = expense['date'] != null ? DateTime.tryParse(expense['date'].toString()) : null;
                          final dateStr = date != null ? '${date.day}/${date.month} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}' : '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => AddExpenseScreen(expense: expense)),
                                );
                                if (result == true) _loadData();
                              },
                              child: _buildTransactionCard(Icons.restaurant, expense['name'] ?? '-', dateStr, _formatRupiah((expense['amount'] as num).toInt())),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: SizedBox(
                      width: double.infinity, height: 55,
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddExpenseScreen()));
                          if (result == true) _loadData();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D1B2A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                        child: const Text('Add New Expense', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String title, required String value, required String subtitle, Color iconColor = const Color(0xFF0D1B2A)}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: iconColor, size: 16), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A)))]),
        const SizedBox(height: 16),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF596273))),
      ]),
    );
  }

  Widget _buildTransactionCard(IconData icon, String title, String subtitle, String amount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Color(0xFF0D1B2A), shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 20)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0D1B2A))),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF596273))),
        ])),
        Text(amount, style: const TextStyle(color: Color(0xFF0D1B2A), fontWeight: FontWeight.w600, fontSize: 14)),
      ]),
    );
  }
}

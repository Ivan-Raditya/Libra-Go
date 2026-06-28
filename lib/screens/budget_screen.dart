import 'package:flutter/material.dart';
import 'package:libra_go/screens/transport_detail_screen.dart';
import 'package:libra_go/screens/culinary_detail_screen.dart';
import 'package:libra_go/screens/accommodation_detail_screen.dart';
import 'package:libra_go/screens/shopping_detail_screen.dart';
import 'package:libra_go/screens/add_expense_screen.dart';
import 'package:libra_go/services/supabase_service.dart';

class BudgetScreen extends StatefulWidget {
  final Map<String, dynamic>? trip;
  const BudgetScreen({super.key, this.trip});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _supabase = SupabaseService();
  List<Map<String, dynamic>> _expenses = [];
  int _totalExpenses = 0;
  bool _isLoading = true;

  // Category totals
  int _culinaryTotal = 0;
  int _transportTotal = 0;
  int _accommodationTotal = 0;
  int _shoppingTotal = 0;
  
  Map<String, dynamic>? _activeTrip;
  
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  int _monthlyBudget = 0;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    try {
      List<Map<String, dynamic>> expenses = [];
      
      if (widget.trip != null) {
        _activeTrip = widget.trip;
        expenses = await _supabase.getExpenses(tripId: _activeTrip!['id'].toString());
      } else {
        _activeTrip = null;
        expenses = await _supabase.getMonthlyExpenses(_selectedMonth, _selectedYear);
        _monthlyBudget = await _supabase.getMonthlyBudget(_selectedMonth, _selectedYear);
      }
          
      int culinary = 0, transport = 0, accommodation = 0, shopping = 0, total = 0;

      for (var e in expenses) {
        final amount = (e['amount'] as num).toInt();
        total += amount;
        switch (e['category']) {
          case 'culinary':
            culinary += amount;
            break;
          case 'transport':
          case 'flight':
            transport += amount;
            break;
          case 'accommodation':
            accommodation += amount;
            break;
          case 'shopping':
            shopping += amount;
            break;
        }
      }

      if (mounted) {
        setState(() {
          _expenses = expenses;
          _totalExpenses = total;
          _culinaryTotal = culinary;
          _transportTotal = transport;
          _accommodationTotal = accommodation;
          _shoppingTotal = shopping;
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

  String _formatShortRupiah(int amount) {
    if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}k';
    }
    return 'Rp $amount';
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'culinary': return Icons.restaurant;
      case 'transport': return Icons.directions_car;
      case 'accommodation': return Icons.bed;
      case 'flight': return Icons.flight;
      case 'shopping': return Icons.shopping_bag_outlined;
      default: return Icons.receipt;
    }
  }

  String _getCategoryName(String? category) {
    switch (category) {
      case 'culinary': return 'Kuliner';
      case 'transport': return 'Transport';
      case 'accommodation': return 'Hotel';
      case 'flight': return 'Penerbangan';
      case 'shopping': return 'Belanja';
      default: return 'Lainnya';
    }
  }

  String _getMonthNameShort(int month) {
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    if (month >= 1 && month <= 12) return monthNames[month - 1];
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final budget = widget.trip != null ? ((_activeTrip?['budget'] as num?)?.toInt() ?? 0) : _monthlyBudget;
    final usagePercent = budget > 0 ? (_totalExpenses / budget * 100).clamp(0, 100).toInt() : 0;
    final progressFactor = budget > 0 ? (_totalExpenses / budget).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = budget > 0 && _totalExpenses > budget;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0D1B2A)),
          onPressed: () {},
        ),
        title: const Text(
          'Riwayat Anggaran',
          style: TextStyle(color: Color(0xFF0D1B2A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Color(0xFF0D1B2A)), onPressed: () {}),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month Filter (only show if not specific trip)
                      if (widget.trip == null)
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Filter Bulanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  DropdownButton<int>(
                                    value: _selectedYear,
                                    items: [DateTime.now().year - 1, DateTime.now().year, DateTime.now().year + 1].map((year) {
                                      return DropdownMenuItem<int>(
                                        value: year, 
                                        child: Text(year.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A)))
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedYear = val;
                                          _isLoading = true;
                                        });
                                        _loadExpenses();
                                      }
                                    },
                                    underline: const SizedBox(),
                                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF0D1B2A)),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 40,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                itemCount: 12,
                                itemBuilder: (context, index) {
                                  final month = index + 1;
                                  final isSelected = month == _selectedMonth;
                                  final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedMonth = month;
                                        _isLoading = true;
                                      });
                                      _loadExpenses();
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFF0D1B2A) : Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: isSelected ? const Color(0xFF0D1B2A) : const Color(0xFFE0E0E0)),
                                      ),
                                      child: Center(
                                        child: Text(
                                          monthNames[index],
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : const Color(0xFF596273),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      if (widget.trip != null) const SizedBox(height: 12),
                      const SizedBox(height: 24),
                      
                      // Total Spending Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                  widget.trip == null 
                                      ? 'TOTAL PENGELUARAN BULAN ${_selectedMonth.toString().padLeft(2, '0')}/$_selectedYear'
                                      : 'TOTAL PENGELUARAN PERJALANAN INI',
                                  style: const TextStyle(color: Color(0xFF596273), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                _formatRupiah(_totalExpenses),
                                style: const TextStyle(color: Color(0xFF0D1B2A), fontSize: 32, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: isOverBudget ? const Color(0xFFD32F2F) : const Color(0xFF1E8F82),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isOverBudget ? Icons.warning : Icons.check,
                                      color: Colors.white, size: 10,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isOverBudget ? 'Melebihi Anggaran!' : 'Dalam Batas Anggaran',
                                    style: TextStyle(
                                      color: isOverBudget ? const Color(0xFFD32F2F) : const Color(0xFF1E8F82),
                                      fontSize: 12, fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Target: ${_formatRupiah(budget)}', style: const TextStyle(color: Color(0xFF596273), fontSize: 12, fontWeight: FontWeight.bold)),
                                  Text('$usagePercent%', style: const TextStyle(color: Color(0xFF0D1B2A), fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Stack(
                                children: [
                                  Container(height: 6, decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(3))),
                                  FractionallySizedBox(
                                    widthFactor: progressFactor.toDouble(),
                                    child: Container(height: 6, decoration: BoxDecoration(color: const Color(0xFF1E8F82), borderRadius: BorderRadius.circular(3))),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Categories Grid
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text('Rincian Kategori', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _buildCategoryCard(Icons.restaurant, 'Kuliner', _formatShortRupiah(_culinaryTotal),
                                      _totalExpenses > 0 ? _culinaryTotal / _totalExpenses : 0, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => CulinaryDetailScreen(
                                      tripId: widget.trip?['id']?.toString(),
                                      month: widget.trip == null ? _selectedMonth : null,
                                      year: widget.trip == null ? _selectedYear : null,
                                    )));
                                  }),
                                  const SizedBox(height: 16),
                                  _buildCategoryCard(Icons.directions_car, 'Transport', _formatShortRupiah(_transportTotal),
                                      _totalExpenses > 0 ? _transportTotal / _totalExpenses : 0, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => TransportDetailScreen(
                                      tripId: widget.trip?['id']?.toString(),
                                      month: widget.trip == null ? _selectedMonth : null,
                                      year: widget.trip == null ? _selectedYear : null,
                                    )));
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildCategoryCard(Icons.shopping_bag_outlined, 'Belanja', _formatShortRupiah(_shoppingTotal),
                                      _totalExpenses > 0 ? _shoppingTotal / _totalExpenses : 0, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => ShoppingDetailScreen(
                                      tripId: widget.trip?['id']?.toString(),
                                      month: widget.trip == null ? _selectedMonth : null,
                                      year: widget.trip == null ? _selectedYear : null,
                                    )));
                                  }),
                                  const SizedBox(height: 16),
                                  _buildCategoryCard(Icons.bed, 'Hotel', _formatShortRupiah(_accommodationTotal),
                                      _totalExpenses > 0 ? _accommodationTotal / _totalExpenses : 0, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => AccommodationDetailScreen(
                                      tripId: widget.trip?['id']?.toString(),
                                      month: widget.trip == null ? _selectedMonth : null,
                                      year: widget.trip == null ? _selectedYear : null,
                                    )));
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Recent Transactions
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Transaksi Terakhir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                            Text('Lihat Semua', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E8F82))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Transactions List from Supabase
                      if (_expenses.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Column(
                              children: const [
                                Icon(Icons.receipt_long, color: Color(0xFFE8ECEF), size: 40),
                                SizedBox(height: 8),
                                Text('Belum ada transaksi', style: TextStyle(color: Color(0xFF596273), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _expenses.take(5).map((expense) {
                              final category = expense['category'] ?? '';
                              final time = expense['date'] != null
                                  ? DateTime.tryParse(expense['date'].toString())
                                  : null;
                              final timeStr = time != null
                                  ? widget.trip == null 
                                      ? '${time.day} ${_getMonthNameShort(time.month)} • ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                                      : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                                  : '';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: InkWell(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => AddExpenseScreen(expense: expense)),
                                    );
                                    if (result == true) _loadExpenses();
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: _buildTransactionItem(
                                    icon: _getCategoryIcon(category),
                                    title: expense['name'] ?? '-',
                                    subtitle: '${_getCategoryName(category)} • $timeStr',
                                    amount: '- ${_formatRupiah((expense['amount'] as num).toInt())}',
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
                
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: FloatingActionButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
                      );
                      if (result == true) _loadExpenses();
                    },
                    backgroundColor: const Color(0xFF0D1B2A),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMonthPill(String text, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF0D1B2A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isActive ? null : Border.all(color: Colors.black12),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(color: isActive ? Colors.white : const Color(0xFF596273), fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildCategoryCard(IconData icon, String title, String amount, double progress, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFF0D1B2A), shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A)))),
              ],
            ),
            const SizedBox(height: 16),
            Text(amount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
            const SizedBox(height: 8),
            Stack(
              children: [
                Container(height: 4, decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(2))),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFF1E8F82), borderRadius: BorderRadius.circular(2))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(color: Color(0xFFE8ECEF), shape: BoxShape.circle),
          child: Icon(icon, color: const Color(0xFF0D1B2A), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0D1B2A))),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF596273))),
            ],
          ),
        ),
        Text(amount, style: const TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}

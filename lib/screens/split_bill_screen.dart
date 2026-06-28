import 'package:flutter/material.dart';
import 'package:libra_go/services/supabase_service.dart';

class SplitBillScreen extends StatefulWidget {
  final String tripId;
  const SplitBillScreen({super.key, required this.tripId});

  @override
  State<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends State<SplitBillScreen> {
  final _supabase = SupabaseService();
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    try {
      final expenses = await _supabase.getExpenses(tripId: widget.tripId);
      if (mounted) {
        setState(() {
          _expenses = expenses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    // Simplistic split bill logic: sum all expenses, divide by members.
    // In a real app, we'd check `paid_by` and calculate exactly who owes whom.
    final total = _expenses.fold<int>(0, (sum, item) => sum + (item['amount'] as num).toInt());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Bill (Patungan)', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('Total Pengeluaran Grup', style: TextStyle(color: Color(0xFF596273))),
                  const SizedBox(height: 8),
                  Text('Rp $total', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Icon(Icons.construction, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Fitur Split Bill detail sedang dalam pengembangan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF596273)),
            ),
          ],
        ),
      ),
    );
  }
}

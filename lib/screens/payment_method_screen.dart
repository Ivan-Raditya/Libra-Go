import 'package:flutter/material.dart';
import 'package:libra_go/services/supabase_service.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  final _supabase = SupabaseService();
  List<Map<String, dynamic>> _methods = [];
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final methods = await _supabase.getPaymentMethods();
      final profile = await _supabase.getProfile();
      if (mounted) {
        setState(() {
          _methods = methods;
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addPaymentMethod(String type, String name) async {
    try {
      await _supabase.addPaymentMethod({
        'type': type,
        'name': name,
        'card_number': type == 'credit_card' ? '•••• •••• •••• ${DateTime.now().millisecond}' : null,
        'balance': type == 'e_wallet' ? 0 : null,
      });
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name berhasil ditambahkan'),
            backgroundColor: const Color(0xFF0D1B2A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    }
  }

  String _formatRupiah(int amount) {
    String result = amount.toString();
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    result = result.replaceAllMapped(regex, (Match m) => '${m[1]}.');
    return 'Rp $result';
  }

  @override
  Widget build(BuildContext context) {
    final holderName = (_profile?['full_name'] ?? 'CARD HOLDER').toString().toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0D1B2A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Metode Pembayaran',
          style: TextStyle(color: Color(0xFF0D1B2A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: Color(0xFF0D1B2A)), onPressed: () {}),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned(
                  top: 0, left: 0,
                  child: Container(
                    width: 150, height: 150,
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(colors: [Color(0xFFD9F4F2), Colors.transparent], radius: 0.8),
                    ),
                  ),
                ),
                
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      
                      // Saved Methods
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'METODE TERSIMPAN',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Color(0xFF596273)),
                            ),
                            Text(
                              '${_methods.length} tersimpan',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E8F82)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dynamic payment methods
                      if (_methods.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Column(
                              children: const [
                                Icon(Icons.credit_card_off, color: Color(0xFFE8ECEF), size: 48),
                                SizedBox(height: 12),
                                Text('Belum ada metode pembayaran', style: TextStyle(color: Color(0xFF596273), fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text('Tambah metode baru di bawah', style: TextStyle(color: Color(0xFF596273), fontSize: 12)),
                              ],
                            ),
                          ),
                        )
                      else
                        ...List.generate(_methods.length, (index) {
                          final method = _methods[index];
                          final type = method['type'] ?? '';

                          if (type == 'credit_card' || type == 'debit_card') {
                            return Padding(
                              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
                              child: _buildCreditCard(method, holderName),
                            );
                          } else {
                            return Padding(
                              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
                              child: _buildEWalletCard(method),
                            );
                          }
                        }),
                      
                      const SizedBox(height: 24),
                      
                      // Add New Method
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          'TAMBAH METODE BARU',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Color(0xFF596273)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            _buildAddMethodItem(Icons.credit_card, 'Kartu Kredit atau Debit', () {
                              _addPaymentMethod('credit_card', 'Visa Card');
                            }),
                            const SizedBox(height: 12),
                            _buildAddMethodItem(Icons.account_balance, 'Transfer Bank (VA)', () {
                              _addPaymentMethod('bank_transfer', 'Bank Transfer');
                            }),
                            const SizedBox(height: 12),
                            _buildAddMethodItem(Icons.account_balance_wallet_outlined, 'E-Wallet (OVO, Dana)', () {
                              _addPaymentMethod('e_wallet', 'E-Wallet');
                            }),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Security Info
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4F8),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.lock_outline, color: Color(0xFF596273), size: 16),
                                  SizedBox(width: 8),
                                  Text('KEAMANAN TERJAMIN', style: TextStyle(color: Color(0xFF596273), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Data kartu Anda dienkripsi secara end-to-end dan memenuhi standar keamanan internasional PCI DSS.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF596273), fontSize: 12, height: 1.5),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
                                    child: const Icon(Icons.check, color: Colors.white, size: 12),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Norton Secured', style: TextStyle(color: Color(0xFF596273), fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCreditCard(Map<String, dynamic> method, String holderName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('LIBRA\nPLATINUM', style: TextStyle(color: Color(0xFF596273), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const Text('VISA', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(width: 30, height: 20, decoration: BoxDecoration(color: const Color(0xFF2C3E50), borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 8),
              Container(width: 30, height: 20, decoration: BoxDecoration(color: const Color(0xFF2C3E50), borderRadius: BorderRadius.circular(4))),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            method['card_number'] ?? '• • • •    • • • •    • • • •    0000',
            style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2.0),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CARD HOLDER', style: TextStyle(color: Color(0xFF596273), fontSize: 8, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(holderName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('EXPIRES', style: TextStyle(color: Color(0xFF596273), fontSize: 8, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('09 / 28', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEWalletCard(Map<String, dynamic> method) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Color(0xFF75E6DA), shape: BoxShape.circle),
            child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(method['name'] ?? 'E-Wallet', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                const SizedBox(height: 4),
                Text(
                  'Tersambung • ${method['card_number'] ?? ''}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF596273)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('SALDO', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF596273))),
              const SizedBox(height: 4),
              Text(
                _formatRupiah((method['balance'] as num?)?.toInt() ?? 0),
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E8F82)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddMethodItem(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0D1B2A)),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(color: Color(0xFF0D1B2A), fontWeight: FontWeight.bold, fontSize: 14))),
            const Icon(Icons.chevron_right, color: Color(0xFF596273)),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:libra_go/services/supabase_service.dart';
import 'package:libra_go/models/destination.dart';
import 'package:libra_go/screens/destination_detail_screen.dart';
import 'package:libra_go/screens/add_expense_screen.dart';
import 'package:libra_go/screens/all_destinations_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = SupabaseService();
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _trips = [];
  int _totalExpenses = 0;
  bool _isLoading = true;

  String _selectedCurrency = 'IDR';
  Map<String, dynamic> _exchangeRates = {
    'IDR': 1.0,
    'USD': 0.000061,
    'SGD': 0.000083,
    'JPY': 0.0094,
    'EUR': 0.000057,
    'MYR': 0.00029,
    'AUD': 0.000093,
  };
  final List<String> _currencies = ['IDR', 'USD', 'SGD', 'JPY', 'EUR', 'MYR', 'AUD'];

  @override
  void initState() {
    super.initState();
    _loadData();
    _fetchExchangeRates();
  }

  Future<void> _fetchExchangeRates() async {
    try {
      final response = await http.get(Uri.parse('https://open.er-api.com/v6/latest/IDR'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _exchangeRates = data['rates'] ?? {'IDR': 1.0};
          });
        }
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _loadData() async {
    try {
      final profile = await _supabase.getProfile();
      final trips = await _supabase.getTrips();
      final activeTrip = trips.firstWhere((t) => t['status'] == 'active', orElse: () => <String, dynamic>{});
      final totalExpenses = activeTrip.isNotEmpty 
          ? await _supabase.getTotalExpenses(tripId: activeTrip['id'].toString())
          : 0;
      if (mounted) {
        setState(() {
          _profile = profile;
          _trips = trips;
          _totalExpenses = totalExpenses;
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

  String _formatCurrency(double amount, {bool hideSymbol = false}) {
    if (_selectedCurrency == 'IDR') {
      final str = _formatRupiah(amount.toInt());
      return hideSymbol ? str.replaceFirst('Rp ', '') : str;
    }
    
    String amountStr = amount.toStringAsFixed(2);
    final parts = amountStr.split('.');
    String intPart = parts[0];
    
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    intPart = intPart.replaceAllMapped(regex, (Match m) => '${m[1]},');
    
    String decPart = parts[1] == '00' ? '' : '.${parts[1]}';
    final formatted = '$intPart$decPart';
    
    return hideSymbol ? formatted : '$_selectedCurrency $formatted';
  }

  Future<void> _endTrip() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Akhiri Perjalanan?'),
        content: const Text('Perjalanan ini akan ditandai selesai. Saldo di Beranda akan dikosongkan hingga Anda memulai perjalanan baru.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Akhiri', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _supabase.deactivateAllTrips();
        await _loadData();
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.currentUser;
    final displayName = _profile?['full_name'] ?? user?.userMetadata?['full_name'] ?? 'Petualang';
    final activeTrip = _trips.firstWhere((t) => t['status'] == 'active', orElse: () => <String, dynamic>{});
    final hasActiveTrip = activeTrip.isNotEmpty;
    final budget = hasActiveTrip ? ((activeTrip['budget'] as num?)?.toInt() ?? 0) : 0;
    final remaining = budget - _totalExpenses;
    final usagePercent = budget > 0 ? (_totalExpenses / budget * 100).clamp(0, 100).toInt() : 0;
    final progressFactor = budget > 0 ? (_totalExpenses / budget).clamp(0.0, 1.0) : 0.0;

    final rate = (_exchangeRates[_selectedCurrency] as num?)?.toDouble() ?? 1.0;
    final convertedRemaining = remaining * rate;
    final convertedTotal = _totalExpenses * rate;

    // Get the first upcoming trip if available
    final upcomingTrip = _trips.isNotEmpty ? _trips.first : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Section
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipPath(
                        clipper: DashboardHeaderClipper(),
                        child: Container(
                          padding: const EdgeInsets.only(
                            top: 60,
                            left: 24,
                            right: 24,
                            bottom: 80,
                          ),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF344D59), Color(0xFF52B8AC)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Libra Go',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.notifications_none,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),
                              const Text(
                                'SELAMAT DATANG',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Halo, $displayName!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Overlapping Card (Removed Positioned to fix hit testing)
                      Container(
                        margin: const EdgeInsets.only(top: 180, left: 24, right: 24),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 20,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!hasActiveTrip) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  alignment: Alignment.center,
                                  child: Column(
                                    children: [
                                      const Icon(Icons.flight_takeoff, size: 48, color: Color(0xFFE8ECEF)),
                                      const SizedBox(height: 16),
                                      const Text('Belum ada perjalanan aktif', style: TextStyle(color: Color(0xFF596273), fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      const Text('Tambahkan perjalanan baru di tab Trips untuk memantau pengeluaranmu!', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF596273), fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'SISA ANGGARAN',
                                          style: TextStyle(
                                            color: Color(0xFF596273),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          height: 24,
                                          padding: const EdgeInsets.symmetric(horizontal: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8ECEF),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: _selectedCurrency,
                                              isDense: true,
                                              icon: const Icon(Icons.arrow_drop_down, size: 16),
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF0D1B2A), fontWeight: FontWeight.bold),
                                              items: _currencies.map((curr) {
                                                return DropdownMenuItem(value: curr, child: Text(curr));
                                              }).toList(),
                                              onChanged: (val) {
                                                if (val != null) {
                                                  setState(() => _selectedCurrency = val);
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD9F4F2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.account_balance_wallet_outlined,
                                        color: Color(0xFF0D1B2A),
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _selectedCurrency == 'IDR' 
                                      ? 'Rp\n${_formatCurrency(remaining.toDouble(), hideSymbol: true)}'
                                      : '$_selectedCurrency\n${_formatCurrency(convertedRemaining, hideSymbol: true)}',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0D1B2A),
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Progress Bar
                                Stack(
                                  children: [
                                    Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0F0F0),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: progressFactor.toDouble(),
                                      child: Container(
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E8F82),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Terpakai: ${_formatCurrency(convertedTotal)}',
                                      style: const TextStyle(
                                        color: Color(0xFF596273),
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '$usagePercent%',
                                      style: const TextStyle(
                                        color: Color(0xFF596273),
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 48,
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
                                            );
                                            if (result == true) _loadData();
                                          },
                                          icon: const Icon(Icons.add, size: 18),
                                          label: const Text('Tambah Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF0D1B2A),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      height: 48,
                                      child: OutlinedButton(
                                        onPressed: _endTrip,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.red),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Icon(Icons.power_settings_new, size: 20),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Upcoming Trips Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Perjalanan Mendatang',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D1B2A),
                          ),
                        ),
                        Text(
                          'Lihat Semua',
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF1E8F82),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Upcoming Trip Card (from Supabase or placeholder)
                  if (upcomingTrip != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 140,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                                image: DecorationImage(
                                  image: NetworkImage(
                                    upcomingTrip['image_url'] ??
                                        'https://images.unsplash.com/photo-1537996194471-e657df975ab4?q=80&w=600&auto=format&fit=crop',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.calendar_today, size: 12, color: Color(0xFF0D1B2A)),
                                        const SizedBox(width: 4),
                                        Text(
                                          upcomingTrip['start_date'] ?? 'TBD',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0D1B2A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    upcomingTrip['name'] ?? '-',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0D1B2A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF596273)),
                                      const SizedBox(width: 4),
                                      Text(
                                        upcomingTrip['destination'] ?? 'Belum ditentukan',
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF596273)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.flight_takeoff, color: Color(0xFFE8ECEF), size: 48),
                            SizedBox(height: 12),
                            Text(
                              'Belum ada perjalanan',
                              style: TextStyle(
                                color: Color(0xFF596273),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tambah perjalanan baru di tab Trips',
                              style: TextStyle(color: Color(0xFF596273), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Popular Destinations Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Destinasi Populer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D1B2A),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AllDestinationsScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'Lihat Semua',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF52B8AC),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF52B8AC)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: popularDestinations.length,
                      itemBuilder: (context, index) {
                        final destination = popularDestinations[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DestinationDetailScreen(destination: destination),
                                ),
                              );
                            },
                            child: _buildDestinationCard(
                              destination.name,
                              destination.country,
                              destination.imageUrl,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDestinationCard(String title, String subtitle, String imageUrl) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.3),
            BlendMode.darken,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                letterSpacing: 1.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 10,
      size.width,
      size.height - 50,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

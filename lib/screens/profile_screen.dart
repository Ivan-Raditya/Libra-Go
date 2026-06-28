import 'package:flutter/material.dart';
import 'package:libra_go/screens/personal_info_screen.dart';
import 'package:libra_go/screens/payment_method_screen.dart';
import 'package:libra_go/screens/help_screen.dart';
import 'package:libra_go/screens/security_screen.dart';
import 'package:libra_go/services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = SupabaseService();
  Map<String, dynamic>? _profile;
  int _tripsCount = 0;
  int _countriesCount = 0;
  int _savedAmount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _supabase.getProfile();
      final trips = await _supabase.getTrips();
      
      int tripsCount = trips.length;
      final Set<String> uniqueDestinations = {};
      int totalBudget = 0;
      int totalExpenses = 0;
      
      for (var trip in trips) {
        if (trip['destination'] != null && trip['destination'].toString().isNotEmpty) {
          // Simplistic way to count unique countries/destinations
          uniqueDestinations.add(trip['destination'].toString().split(',').last.trim().toLowerCase());
        }
        totalBudget += (trip['budget'] as num?)?.toInt() ?? 0;
        final expenses = await _supabase.getTotalExpenses(tripId: trip['id'].toString());
        totalExpenses += expenses;
      }
      
      int savedAmount = totalBudget - totalExpenses;
      if (savedAmount < 0) savedAmount = 0;

      if (mounted) {
        setState(() {
          _profile = profile;
          _tripsCount = tripsCount;
          _countriesCount = uniqueDestinations.length;
          _savedAmount = savedAmount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _supabase.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal logout: $e')),
      );
    }
  }

  String _formatShortRupiah(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1).replaceAll('.0', '')}jt';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1).replaceAll('.0', '')}rb';
    }
    return amount.toString();
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.currentUser;
    final displayName = _profile?['full_name'] ?? user?.userMetadata?['full_name'] ?? 'Pengguna';
    final displayEmail = user?.email ?? '-';

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
          'Libra Go',
          style: TextStyle(
            color: Color(0xFF0D1B2A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF0D1B2A)),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Profile Picture
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            image: DecorationImage(
                              image: NetworkImage(
                                _profile?['avatar_url'] ?? 'https://i.pravatar.cc/150?img=11',
                              ),
                              fit: BoxFit.cover,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0D1B2A),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Name and Email
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0D1B2A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayEmail,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF596273),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Statistics Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(_tripsCount.toString(), 'TRIPS'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(_countriesCount.toString(), 'COUNTRIES'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(_formatShortRupiah(_savedAmount), 'SAVED'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Menu Items
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        _buildMenuItem(Icons.person_outline, 'Informasi Pribadi', onTap: () async {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalInfoScreen()));
                          if (result == true) {
                            setState(() => _isLoading = true);
                            _loadProfile();
                          }
                        }),
                        _buildMenuItem(Icons.credit_card_outlined, 'Metode Pembayaran', onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentMethodScreen()));
                        }),
                        _buildMenuItem(Icons.receipt_long_outlined, 'Riwayat Anggaran'),
                        _buildMenuItem(Icons.security_outlined, 'Keamanan', onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const SecurityScreen()));
                        }),
                        _buildMenuItem(Icons.help_outline, 'Bantuan', isLast: true, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpScreen()));
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Logout Button
                  TextButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(
                      Icons.logout,
                      color: Color(0xFFD32F2F),
                      size: 20,
                    ),
                    label: const Text(
                      'Keluar',
                      style: TextStyle(
                        color: Color(0xFFD32F2F),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Color(0xFF596273),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {bool isLast = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D1B2A),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0D1B2A),
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF596273), size: 20),
              ],
            ),
          ),
          if (!isLast)
            const Divider(
              color: Colors.black12,
              height: 24,
              thickness: 1,
            ),
        ],
      ),
    );
  }
}

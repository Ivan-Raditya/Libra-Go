import 'package:flutter/material.dart';
import 'package:libra_go/screens/vacation_detail_screen.dart';
import 'package:libra_go/screens/add_vacation_screen.dart';
import 'package:libra_go/screens/all_trips_screen.dart';
import 'package:libra_go/services/supabase_service.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  final _supabase = SupabaseService();
  List<Map<String, dynamic>> _trips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    try {
      final trips = await _supabase.getTrips();
      if (mounted) {
        setState(() {
          _trips = trips;
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

  @override
  Widget build(BuildContext context) {
    final activeTrip = _trips.isNotEmpty ? _trips.firstWhere(
      (t) => t['status'] == 'active',
      orElse: () => _trips.first,
    ) : null;
    final otherTrips = _trips.where((t) => t != activeTrip).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0D1B2A)),
          onPressed: () => Navigator.pop(context),
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
            icon: const Icon(Icons.search, color: Color(0xFF0D1B2A)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFF0D1B2A)),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Background Curve
                Positioned(
                  top: 0, left: 0, right: 0, height: 140,
                  child: ClipPath(
                    clipper: HeaderWaveClipper(),
                    child: Container(color: const Color(0xFFE8ECEF)),
                  ),
                ),
                
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          'Rencana Perjalanan',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0D1B2A)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          'Kemanakah petualangan Anda selanjutnya?',
                          style: TextStyle(fontSize: 14, color: Color(0xFF596273)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Active Trip Card
                      if (activeTrip != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => VacationDetailScreen(trip: activeTrip)));
                              if (result == true) _loadTrips();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    height: 160,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(24),
                                        topRight: Radius.circular(24),
                                      ),
                                      image: DecorationImage(
                                        image: NetworkImage(activeTrip['image_url'] ?? 'https://picsum.photos/id/1018/600/400'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(24),
                                              topRight: Radius.circular(24),
                                            ),
                                            gradient: LinearGradient(
                                              colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 16, left: 16,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (activeTrip['status'] ?? 'UPCOMING').toString().toUpperCase(),
                                                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                activeTrip['name'] ?? '-',
                                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (activeTrip['start_date'] != null)
                                          Positioned(
                                            bottom: 16, right: 16,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1E8F82),
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.calendar_today, size: 12, color: Colors.white),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    activeTrip['start_date'] ?? '',
                                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(color: Color(0xFF0D1B2A), shape: BoxShape.circle),
                                          child: const Icon(Icons.location_on, color: Colors.white, size: 16),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('LOKASI', style: TextStyle(color: Color(0xFF596273), fontSize: 10)),
                                              Text(
                                                activeTrip['destination'] ?? 'Belum ditentukan',
                                                style: const TextStyle(color: Color(0xFF0D1B2A), fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text('ANGGARAN', style: TextStyle(color: Color(0xFF596273), fontSize: 10)),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatRupiah((activeTrip['budget'] as num?)?.toInt() ?? 0),
                                              style: const TextStyle(color: Color(0xFF0D1B2A), fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Column(
                              children: const [
                                Icon(Icons.flight_takeoff, color: Color(0xFFE8ECEF), size: 48),
                                SizedBox(height: 12),
                                Text('Belum ada perjalanan', style: TextStyle(color: Color(0xFF596273), fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text('Klik tombol di bawah untuk menambah', style: TextStyle(color: Color(0xFF596273), fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      
                      if (otherTrips.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Mendatang & Lampau', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                              GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AllTripsScreen()));
                                  if (result == true) _loadTrips();
                                },
                                child: const Text('LIHAT SEMUA →', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E8F82))),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        ...otherTrips.map((trip) {
                          final status = (trip['status'] ?? 'upcoming').toString().toUpperCase();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => VacationDetailScreen(trip: trip)));
                                if (result == true) _loadTrips();
                              },
                              child: _buildTripListItem(
                                title: trip['name'] ?? '-',
                                date: trip['start_date'] ?? '-',
                                imageUrl: trip['image_url'] ?? 'https://picsum.photos/id/1015/100/100',
                                tags: [
                                  {'text': status, 'color': const Color(0xFFE8ECEF), 'textColor': const Color(0xFF596273)},
                                  if (trip['category'] != null)
                                    {'text': (trip['category'] as String).toUpperCase(), 'color': const Color(0xFFD9F4F2), 'textColor': const Color(0xFF1E8F82)},
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                      
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AddVacationScreen()),
                              );
                              if (result == true) _loadTrips();
                            },
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text(
                              'TAMBAH PERJALANAN',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D1B2A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTripListItem({
    required String title,
    required String date,
    required String imageUrl,
    required List<Map<String, dynamic>> tags,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(color: const Color(0xFFE8ECEF), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.landscape, color: Color(0xFF596273)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0D1B2A))),
                  const SizedBox(height: 4),
                  Text(date, style: const TextStyle(fontSize: 12, color: Color(0xFF596273))),
                  const SizedBox(height: 8),
                  Row(
                    children: tags.map((tag) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: tag['color'],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag['text'],
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: tag['textColor']),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}

class HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(size.width / 4, size.height, size.width / 2, size.height - 20);
    path.quadraticBezierTo(size.width * 3 / 4, size.height - 40, size.width, size.height - 10);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

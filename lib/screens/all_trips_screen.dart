import 'package:flutter/material.dart';
import 'package:libra_go/services/supabase_service.dart';
import 'package:libra_go/screens/vacation_detail_screen.dart';

class AllTripsScreen extends StatefulWidget {
  const AllTripsScreen({super.key});

  @override
  State<AllTripsScreen> createState() => _AllTripsScreenState();
}

class _AllTripsScreenState extends State<AllTripsScreen> {
  final _supabase = SupabaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _allTrips = [];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);
    try {
      final trips = await _supabase.getTrips();
      setState(() {
        _allTrips = trips;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildTripListItem({
    required String title,
    required String date,
    required String imageUrl,
    required List<Map<String, dynamic>> tags,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D1B2A)),
                ),
                const SizedBox(height: 4),
                Text(date, style: const TextStyle(color: Color(0xFF596273), fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: tags.map((tag) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: tag['color'],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag['text'],
                        style: TextStyle(color: tag['textColor'], fontSize: 8, fontWeight: FontWeight.bold),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0D1B2A)),
          onPressed: () => Navigator.pop(context, true), // pass true to refresh previous screen
        ),
        title: const Text(
          'Semua Perjalanan',
          style: TextStyle(
            color: Color(0xFF0D1B2A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allTrips.isEmpty
              ? const Center(child: Text('Belum ada perjalanan'))
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _allTrips.length,
                  itemBuilder: (context, index) {
                    final trip = _allTrips[index];
                    final status = (trip['status'] ?? 'upcoming').toString().toUpperCase();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => VacationDetailScreen(trip: trip)),
                          );
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
                  },
                ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:libra_go/services/supabase_service.dart';
import 'package:libra_go/screens/add_itinerary_screen.dart';
import 'package:libra_go/screens/budget_screen.dart';
import 'package:libra_go/screens/trip_map_screen.dart';
import 'package:libra_go/screens/trip_documents_screen.dart';
import 'package:libra_go/screens/invite_member_screen.dart';
import 'package:libra_go/screens/split_bill_screen.dart';
import 'package:libra_go/services/pdf_service.dart';
import 'package:libra_go/screens/add_vacation_screen.dart';

class VacationDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? trip;

  const VacationDetailScreen({super.key, this.trip});

  @override
  State<VacationDetailScreen> createState() => _VacationDetailScreenState();
}

class _VacationDetailScreenState extends State<VacationDetailScreen> with SingleTickerProviderStateMixin {
  final _supabase = SupabaseService();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _itineraries = [];
  bool _isLoadingItinerary = true;

  int _belanjaTotal = 0;
  int _penginapanTotal = 0;
  int _kulinerTotal = 0;
  List<Map<String, dynamic>> _expensesList = [];
  bool _isLoadingExpenses = true;
  bool _isGeneratingPdf = false;

  RealtimeChannel? _expensesSubscription;
  RealtimeChannel? _itinerariesSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadItineraries();
    _loadExpenses();
    _setupRealtimeSync();
  }
  
  void _setupRealtimeSync() {
    if (widget.trip == null || widget.trip!['id'] == null) return;
    final tripId = widget.trip!['id'].toString();

    _expensesSubscription = _supabase.client.channel('public:expenses:$tripId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'expenses',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'trip_id',
          value: tripId,
        ),
        callback: (payload) {
          _loadExpenses();
        },
      ).subscribe();

    _itinerariesSubscription = _supabase.client.channel('public:itineraries:$tripId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'itineraries',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'trip_id',
          value: tripId,
        ),
        callback: (payload) {
          _loadItineraries();
        },
      ).subscribe();
  }

  @override
  void dispose() {
    _expensesSubscription?.unsubscribe();
    _itinerariesSubscription?.unsubscribe();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadItineraries() async {
    if (widget.trip == null || widget.trip!['id'] == null) {
      if (mounted) setState(() => _isLoadingItinerary = false);
      return;
    }
    try {
      final data = await _supabase.getItineraries(widget.trip!['id'].toString());
      if (mounted) {
        setState(() {
          _itineraries = data;
          _isLoadingItinerary = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingItinerary = false);
    }
  }

  Future<void> _loadExpenses() async {
    if (widget.trip == null || widget.trip!['id'] == null) {
      if (mounted) setState(() => _isLoadingExpenses = false);
      return;
    }
    try {
      final expenses = await _supabase.getExpenses(tripId: widget.trip!['id'].toString());
      int belanja = 0, penginapan = 0, kuliner = 0;
      for (var e in expenses) {
        // Use IDR amount for display summary
        final amt = (e['amount'] as num).toInt();
        final cat = e['category'];
        if (cat == 'shopping' || cat == 'flight' || cat == 'transport') belanja += amt; 
        else if (cat == 'accommodation') penginapan += amt;
        else if (cat == 'culinary') kuliner += amt;
      }
      if (mounted) {
        setState(() {
          _belanjaTotal = belanja;
          _penginapanTotal = penginapan;
          _kulinerTotal = kuliner;
          _expensesList = expenses;
          _isLoadingExpenses = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingExpenses = false);
    }
  }

  String _formatRupiah(int amount) {
    String result = amount.toString();
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    result = result.replaceAllMapped(regex, (Match m) => '${m[1]}.');
    return 'Rp $result';
  }

  Future<void> _deleteTrip() async {
    if (widget.trip == null || widget.trip!['id'] == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text('Are you sure you want to delete this trip?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabase.deleteTrip(widget.trip!['id'].toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip deleted')));
          Navigator.pop(context, true); 
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.trip?['name'] ?? 'Liburan';
    final location = widget.trip?['destination'] ?? 'Destinasi';
    final imageUrl = widget.trip?['image_url'] ?? 'https://picsum.photos/id/1018/600/400';
    final date = widget.trip?['start_date'] ?? 'TBD';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () {
               if (widget.trip != null) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => InviteMemberScreen(tripId: widget.trip!['id'].toString())));
               }
            },
          ),
          PopupMenuButton<String>(
            icon: _isGeneratingPdf 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
              : const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'edit') {
                if (widget.trip != null) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddVacationScreen(existingTrip: widget.trip)),
                  );
                  if (result == true && mounted) {
                    Navigator.pop(context, true); // Pop back to trigger refresh in parent
                  }
                }
              } else if (value == 'split_bill') {
                if (widget.trip != null) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SplitBillScreen(tripId: widget.trip!['id'].toString())));
                }
              } else if (value == 'share') {
                if (widget.trip != null) {
                  setState(() => _isGeneratingPdf = true);
                  try {
                    await PdfService.generateAndShareTripReport(
                      trip: widget.trip!,
                      itineraries: _itineraries,
                      expenses: _expensesList,
                    );
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuat PDF: $e')));
                  } finally {
                    if (mounted) setState(() => _isGeneratingPdf = false);
                  }
                }
              } else if (value == 'delete') {
                _deleteTrip();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit Perjalanan')),
              const PopupMenuItem(value: 'split_bill', child: Text('Split Bill')),
              const PopupMenuItem(value: 'share', child: Text('Bagikan (PDF)')),
              const PopupMenuItem(value: 'delete', child: Text('Hapus Perjalanan', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Image
          Container(
            height: 150,
            decoration: BoxDecoration(
              image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
            ),
            child: Container(
              color: Colors.black.withOpacity(0.5),
              padding: const EdgeInsets.all(20),
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date, style: const TextStyle(color: Color(0xFF52B8AC), fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(location, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1E8F82),
              unselectedLabelColor: const Color(0xFF596273),
              indicatorColor: const Color(0xFF1E8F82),
              tabs: const [
                Tab(text: 'Jadwal'),
                Tab(text: 'Anggaran'),
                Tab(text: 'Dokumen'),
                Tab(text: 'Peta'),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildItineraryTab(),
                _buildBudgetTab(),
                widget.trip != null ? TripDocumentsScreen(tripId: widget.trip!['id'].toString()) : const Center(child: Text('Simpan trip dahulu')),
                TripMapScreen(itineraries: _itineraries, destinationName: location),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
        ? FloatingActionButton(
            onPressed: () async {
              if (widget.trip == null || widget.trip!['id'] == null) return;
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddItineraryScreen(tripId: widget.trip!['id'].toString())),
              );
              if (result == true) _loadItineraries();
            },
            backgroundColor: const Color(0xFF0D1B2A),
            child: const Icon(Icons.add, color: Colors.white),
          )
        : null,
    );
  }

  Widget _buildItineraryTab() {
    if (_isLoadingItinerary) return const Center(child: CircularProgressIndicator());
    if (_itineraries.isEmpty) return const Center(child: Text('Belum ada jadwal.'));
    
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _itineraries.length,
      itemBuilder: (context, index) {
        final item = _itineraries[index];
        final dateStr = item['date'] != null ? '${DateTime.parse(item['date']).day}/${DateTime.parse(item['date']).month}' : '';
        return _buildTimelineItem(
          day: 'HARI ${item['day_number']}',
          date: dateStr,
          title: item['title'] ?? '',
          description: item['description'] ?? '',
          locationBox: item['location'],
          isLast: index == _itineraries.length - 1,
        );
      },
    );
  }

  Widget _buildBudgetTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Rincian Anggaran (IDR)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BudgetScreen(trip: widget.trip))),
                child: const Text('DETAIL >', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E8F82))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black12),
            ),
            child: _isLoadingExpenses
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      _buildBudgetRow(Icons.shopping_bag_outlined, 'Belanja & Transport', _formatRupiah(_belanjaTotal), 
                          widget.trip?['budget'] != null && widget.trip!['budget'] > 0 ? (_belanjaTotal / widget.trip!['budget']).clamp(0.0, 1.0) : 0.0),
                      const SizedBox(height: 20),
                      _buildBudgetRow(Icons.bed, 'Penginapan', _formatRupiah(_penginapanTotal), 
                          widget.trip?['budget'] != null && widget.trip!['budget'] > 0 ? (_penginapanTotal / widget.trip!['budget']).clamp(0.0, 1.0) : 0.0),
                      const SizedBox(height: 20),
                      _buildBudgetRow(Icons.restaurant, 'Makan & Hiburan', _formatRupiah(_kulinerTotal), 
                          widget.trip?['budget'] != null && widget.trip!['budget'] > 0 ? (_kulinerTotal / widget.trip!['budget']).clamp(0.0, 1.0) : 0.0),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetRow(IconData icon, String title, String amount, double progress) {
    return Column(
      children: [
        Row(
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFF0D1B2A), shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 14)),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(color: Color(0xFF596273), fontSize: 13))),
            Text(amount, style: const TextStyle(color: Color(0xFF0D1B2A), fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            Container(height: 6, decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(3))),
            FractionallySizedBox(widthFactor: progress, child: Container(height: 6, decoration: BoxDecoration(color: const Color(0xFF1E8F82), borderRadius: BorderRadius.circular(3)))),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineItem({required String day, required String date, required String title, required String description, String? locationBox, required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(width: 16, height: 16, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF1E8F82), width: 2), color: Colors.white)),
              if (!isLast) Expanded(child: Container(width: 2, color: const Color(0xFFE8ECEF))),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$day • $date', style: const TextStyle(color: Color(0xFF1E8F82), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(title, style: const TextStyle(color: Color(0xFF0D1B2A), fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(description, style: const TextStyle(color: Color(0xFF596273), fontSize: 13, height: 1.4)),
                  if (locationBox != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(color: const Color(0xFFF0F4F8), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: Color(0xFF1E8F82), size: 16),
                          const SizedBox(width: 8),
                          Text(locationBox, style: const TextStyle(color: Color(0xFF0D1B2A), fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

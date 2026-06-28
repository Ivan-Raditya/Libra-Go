import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:libra_go/services/supabase_service.dart';

class InviteMemberScreen extends StatefulWidget {
  final String tripId;
  const InviteMemberScreen({super.key, required this.tripId});

  @override
  State<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends State<InviteMemberScreen> {
  final _supabase = SupabaseService();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  Timer? _debounce;
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _setupRealtimeSync();
    _searchController.addListener(_onSearchChanged);
  }

  void _setupRealtimeSync() {
    _subscription = _supabase.client.channel('public:trip_members:${widget.tripId}')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'trip_members',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'trip_id',
          value: widget.tripId,
        ),
        callback: (payload) {
          _loadMembers();
        },
      ).subscribe();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await _supabase.getTripMembers(widget.tripId);
      if (mounted) {
        setState(() {
          _members = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        _searchUsers(query);
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  Future<void> _searchUsers(String query) async {
    setState(() => _isSearching = true);
    try {
      final results = await _supabase.searchUsers(query);
      
      // Filter out users who are already members
      final existingIds = _members.map((m) => m['user_id'].toString()).toSet();
      final filtered = results.where((user) => !existingIds.contains(user['id'].toString())).toList();
      
      if (mounted) {
        setState(() {
          _searchResults = filtered;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _inviteMember(Map<String, dynamic> user) async {
    try {
      await _supabase.addTripMemberById(widget.tripId, user['id'].toString());
      _showSnackBar('Berhasil mengundang ${user['full_name']}');
      
      // Remove from search results instantly for better UX
      setState(() {
        _searchResults.removeWhere((u) => u['id'] == user['id']);
      });
      // The realtime subscription will refresh the actual members list
    } catch (e) {
      _showSnackBar(e.toString());
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmRemoveMember(Map<String, dynamic> member) async {
    final profile = member['profiles'];
    final name = profile != null ? profile['full_name'] : 'Anggota ini';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluarkan Anggota'),
        content: Text('Apakah Anda yakin ingin mengeluarkan $name dari perjalanan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Keluarkan', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabase.removeTripMember(widget.tripId, member['user_id'].toString());
        _showSnackBar('$name berhasil dikeluarkan.');
        // Sinkronisasi realtime akan memperbarui daftar otomatis
      } catch (e) {
        _showSnackBar('Gagal mengeluarkan anggota: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text('Anggota Trip', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cari Teman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D1B2A))),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Ketik nama teman...',
                    prefixIcon: const Icon(Icons.search, color: Colors.black26),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                
                if (_isSearching || _searchResults.isNotEmpty || _searchController.text.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Hasil Pencarian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF596273))),
                  const SizedBox(height: 8),
                  
                  if (_isSearching)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_searchResults.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: Text('Tidak ada pengguna ditemukan.', style: TextStyle(color: Color(0xFF596273)))),
                    )
                  else
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(user['avatar_url'] ?? 'https://i.pravatar.cc/150?img=11'),
                            ),
                            title: Text(user['full_name'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            trailing: ElevatedButton(
                              onPressed: () => _inviteMember(user),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E8F82),
                                minimumSize: const Size(60, 30),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Tambah', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          );
                        },
                      ),
                    ),
                ],
                
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Daftar Anggota', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D1B2A))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8ECEF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_members.length} Orang',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF596273)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      final profile = member['profiles'];
                      final name = profile != null ? profile['full_name'] : 'Unknown User';
                      final avatarUrl = profile != null ? profile['avatar_url'] : null;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(avatarUrl ?? 'https://i.pravatar.cc/150?img=11'),
                          ),
                          title: Text(name ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(member['role'] == 'admin' ? 'Admin' : 'Member', style: const TextStyle(fontSize: 12, color: Color(0xFF596273))),
                          trailing: member['role'] != 'admin' 
                            ? IconButton(
                                icon: const Icon(Icons.person_remove, color: Colors.redAccent, size: 20),
                                onPressed: () => _confirmRemoveMember(member),
                              )
                            : null,
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
}

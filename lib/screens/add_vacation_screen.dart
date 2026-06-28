import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:libra_go/services/supabase_service.dart';

class AddVacationScreen extends StatefulWidget {
  final Map<String, dynamic>? existingTrip;
  const AddVacationScreen({super.key, this.existingTrip});

  @override
  State<AddVacationScreen> createState() => _AddVacationScreenState();
}

class _AddVacationScreenState extends State<AddVacationScreen> {
  final _supabase = SupabaseService();
  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _budgetController = TextEditingController();
  String _selectedCategory = 'leisure';
  DateTime? _selectedDate;
  bool _isLoading = false;
  
  String? _tripImageUrl;
  final _picker = ImagePicker();
  List<Map<String, dynamic>> _invitedUsers = [];
  List<Map<String, dynamic>> _originalMembers = [];

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
  bool _isFetchingRates = false;
  double _convertedAmount = 0.0;
  final List<String> _currencies = ['IDR', 'USD', 'SGD', 'JPY', 'EUR', 'MYR', 'AUD'];

  @override
  void initState() {
    super.initState();
    _fetchExchangeRates();
    _budgetController.addListener(_updateConvertedAmount);

    if (widget.existingTrip != null) {
      final trip = widget.existingTrip!;
      _nameController.text = trip['name'] ?? '';
      _destinationController.text = trip['destination'] ?? '';
      _budgetController.text = (trip['budget'] ?? '').toString();
      _selectedCategory = trip['category'] ?? 'leisure';
      _tripImageUrl = trip['image_url'];
      if (trip['start_date'] != null) {
        _selectedDate = DateTime.tryParse(trip['start_date']);
      }
      _fetchExistingMembers();
    }
  }

  Future<void> _fetchExistingMembers() async {
    try {
      final members = await _supabase.getTripMembers(widget.existingTrip!['id'].toString());
      if (mounted) {
        setState(() {
          _invitedUsers = members.map((m) {
            final profile = m['profiles'];
            return {
              'id': m['user_id'],
              'full_name': profile?['full_name'],
              'avatar_url': profile?['avatar_url'],
              'role': m['role'],
            };
          }).toList();
          _originalMembers = List.from(_invitedUsers);
        });
      }
    } catch (e) {
      // Ignore error, just start with empty list
    }
  }

  Future<void> _fetchExchangeRates() async {
    setState(() => _isFetchingRates = true);
    try {
      final response = await http.get(Uri.parse('https://open.er-api.com/v6/latest/IDR'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _exchangeRates = data['rates'] ?? {'IDR': 1.0};
          });
          _updateConvertedAmount();
        }
      }
    } catch (e) {
      // Ignore
    } finally {
      if (mounted) setState(() => _isFetchingRates = false);
    }
  }

  void _updateConvertedAmount() {
    final amountText = _budgetController.text.trim().replaceAll('.', '').replaceAll(',', '');
    final amount = double.tryParse(amountText) ?? 0.0;
    
    if (_selectedCurrency == 'IDR') {
      setState(() => _convertedAmount = amount);
    } else {
      final rate = _exchangeRates[_selectedCurrency];
      if (rate != null && rate > 0) {
        setState(() => _convertedAmount = amount * rate);
      }
    }
  }

  String _formatForeignCurrency(double amount) {
    String amountStr = amount.toStringAsFixed(2);
    final parts = amountStr.split('.');
    String intPart = parts[0];
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    intPart = intPart.replaceAllMapped(regex, (Match m) => '${m[1]},');
    String decPart = parts[1] == '00' ? '' : '.${parts[1]}';
    return '$intPart$decPart';
  }

  @override
  void dispose() {
    _budgetController.removeListener(_updateConvertedAmount);
    _nameController.dispose();
    _destinationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _pickTripImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tambahkan Foto Perjalanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF1E8F82)),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.link, color: Color(0xFF1E8F82)),
                title: const Text('Gunakan URL Gambar'),
                onTap: () {
                  Navigator.pop(context);
                  _changeViaUrl();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
      if (image == null) return;

      setState(() => _isLoading = true);

      final url = await _supabase.uploadTripImage(File(image.path));
      if (url != null) {
        setState(() => _tripImageUrl = url);
        _showSnackBar('Foto berhasil ditambahkan');
      }
    } catch (e) {
      _showSnackBar('Gagal mengupload foto. Pastikan bucket "trips" sudah dibuat dan public. Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changeViaUrl() {
    final urlController = TextEditingController(text: _tripImageUrl ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('URL Foto Perjalanan'),
          content: TextField(
            controller: urlController,
            decoration: const InputDecoration(hintText: 'https://...'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                final url = urlController.text.trim();
                if (url.isNotEmpty) {
                  setState(() => _tripImageUrl = url);
                  _showSnackBar('URL foto berhasil ditambahkan');
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D1B2A)),
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }


  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final destination = _destinationController.text.trim();
    final budgetText = _budgetController.text.trim().replaceAll('.', '').replaceAll(',', '');

    if (name.isEmpty) {
      _showSnackBar('Mohon isi nama perjalanan');
      return;
    }

    final startNow = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mulai Perjalanan?'),
        content: const Text('Apakah Anda ingin memulai perjalanan ini sekarang? Saldo dan pengeluaran di halaman Beranda akan menyesuaikan dengan perjalanan ini.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Nanti')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya, Mulai', style: TextStyle(color: Color(0xFF1E8F82), fontWeight: FontWeight.bold))),
        ],
      ),
    );

    setState(() => _isLoading = true);

    try {
      final data = <String, dynamic>{
        'name': name,
        'destination': destination.isEmpty ? null : destination,
        'category': _selectedCategory,
        'status': startNow == true ? 'active' : 'upcoming',
        if (_tripImageUrl != null) 'image_url': _tripImageUrl,
      };

      if (budgetText.isNotEmpty) {
        data['budget'] = int.tryParse(budgetText) ?? 0;
      }
      if (_selectedDate != null) {
        data['start_date'] = _selectedDate!.toIso8601String().split('T')[0];
      }

      if (startNow == true) {
        await _supabase.deactivateAllTrips();
      }

      if (widget.existingTrip != null) {
        // Edit mode
        final tripId = widget.existingTrip!['id'].toString();
        await _supabase.updateTrip(tripId, data);
        
        // Sync members
        final originalIds = _originalMembers.map((m) => m['id'].toString()).toSet();
        final currentIds = _invitedUsers.map((m) => m['id'].toString()).toSet();
        
        final addedUsers = _invitedUsers.where((m) => !originalIds.contains(m['id'].toString()));
        final removedUserIds = originalIds.difference(currentIds);

        for (var u in addedUsers) {
          try {
            await _supabase.addTripMemberById(tripId, u['id'].toString());
          } catch (e) {}
        }
        for (var id in removedUserIds) {
          try {
            await _supabase.removeTripMember(tripId, id);
          } catch (e) {}
        }

        if (mounted) {
          _showSnackBar('Perjalanan berhasil diperbarui!');
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) Navigator.pop(context, true);
          });
        }
      } else {
        // Create mode
        final insertedTrip = await _supabase.addTrip(data);
        final newTripId = insertedTrip['id'].toString();

        // Invite members if any
        for (final user in _invitedUsers) {
          try {
            await _supabase.addTripMemberById(newTripId, user['id'].toString());
          } catch (e) {
            // just ignore or we could show partial failure
          }
        }

        if (mounted) {
          _showSnackBar('Perjalanan berhasil disimpan!');
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) Navigator.pop(context, true);
          });
        }
      }
    } catch (e) {
      _showSnackBar('Gagal menyimpan: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF0D1B2A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existingTrip != null ? 'Edit Perjalanan' : 'Tambah Perjalanan',
          style: const TextStyle(
            color: Color(0xFF0D1B2A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF0D1B2A)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // Header Banner
              GestureDetector(
                onTap: _pickTripImage,
                child: Container(
                  width: double.infinity,
                  height: 140,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _tripImageUrl == null ? const Color(0xFF0D1B2A) : null,
                    image: _tripImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_tripImageUrl!),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.4),
                              BlendMode.darken,
                            ),
                          )
                        : null,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_tripImageUrl == null) ...[
                        const Icon(Icons.add_a_photo_outlined, color: Colors.white54, size: 32),
                        const SizedBox(height: 12),
                        const Text(
                          'TAMBAHKAN FOTO DESTINASI',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Mulai Petualangan Baru',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: const [
                            Icon(Icons.edit, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Ubah Foto',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Trip Name
              const Text(
                'NAMA PERJALANAN',
                style: TextStyle(
                  color: Color(0xFF0D1B2A),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g., Liburan Musim Dingin',
                  hintStyle: const TextStyle(color: Colors.black26),
                  suffixIcon: const Icon(Icons.edit_outlined, color: Colors.black26, size: 20),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black12),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF0D1B2A)),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Destination
              const Text(
                'DESTINASI',
                style: TextStyle(
                  color: Color(0xFF0D1B2A),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              TextField(
                controller: _destinationController,
                decoration: InputDecoration(
                  hintText: 'Cari Kota atau Negara',
                  hintStyle: const TextStyle(color: Colors.black26),
                  prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.black26, size: 20),
                  prefixIconConstraints: const BoxConstraints(minWidth: 30),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black12),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF0D1B2A)),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Date and Budget Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TANGGAL',
                          style: TextStyle(
                            color: Color(0xFF0D1B2A),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        TextField(
                          readOnly: true,
                          onTap: _pickDate,
                          decoration: InputDecoration(
                            hintText: _selectedDate != null
                                ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                : 'Pilih Tanggal',
                            hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
                            prefixIcon: const Icon(Icons.calendar_today, color: Colors.black26, size: 16),
                            prefixIconConstraints: const BoxConstraints(minWidth: 24),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black12),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF0D1B2A)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ANGGARAN (IDR)',
                              style: TextStyle(
                                color: Color(0xFF0D1B2A),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCurrency,
                                isDense: true,
                                icon: const Icon(Icons.arrow_drop_down, size: 16),
                                style: const TextStyle(fontSize: 10, color: Color(0xFF1E8F82), fontWeight: FontWeight.bold),
                                items: _currencies.map((curr) {
                                  return DropdownMenuItem(value: curr, child: Text(curr));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedCurrency = val);
                                    _updateConvertedAmount();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        TextField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
                            prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.black26, size: 16),
                            prefixIconConstraints: const BoxConstraints(minWidth: 24),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black12),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF0D1B2A)),
                            ),
                          ),
                        ),
                        if (_selectedCurrency != 'IDR')
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _isFetchingRates ? 'Menghitung kurs...' : '≈ $_selectedCurrency ${_formatForeignCurrency(_convertedAmount)}',
                              style: const TextStyle(color: Color(0xFF1E8F82), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Category
              const Text(
                'KATEGORI',
                style: TextStyle(
                  color: Color(0xFF0D1B2A),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _selectedCategory = 'leisure'),
                      child: _buildCategoryChip(Icons.beach_access, 'Leisure', _selectedCategory == 'leisure'),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => setState(() => _selectedCategory = 'business'),
                      child: _buildCategoryChip(Icons.work_outline, 'Business', _selectedCategory == 'business'),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => setState(() => _selectedCategory = 'adventure'),
                      child: _buildCategoryChip(Icons.landscape, 'Adventure', _selectedCategory == 'adventure'),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Travel Companions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TEMAN PERJALANAN',
                    style: TextStyle(
                      color: Color(0xFF0D1B2A),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8ECEF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_invitedUsers.length} Ditambahkan',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF596273)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_invitedUsers.isNotEmpty)
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: Stack(
                          children: [
                            for (int i = 0; i < _invitedUsers.length; i++)
                              Positioned(
                                left: i * 32.0,
                                child: GestureDetector(
                                  onTap: () {
                                    final u = _invitedUsers[i];
                                    if (u['role'] == 'admin') {
                                      _showSnackBar('Tidak dapat menghapus pembuat perjalanan');
                                      return;
                                    }
                                    showDialog(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        title: const Text('Hapus Teman?'),
                                        content: Text('Hapus ${u['full_name'] ?? 'pengguna ini'} dari daftar?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')),
                                          TextButton(
                                            onPressed: () {
                                              setState(() => _invitedUsers.removeAt(i));
                                              Navigator.pop(c);
                                            },
                                            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: const [
                                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundImage: NetworkImage(_invitedUsers[i]['avatar_url'] ?? 'https://i.pravatar.cc/150?img=11'),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: () => _showInviteModal(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF1E8F82), width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.add, color: Color(0xFF1E8F82), size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleSave,
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_outlined, color: Colors.white, size: 20),
                  label: _isLoading
                      ? const SizedBox.shrink()
                      : const Text(
                    'Simpan Perjalanan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D1B2A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              const Center(
                child: Text(
                  'Semua detail dapat diubah nanti di pengaturan perjalanan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF596273),
                    fontSize: 12,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(IconData icon, String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF0D1B2A) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: isActive ? null : Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Icon(icon, color: isActive ? Colors.white : const Color(0xFF0D1B2A), size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : const Color(0xFF0D1B2A),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showInviteModal(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _InviteUserModal(
          onUserSelected: (user) {
            if (!_invitedUsers.any((u) => u['id'] == user['id'])) {
              setState(() => _invitedUsers.add(user));
            }
          },
        );
      },
    );
  }
}

class _InviteUserModal extends StatefulWidget {
  final Function(Map<String, dynamic>) onUserSelected;

  const _InviteUserModal({required this.onUserSelected});

  @override
  State<_InviteUserModal> createState() => _InviteUserModalState();
}

class _InviteUserModalState extends State<_InviteUserModal> {
  final _searchController = TextEditingController();
  final _supabase = SupabaseService();
  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
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
      if (mounted) {
        setState(() {
          _searchResults = results;
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cari Teman', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Ketik nama teman...',
              prefixIcon: const Icon(Icons.search, color: Colors.black26),
              filled: true,
              fillColor: const Color(0xFFF7F9FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty && _searchController.text.isNotEmpty
                    ? const Center(child: Text('Tidak ada pengguna ditemukan.'))
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(user['avatar_url'] ?? 'https://i.pravatar.cc/150?img=11'),
                            ),
                            title: Text(user['full_name'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: ElevatedButton(
                              onPressed: () {
                                widget.onUserSelected(user);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E8F82),
                                minimumSize: const Size(60, 30),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Pilih', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

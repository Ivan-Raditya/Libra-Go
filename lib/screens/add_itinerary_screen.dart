import 'package:flutter/material.dart';
import 'package:libra_go/services/supabase_service.dart';

class AddItineraryScreen extends StatefulWidget {
  final String tripId;
  final Map<String, dynamic>? existingItinerary;

  const AddItineraryScreen({super.key, required this.tripId, this.existingItinerary});

  @override
  State<AddItineraryScreen> createState() => _AddItineraryScreenState();
}

class _AddItineraryScreenState extends State<AddItineraryScreen> {
  final _supabase = SupabaseService();
  final _dayController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingItinerary != null) {
      final item = widget.existingItinerary!;
      _dayController.text = item['day_number']?.toString() ?? '';
      _titleController.text = item['title'] ?? '';
      _descriptionController.text = item['description'] ?? '';
      _locationController.text = item['location'] ?? '';
      if (item['date'] != null) {
        _selectedDate = DateTime.tryParse(item['date']);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _handleSave() async {
    final dayStr = _dayController.text.trim();
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();

    if (dayStr.isEmpty || title.isEmpty) {
      _showSnackBar('Mohon isi Hari Ke- dan Judul Kegiatan');
      return;
    }

    final dayNumber = int.tryParse(dayStr);
    if (dayNumber == null) {
      _showSnackBar('Hari Ke- harus berupa angka');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = <String, dynamic>{
        'trip_id': widget.tripId,
        'day_number': dayNumber,
        'title': title,
        'description': description.isNotEmpty ? description : null,
        'location': location.isNotEmpty ? location : null,
        'date': _selectedDate != null ? _selectedDate!.toIso8601String().split('T')[0] : null,
      };

      if (widget.existingItinerary != null) {
        await _supabase.updateItinerary(widget.existingItinerary!['id'].toString(), data);
      } else {
        await _supabase.addItinerary(data);
      }

      if (mounted) {
        _showSnackBar(widget.existingItinerary != null ? 'Jadwal berhasil diperbarui!' : 'Jadwal berhasil ditambahkan!');
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context, true);
        });
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existingItinerary != null ? 'Edit Jadwal Harian' : 'Tambah Jadwal Harian',
          style: const TextStyle(color: Color(0xFF0D1B2A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('HARI KE-', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF596273))),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _dayController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Misal: 1',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TANGGAL (OPSIONAL)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF596273))),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          height: 55,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDate != null ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}' : 'Pilih Tanggal',
                                style: TextStyle(color: _selectedDate != null ? const Color(0xFF0D1B2A) : Colors.black38),
                              ),
                              const Icon(Icons.calendar_today, color: Colors.black38, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('JUDUL KEGIATAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF596273))),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Misal: Kedatangan & Check-in',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            const Text('LOKASI (OPSIONAL)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF596273))),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Misal: Bandara Ngurah Rai',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.location_on, color: Color(0xFF1E8F82)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            const Text('DESKRIPSI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF596273))),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Ceritakan detail kegiatan...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D1B2A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Simpan Jadwal', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

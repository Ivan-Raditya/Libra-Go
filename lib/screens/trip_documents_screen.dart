import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:libra_go/services/supabase_service.dart';

class TripDocumentsScreen extends StatefulWidget {
  final String tripId;
  const TripDocumentsScreen({super.key, required this.tripId});

  @override
  State<TripDocumentsScreen> createState() => _TripDocumentsScreenState();
}

class _TripDocumentsScreenState extends State<TripDocumentsScreen> {
  final _supabase = SupabaseService();
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      final data = await _supabase.getDocuments(widget.tripId);
      if (mounted) {
        setState(() {
          _documents = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _isUploading = true);
      try {
        final file = File(result.files.single.path!);
        final extension = result.files.single.extension ?? 'unknown';
        await _supabase.uploadDocument(file, widget.tripId, extension, result.files.single.name);
        _showSnackBar('Dokumen berhasil diunggah');
        _loadDocuments();
      } catch (e) {
        _showSnackBar('Gagal mengunggah dokumen: $e');
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading 
      ? const Center(child: CircularProgressIndicator())
      : Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickAndUploadFile,
                icon: _isUploading 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.upload_file, color: Colors.white),
                label: const Text('Unggah Dokumen (PDF/Gambar)', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E8F82),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
            Expanded(
              child: _documents.isEmpty
                ? const Center(child: Text('Belum ada dokumen.'))
                : ListView.builder(
                    itemCount: _documents.length,
                    itemBuilder: (context, index) {
                      final doc = _documents[index];
                      final isPdf = doc['file_type'] == 'pdf';
                      return ListTile(
                        leading: Icon(
                          isPdf ? Icons.picture_as_pdf : Icons.image,
                          color: isPdf ? Colors.red : Colors.blue,
                        ),
                        title: Text(doc['file_name'] ?? 'Document'),
                        subtitle: Text(doc['created_at'] != null ? doc['created_at'].toString().split('T')[0] : ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () {
                            // Here you'd use url_launcher to open the file_url
                            _showSnackBar('Fitur unduh: ${doc['file_url']}');
                          },
                        ),
                      );
                    },
                  ),
            ),
          ],
        );
  }
}

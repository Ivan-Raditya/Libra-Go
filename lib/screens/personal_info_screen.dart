import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:libra_go/services/supabase_service.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _supabase = SupabaseService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  String _selectedGender = '-';
  String _avatarUrl = 'https://i.pravatar.cc/300?img=5';
  
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _supabase.getProfile();
      final user = _supabase.currentUser;
      
      if (mounted) {
        setState(() {
          _profile = profile;
          _nameController.text = _profile?['full_name'] ?? user?.userMetadata?['full_name'] ?? '';
          _phoneController.text = _profile?['phone'] ?? '';
          _selectedGender = _profile?['gender'] ?? '-';
          _avatarUrl = _profile?['avatar_url'] ?? 'https://i.pravatar.cc/300?img=5';
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
      _showSnackBar('Gagal logout: $e');
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

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('Nama lengkap tidak boleh kosong');
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      await _supabase.updateProfile({
        'full_name': name,
        'phone': _phoneController.text.trim(),
        'gender': _selectedGender,
        'avatar_url': _avatarUrl,
      });
      _showSnackBar('Profil berhasil diperbarui!');
    } catch (e) {
      _showSnackBar('Gagal memperbarui profil: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changeAvatar() async {
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
              const Text('Ubah Foto Profil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
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

      setState(() => _isSaving = true);

      final url = await _supabase.uploadAvatar(File(image.path));
      if (url != null) {
        setState(() => _avatarUrl = url);
        await _supabase.updateProfile({'avatar_url': url});
        _showSnackBar('Foto profil berhasil diupload');
      }
    } catch (e) {
      _showSnackBar('Gagal mengupload foto. Pastikan bucket "avatars" sudah dibuat dan public di Supabase. Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _changeViaUrl() {
    final urlController = TextEditingController(text: _avatarUrl);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('URL Foto Profil'),
          content: TextField(
            controller: urlController,
            decoration: const InputDecoration(hintText: 'https://...'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final url = urlController.text.trim();
                if (url.isNotEmpty) {
                  Navigator.pop(context);
                  setState(() {
                    _avatarUrl = url;
                    _isSaving = true;
                  });
                  try {
                    await _supabase.updateProfile({'avatar_url': url});
                    _showSnackBar('URL foto profil berhasil diperbarui');
                  } catch (e) {
                    _showSnackBar('Gagal memperbarui URL: $e');
                  } finally {
                    if (mounted) setState(() => _isSaving = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D1B2A)),
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.currentUser;
    final email = user?.email ?? '-';
    final currency = _profile?['currency'] ?? 'IDR';
    final language = _profile?['language'] ?? 'id';
    final isVerified = _profile?['is_verified'] ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0D1B2A)),
          onPressed: () => Navigator.pop(context, true), // Return true to refresh parent
        ),
        title: const Text(
          'Informasi Pribadi',
          style: TextStyle(
            color: Color(0xFF0D1B2A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.only(right: 16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),

                  // Profile Header
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 250,
                        height: 120,
                        decoration: const BoxDecoration(
                          gradient: RadialGradient(
                            colors: [Color(0xFFE0F7FA), Colors.transparent],
                            radius: 0.6,
                          ),
                        ),
                      ),
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                              image: DecorationImage(
                                image: NetworkImage(_avatarUrl),
                                fit: BoxFit.cover,
                                onError: (_, __) => const Icon(Icons.person),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _changeAvatar,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Color(0xFF0D1B2A), shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sections
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PERSONAL DETAILS', style: TextStyle(color: Color(0xFF596273), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField('FULL NAME', _nameController),
                              const SizedBox(height: 16),
                              const Divider(height: 1, color: Colors.black12),
                              const SizedBox(height: 16),
                              
                              const Text('EMAIL', style: TextStyle(fontSize: 10, color: Color(0xFF596273))),
                              const SizedBox(height: 4),
                              Text(email, style: const TextStyle(fontSize: 14, color: Color(0xFF0D1B2A))),
                              const SizedBox(height: 16),
                              const Divider(height: 1, color: Colors.black12),
                              const SizedBox(height: 16),

                              _buildTextField('PHONE NUMBER', _phoneController, keyboardType: TextInputType.phone),
                              const SizedBox(height: 16),
                              const Divider(height: 1, color: Colors.black12),
                              const SizedBox(height: 16),

                              const Text('GENDER', style: TextStyle(fontSize: 10, color: Color(0xFF596273))),
                              const SizedBox(height: 4),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedGender,
                                  isExpanded: true,
                                  isDense: true,
                                  items: ['-', 'Laki-laki', 'Perempuan'].map((String value) {
                                    return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF0D1B2A))));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedGender = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D1B2A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                            child: const Text('Simpan Profil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 32),

                        const Text('SECURITY & IDENTITY', style: TextStyle(color: Color(0xFF596273), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('IDENTITY VERIFICATION', style: TextStyle(fontSize: 10, color: Color(0xFF596273))),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                isVerified ? 'Verified' : 'Not Verified',
                                                style: TextStyle(fontSize: 14, color: isVerified ? const Color(0xFF1E8F82) : Colors.orange, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(isVerified ? Icons.check_circle_outline : Icons.warning_amber_rounded, color: isVerified ? const Color(0xFF1E8F82) : Colors.orange, size: 16),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),

                        // Logout Button
                        Center(
                          child: TextButton.icon(
                            onPressed: _handleLogout,
                            icon: const Icon(Icons.logout, color: Color(0xFFD32F2F), size: 20),
                            label: const Text('Keluar dari Akun', style: TextStyle(color: Color(0xFFD32F2F), fontSize: 14, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF596273))),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: Color(0xFF0D1B2A), fontWeight: FontWeight.w500),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
            border: InputBorder.none,
          ),
        ),
      ],
    );
  }
}

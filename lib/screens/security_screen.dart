import 'package:flutter/material.dart';
import 'package:libra_go/services/supabase_service.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _supabase = SupabaseService();
  bool _isLoading = false;

  void _showChangePasswordDialog() {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Kata Sandi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Kata Sandi Baru',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Konfirmasi Kata Sandi Baru',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D1B2A)),
            onPressed: () async {
              if (passwordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kata sandi tidak cocok')),
                );
                return;
              }
              if (passwordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kata sandi minimal 6 karakter')),
                );
                return;
              }

              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await _supabase.updatePassword(passwordController.text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kata sandi berhasil diubah!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal mengubah sandi: $e')),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Keamanan',
          style: TextStyle(
            color: Color(0xFF0D1B2A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                
                // Password section
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'KATA SANDI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Color(0xFF596273),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8ECEF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_outline, color: Color(0xFF0D1B2A), size: 20),
                      ),
                      title: const Text(
                        'Ubah Kata Sandi',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF0D1B2A),
                        ),
                      ),
                      subtitle: const Text(
                        'Ketuk untuk mengganti kata sandi',
                        style: TextStyle(fontSize: 12, color: Color(0xFF596273)),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Color(0xFF596273)),
                      onTap: _showChangePasswordDialog,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

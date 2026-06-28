import 'package:flutter/material.dart';
import 'package:libra_go/widgets/curved_background.dart';
import 'package:libra_go/services/supabase_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabase = SupabaseService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar('Mohon isi semua kolom');
      return;
    }
    if (password.length < 6) {
      _showSnackBar('Kata sandi minimal 6 karakter');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _supabase.signUp(
        email: email,
        password: password,
        fullName: name,
      );

      if (mounted) {
        if (response.user != null) {
          _showSnackBar('Registrasi berhasil! Silakan cek email untuk konfirmasi.');
          // Auto-navigate to login after short delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context);
          });
        }
      }
    } catch (e) {
      String message = 'Registrasi gagal';
      if (e.toString().contains('already registered')) {
        message = 'Email sudah terdaftar';
      } else if (e.toString().contains('valid email')) {
        message = 'Format email tidak valid';
      } else if (e.toString().contains('at least')) {
        message = 'Kata sandi terlalu pendek';
      }
      _showSnackBar(message);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Stack(
        children: [
          const CurvedTopBackground(height: 160),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomCurvedBackground(height: 120),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(Icons.arrow_back, color: Color(0xFF0D1B2A)),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Daftar',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D1B2A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Mulai petualangan baru dan atur\nanggaran perjalanan Anda dengan\npresisi.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF596273),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildTextField(label: 'NAMA LENGKAP', hint: 'Contoh: Budi Santoso', controller: _nameController),
                  const SizedBox(height: 24),
                  _buildTextField(label: 'EMAIL', hint: 'nama@email.com', controller: _emailController, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 24),
                  const Text(
                    'KATA SANDI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Color(0xFF596273),
                    ),
                  ),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: const TextStyle(color: Colors.black26, letterSpacing: 4),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black12),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF0D1B2A)),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.black38,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 32),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF596273),
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(text: 'Dengan mendaftar, Anda menyetujui '),
                        TextSpan(
                          text: 'Syarat &\nKetentuan',
                          style: TextStyle(
                            color: Color(0xFF0D1B2A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: ' serta '),
                        TextSpan(
                          text: 'Kebijakan Privasi',
                          style: TextStyle(
                            color: Color(0xFF0D1B2A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: ' kami.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D1B2A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Daftar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sudah punya akun? ',
                        style: TextStyle(color: Color(0xFF596273), fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Masuk Sekarang',
                          style: TextStyle(
                            color: Color(0xFF0D1B2A),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Color(0xFF596273),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black26),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black12),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF0D1B2A)),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
}

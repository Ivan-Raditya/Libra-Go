import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

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
          'Pusat Bantuan',
          style: TextStyle(
            color: Color(0xFF0D1B2A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, color: Color(0xFF596273)),
                    hintText: 'Cari topik bantuan...',
                    hintStyle: TextStyle(color: Color(0xFF596273), fontSize: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Pertanyaan Populer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B2A),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // FAQ Items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  _buildFaqItem(
                    'Bagaimana cara menambah pengeluaran baru?',
                    'Anda dapat menambah pengeluaran baru dengan menekan tombol "+" pada halaman Budget atau melalui Detail Kategori.',
                  ),
                  const SizedBox(height: 12),
                  _buildFaqItem(
                    'Bagaimana cara menghubungkan E-Wallet?',
                    'Buka menu Profil > Metode Pembayaran, lalu pilih Tambah Metode Baru dan pilih E-Wallet. Masukkan detail akun Anda.',
                  ),
                  const SizedBox(height: 12),
                  _buildFaqItem(
                    'Apakah data saya aman?',
                    'Ya, data Anda disimpan dengan enkripsi end-to-end menggunakan teknologi dari Supabase.',
                  ),
                  const SizedBox(height: 12),
                  _buildFaqItem(
                    'Bagaimana cara reset password?',
                    'Gunakan fitur "Lupa Kata Sandi" pada halaman Login. Kami akan mengirimkan email untuk mereset kata sandi Anda.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Contact Us
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Butuh bantuan lebih lanjut?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B2A),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B2A),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.headset_mic, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Hubungi Kami',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'cs@librago.com',
                            style: TextStyle(
                              color: Color(0xFF596273),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0D1B2A),
          ),
        ),
        iconColor: const Color(0xFF1E8F82),
        collapsedIconColor: const Color(0xFF596273),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF596273),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

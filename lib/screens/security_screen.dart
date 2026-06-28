import 'package:flutter/material.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _useBiometric = true;
  bool _useTwoFactor = false;

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
      body: SingleChildScrollView(
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
                    'Terakhir diubah 3 bulan yang lalu',
                    style: TextStyle(fontSize: 12, color: Color(0xFF596273)),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF596273)),
                  onTap: () {
                    // Logic for changing password
                  },
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Authentication options
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'AUTENTIKASI & KEAMANAN',
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
                child: Column(
                  children: [
                    _buildSwitchItem(
                      icon: Icons.fingerprint,
                      title: 'Login Biometrik',
                      subtitle: 'Gunakan sidik jari atau Face ID',
                      value: _useBiometric,
                      onChanged: (val) => setState(() => _useBiometric = val),
                    ),
                    const Divider(height: 1, color: Colors.black12, indent: 64),
                    _buildSwitchItem(
                      icon: Icons.security,
                      title: 'Autentikasi Dua Faktor (2FA)',
                      subtitle: 'Tambahkan lapisan keamanan ekstra',
                      value: _useTwoFactor,
                      onChanged: (val) => setState(() => _useTwoFactor = val),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Devices section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'PERANGKAT TERHUBUNG',
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  children: [
                    _buildDeviceItem(
                      icon: Icons.smartphone,
                      name: 'iPhone 13 Pro',
                      location: 'Jakarta, Indonesia',
                      status: 'Perangkat Ini',
                      isActive: true,
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Colors.black12),
                    const SizedBox(height: 16),
                    _buildDeviceItem(
                      icon: Icons.laptop_mac,
                      name: 'MacBook Air M1',
                      location: 'Bandung, Indonesia',
                      status: 'Aktif 2 hari yang lalu',
                      isActive: false,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFE8ECEF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF0D1B2A), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF596273),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF1E8F82),
            activeTrackColor: const Color(0xFFD9F4F2),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceItem({
    required IconData icon,
    required String name,
    required String location,
    required String status,
    required bool isActive,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFD9F4F2) : const Color(0xFFE8ECEF),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isActive ? const Color(0xFF1E8F82) : const Color(0xFF596273),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF0D1B2A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$location • $status',
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? const Color(0xFF1E8F82) : const Color(0xFF596273),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        if (!isActive)
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFD32F2F), size: 20),
            onPressed: () {},
            tooltip: 'Log out dari perangkat ini',
          ),
      ],
    );
  }
}

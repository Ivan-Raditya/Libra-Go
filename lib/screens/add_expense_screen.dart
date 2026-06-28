import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:libra_go/services/supabase_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final Map<String, dynamic>? expense;
  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _supabase = SupabaseService();
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String _selectedCategory = 'culinary';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  
  String _selectedCurrency = 'IDR';
  Map<String, dynamic> _exchangeRates = {'IDR': 1.0};
  bool _isFetchingRates = false;
  double _convertedIdr = 0.0;
  
  File? _receiptFile;
  String? _existingReceiptUrl;
  
  final List<String> _currencies = ['IDR', 'USD', 'SGD', 'JPY', 'EUR', 'MYR', 'AUD'];

  final Map<String, Map<String, dynamic>> _categories = {
    'culinary': {'icon': Icons.restaurant, 'label': 'Kuliner'},
    'transport': {'icon': Icons.directions_car, 'label': 'Transport'},
    'accommodation': {'icon': Icons.bed, 'label': 'Hotel'},
    'shopping': {'icon': Icons.shopping_bag_outlined, 'label': 'Belanja'},
  };

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      final exp = widget.expense!;
      _amountController.text = exp['amount'].toString();
      _nameController.text = exp['name'] ?? '';
      _selectedCategory = exp['category'] ?? 'culinary';
      _selectedCurrency = exp['currency'] ?? 'IDR';
      _existingReceiptUrl = exp['receipt_url'];
      if (exp['date'] != null) {
        final parsedDate = DateTime.parse(exp['date']);
        _selectedDate = parsedDate;
        _selectedTime = TimeOfDay.fromDateTime(parsedDate);
      }
    }
    _fetchExchangeRates();
    _amountController.addListener(_updateConvertedAmount);
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateConvertedAmount);
    _amountController.dispose();
    _nameController.dispose();
    super.dispose();
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
      // Ignore API failure, default to 1.0
    } finally {
      if (mounted) setState(() => _isFetchingRates = false);
    }
  }

  void _updateConvertedAmount() {
    final amountText = _amountController.text.trim().replaceAll('.', '').replaceAll(',', '');
    final amount = double.tryParse(amountText) ?? 0.0;
    
    if (_selectedCurrency == 'IDR') {
      setState(() => _convertedIdr = amount);
    } else {
      final rate = _exchangeRates[_selectedCurrency];
      if (rate != null && rate > 0) {
        // IDR is base. rate is e.g. USD -> 0.000065. So IDR equivalent = amount / rate
        setState(() => _convertedIdr = amount / rate);
      }
    }
  }

  Future<void> _handleSave() async {
    final amountText = _amountController.text.trim().replaceAll('.', '').replaceAll(',', '');
    final name = _nameController.text.trim();

    if (amountText.isEmpty || name.isEmpty) {
      _showSnackBar('Mohon isi nama dan nominal pengeluaran');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showSnackBar('Nominal tidak valid');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      String? finalReceiptUrl = _existingReceiptUrl;
      if (_receiptFile != null) {
        finalReceiptUrl = await _supabase.uploadReceipt(_receiptFile!);
      }

      final expenseData = {
        'name': name,
        'amount': _selectedCurrency == 'IDR' ? amount.toInt() : _convertedIdr.toInt(),
        'original_amount': amount,
        'currency': _selectedCurrency,
        'exchange_rate': _selectedCurrency == 'IDR' ? 1.0 : _exchangeRates[_selectedCurrency],
        'category': _selectedCategory,
        'date': dateTime.toIso8601String(),
        'receipt_url': finalReceiptUrl,
      };

      if (widget.expense != null) {
        await _supabase.updateExpense(widget.expense!['id'].toString(), expenseData);
      } else {
        await _supabase.addExpense(expenseData);
      }

      if (mounted) {
        _showSnackBar(widget.expense != null ? 'Pengeluaran berhasil diperbarui!' : 'Pengeluaran berhasil disimpan!');
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context, true); // Return true to indicate data changed
        });
      }
    } catch (e) {
      _showSnackBar('Gagal menyimpan: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin menghapus pengeluaran ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal', style: TextStyle(color: Color(0xFF596273)))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _supabase.deleteExpense(widget.expense!['id'].toString());
        if (mounted) {
          _showSnackBar('Pengeluaran berhasil dihapus');
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) Navigator.pop(context, true);
          });
        }
      } catch (e) {
        _showSnackBar('Gagal menghapus: ${e.toString()}');
        if (mounted) setState(() => _isLoading = false);
      }
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
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _pickReceiptImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _receiptFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showSnackBar('Gagal memilih gambar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0D1B2A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.expense != null ? 'Edit Pengeluaran' : 'Tambah Pengeluaran',
          style: const TextStyle(
            color: Color(0xFF0D1B2A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Input Area with Wave Background
            Stack(
              children: [
                Positioned.fill(
                  child: ClipPath(
                    clipper: AmountWaveClipper(),
                    child: Container(
                      color: const Color(0xFFF7F9FB),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'JUMLAH NOMINAL',
                        style: TextStyle(
                          color: Color(0xFF596273),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2.0, right: 8.0),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCurrency,
                                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF596273)),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF596273),
                                ),
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
                          ),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D1B2A),
                              ),
                              decoration: const InputDecoration(
                                hintText: '0',
                                hintStyle: TextStyle(
                                  color: Color(0xFFE8ECEF),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.black12, thickness: 1),
                      if (_selectedCurrency != 'IDR')
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _isFetchingRates 
                              ? 'Menghitung kurs...' 
                              : '≈ Rp ${_convertedIdr.toInt()}',
                            style: const TextStyle(
                              color: Color(0xFF1E8F82),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Expense Name
                  const Text(
                    'NAMA PENGELUARAN',
                    style: TextStyle(
                      color: Color(0xFF596273),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Makan Malam di Jimbaran',
                      hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Category Selection
                  const Text(
                    'KATEGORI',
                    style: TextStyle(
                      color: Color(0xFF596273),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _categories.entries.map((entry) {
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = entry.key),
                        child: _buildCategoryOption(
                          entry.value['icon'] as IconData,
                          entry.value['label'] as String,
                          _selectedCategory == entry.key,
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Date and Time
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickDate,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TANGGAL',
                                style: TextStyle(
                                  color: Color(0xFF596273),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.black26),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                                    style: const TextStyle(fontSize: 14, color: Color(0xFF0D1B2A)),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.black12),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickTime,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'WAKTU',
                                style: TextStyle(
                                  color: Color(0xFF596273),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 16, color: Colors.black26),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontSize: 14, color: Color(0xFF0D1B2A)),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.black12),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Attachment
                  const Text(
                    'LAMPIRAN (OPSIONAL)',
                    style: TextStyle(
                      color: Color(0xFF596273),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickReceiptImage,
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.black12, style: BorderStyle.solid),
                      ),
                      child: _receiptFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.file(_receiptFile!, fit: BoxFit.cover),
                            )
                          : (_existingReceiptUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.network(_existingReceiptUrl!, fit: BoxFit.cover),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.camera_alt_outlined, color: Colors.black26, size: 24),
                                    SizedBox(height: 8),
                                    Text(
                                      'Unggah Foto Struk',
                                      style: TextStyle(
                                        color: Color(0xFF596273),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleSave,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Simpan Pengeluaran',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      label: _isLoading
                          ? const SizedBox.shrink()
                          : const Icon(Icons.check_circle_outline, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D1B2A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),
                  if (widget.expense != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: TextButton.icon(
                        onPressed: _isLoading ? null : _handleDelete,
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text(
                          'Hapus Pengeluaran',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[month - 1];
  }

  Widget _buildCategoryOption(IconData icon, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0D1B2A) : const Color(0xFFF7F9FB),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : const Color(0xFF596273),
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isActive ? const Color(0xFF0D1B2A) : const Color(0xFF596273),
          ),
        ),
      ],
    );
  }
}

class AmountWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(
        size.width / 4, size.height, size.width / 2, size.height - 20);
    path.quadraticBezierTo(
        size.width * 3 / 4, size.height - 40, size.width, size.height - 10);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;
  User? get currentUser => client.auth.currentUser;

  // ==================== AUTH ====================

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // ==================== PROFILES ====================

  Future<Map<String, dynamic>?> getProfile() async {
    final userId = currentUser?.id;
    if (userId == null) return null;
    final response = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    await client.from('profiles').update(data).eq('id', userId);
  }

  Future<String?> uploadAvatar(File imageFile) async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    final fileExtension = imageFile.path.split('.').last.toLowerCase();
    final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    final filePath = '$userId/$fileName';

    try {
      await client.storage.from('avatars').upload(filePath, imageFile);
      final publicUrl = client.storage.from('avatars').getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      // Re-throw or handle as necessary. 
      // If bucket doesn't exist or RLS fails, this will throw an exception.
      rethrow;
    }
  }

  // Upload Trip Image
  Future<String?> uploadTripImage(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final filePath = '${currentUser!.id}/$fileName';
      
      await client.storage.from('trips').upload(filePath, imageFile);
      return client.storage.from('trips').getPublicUrl(filePath);
    } catch (e) {
      print('Error uploading trip image: $e');
      return null;
    }
  }

  // Upload Receipt Image
  Future<String?> uploadReceipt(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final filePath = '${currentUser!.id}/$fileName';
      
      await client.storage.from('receipts').upload(filePath, imageFile);
      return client.storage.from('receipts').getPublicUrl(filePath);
    } catch (e) {
      print('Error uploading receipt image: $e');
      return null;
    }
  }

  // ==================== TRIPS ====================

  Future<List<Map<String, dynamic>>> getTrips() async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    final response = await client
        .from('trips')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> addTrip(Map<String, dynamic> data) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not logged in');
    data['user_id'] = userId;
    final response = await client.from('trips').insert(data).select().single();
    return response;
  }

  Future<void> deactivateAllTrips() async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not logged in');
    
    await client
        .from('trips')
        .update({'status': 'completed'})
        .eq('status', 'active')
        .eq('user_id', userId);
  }

  Future<void> endTrip(String tripId) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not logged in');
    
    await client
        .from('trips')
        .update({'status': 'completed'})
        .eq('id', tripId)
        .eq('user_id', userId);
  }

  Future<void> updateTrip(String tripId, Map<String, dynamic> data) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    await client.from('trips').update(data).eq('id', tripId).eq('user_id', userId);
  }

  Future<void> deleteTrip(String tripId) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    await client.from('trips').delete().eq('id', tripId).eq('user_id', userId);
  }

  // ==================== TRIP MEMBERS (COLLABORATION) ====================

  Future<List<Map<String, dynamic>>> getTripMembers(String tripId) async {
    final response = await client
        .from('trip_members')
        .select('*, profiles:user_id(full_name, avatar_url)')
        .eq('trip_id', tripId);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    
    // Pencarian hanya menggunakan full_name karena email tidak tersedia di tabel profiles
    final response = await client
        .from('profiles')
        .select('id, full_name, avatar_url')
        .ilike('full_name', '%$query%')
        .limit(10);
        
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addTripMemberById(String tripId, String memberUserId) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    // Cek apakah sudah menjadi anggota
    final existing = await client
        .from('trip_members')
        .select('id')
        .eq('trip_id', tripId)
        .eq('user_id', memberUserId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Pengguna sudah menjadi anggota perjalanan ini.');
    }

    await client.from('trip_members').insert({
      'trip_id': tripId,
      'user_id': memberUserId,
      'role': 'member'
    });
  }

  Future<void> removeTripMember(String tripId, String memberUserId) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    // We allow removing if the current user is the owner (role='admin' on this trip) 
    // or if they are removing themselves.
    // Assuming 'admin' is the owner. If RLS handles this, just delete.
    await client
        .from('trip_members')
        .delete()
        .eq('trip_id', tripId)
        .eq('user_id', memberUserId);
  }

  Future<void> addTripMemberByEmail(String tripId, String email) async {
    // Cari user berdasarkan email. (Di Supabase, Anda biasanya menggunakan endpoint edge function atau 
    // sebuah view yang menampilkan public profile user). Untuk saat ini kita asumsikan 
    // ada profil dengan email tersebut (jika ada kolom email di tabel profiles).
    // Jika tidak, Anda harus memanggil Edge Function untuk mencari id pengguna.
    final response = await client.from('profiles').select('id').eq('email', email).maybeSingle();
    if (response == null) {
      throw Exception('Pengguna dengan email tersebut tidak ditemukan.');
    }
    
    await client.from('trip_members').insert({
      'trip_id': tripId,
      'user_id': response['id'],
      'role': 'member'
    });
  }

  // ==================== ITINERARIES ====================

  Future<List<Map<String, dynamic>>> getItineraries(String tripId) async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    final response = await client
        .from('itineraries')
        .select()
        .eq('trip_id', tripId)
        .eq('user_id', userId)
        .order('day_number', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addItinerary(Map<String, dynamic> data) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    data['user_id'] = userId;
    await client.from('itineraries').insert(data);
  }

  Future<void> deleteItinerary(String id) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    await client.from('itineraries').delete().eq('id', id).eq('user_id', userId);
  }

  // ==================== EXPENSES ====================

  Future<List<Map<String, dynamic>>> getExpenses({String? tripId}) async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    var query = client.from('expenses').select().eq('user_id', userId);
    if (tripId != null) {
      query = query.eq('trip_id', tripId);
    }
    final response = await query.order('date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getExpensesByCategory(String category, {String? tripId}) async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    var query = client
        .from('expenses')
        .select()
        .eq('user_id', userId)
        .eq('category', category);
        
    if (tripId != null) {
      query = query.eq('trip_id', tripId);
    }
    
    final response = await query.order('date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getMonthlyExpenses(int month, int year) async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    
    // Create start and end date for the month
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = month == 12 
        ? DateTime(year + 1, 1, 1).toIso8601String()
        : DateTime(year, month + 1, 1).toIso8601String();
        
    final response = await client
        .from('expenses')
        .select()
        .eq('user_id', userId)
        .gte('date', startDate)
        .lt('date', endDate)
        .order('date', ascending: false);
        
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getMonthlyExpensesByCategory(String category, int month, int year) async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = month == 12 
        ? DateTime(year + 1, 1, 1).toIso8601String()
        : DateTime(year, month + 1, 1).toIso8601String();
        
    final response = await client
        .from('expenses')
        .select()
        .eq('user_id', userId)
        .eq('category', category)
        .gte('date', startDate)
        .lt('date', endDate)
        .order('date', ascending: false);
        
    return List<Map<String, dynamic>>.from(response);
  }

  Future<int> getMonthlyBudget(int month, int year) async {
    final userId = currentUser?.id;
    if (userId == null) return 0;
    
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = month == 12 
        ? DateTime(year + 1, 1, 1).toIso8601String()
        : DateTime(year, month + 1, 1).toIso8601String();
        
    final response = await client
        .from('trips')
        .select('budget')
        .eq('user_id', userId)
        .gte('created_at', startDate)
        .lt('created_at', endDate);
        
    int total = 0;
    for (var trip in response) {
      total += (trip['budget'] as num?)?.toInt() ?? 0;
    }
    return total;
  }

  Future<void> addExpense(Map<String, dynamic> data) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    data['user_id'] = userId;
    
    // Auto attach to active trip if not provided
    if (!data.containsKey('trip_id')) {
      final activeTrips = await client.from('trips').select('id').eq('status', 'active').eq('user_id', userId).limit(1);
      if (activeTrips.isNotEmpty) {
        data['trip_id'] = activeTrips.first['id'];
      }
    }
    
    await client.from('expenses').insert(data);
  }

  Future<void> updateExpense(String expenseId, Map<String, dynamic> data) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    await client.from('expenses').update(data).eq('id', expenseId).eq('user_id', userId);
  }

  Future<void> deleteExpense(String expenseId) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    await client.from('expenses').delete().eq('id', expenseId).eq('user_id', userId);
  }

  Future<void> deleteExpensesByCategory(String category, {String? tripId}) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    var query = client.from('expenses').delete().eq('category', category).eq('user_id', userId);
    if (tripId != null) {
      query = query.eq('trip_id', tripId);
    }
    await query;
  }

  Future<int> getTotalExpenses({String? tripId}) async {
    final userId = currentUser?.id;
    if (userId == null) return 0;
    var query = client
        .from('expenses')
        .select('amount')
        .eq('user_id', userId);
        
    if (tripId != null) {
      query = query.eq('trip_id', tripId);
    }
    
    final response = await query;
    int total = 0;
    for (var row in response) {
      total += (row['amount'] as num).toInt();
    }
    return total;
  }

  // ==================== DOCUMENTS (TRAVEL WALLET) ====================

  Future<List<Map<String, dynamic>>> getDocuments(String tripId) async {
    final response = await client
        .from('trip_documents')
        .select()
        .eq('trip_id', tripId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> uploadDocument(File file, String tripId, String type, String originalName) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    final fileExtension = file.path.split('.').last.toLowerCase();
    final fileName = '$tripId-${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    final filePath = '$tripId/$fileName';

    try {
      await client.storage.from('documents').upload(filePath, file);
      final publicUrl = client.storage.from('documents').getPublicUrl(filePath);

      await client.from('trip_documents').insert({
        'trip_id': tripId,
        'user_id': userId,
        'file_name': originalName,
        'file_url': publicUrl,
        'file_type': type,
      });
    } catch (e) {
      rethrow;
    }
  }

  // ==================== PAYMENT METHODS ====================

  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    final response = await client
        .from('payment_methods')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addPaymentMethod(Map<String, dynamic> data) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    data['user_id'] = userId;
    await client.from('payment_methods').insert(data);
  }

  Future<void> deletePaymentMethod(String methodId) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    await client.from('payment_methods').delete().eq('id', methodId).eq('user_id', userId);
  }
}

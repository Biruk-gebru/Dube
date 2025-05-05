import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../models/customer.dart';
import '../models/transaction.dart';
import '../models/product.dart';

class SupabaseService {
  final SupabaseClient _supabaseClient;

  SupabaseService(this._supabaseClient);

  // Profile operations
  Future<Profile?> getProfile(String userId) async {
    try {
      final response = await _supabaseClient
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      return response != null ? Profile.fromJson(response) : null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Profile>> getAllProfiles() async {
    final response = await _supabaseClient.from('profiles').select();
    return response.map((json) => Profile.fromJson(json)).toList();
  }

  Future<void> updateProfile(Profile profile) async {
    await _supabaseClient
        .from('profiles')
        .update(profile.toJson())
        .eq('user_id', profile.userId);
  }

  // Product operations
  Future<List<Product>> getProducts(String userId) async {
    try {
      final response = await _supabaseClient
          .from('products')
          .select()
          .eq('user_id', userId);
      
      return response.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Product> addProduct(Product product) async {
    final response = await _supabaseClient
        .from('products')
        .insert(product.toJson())
        .select()
        .single();
    return Product.fromJson(response);
  }

  Future<Product> addProductWithParams({
    required String name,
    required int stock,
    required int price,
    required String userId,
  }) async {
    final response = await _supabaseClient.from('products').insert({
      'name': name,
      'stock': stock,
      'price': price,
      'sold': 0,
      'user_id': userId,
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();
    
    return Product.fromJson(response);
  }

  Future<Product> updateProduct({
    required int id,
    required String name,
    required int stock,
    required int price,
  }) async {
    final response = await _supabaseClient
        .from('products')
        .update({
          'name': name,
          'stock': stock,
          'price': price,
        })
        .eq('id', id)
        .select()
        .single();
    
    return Product.fromJson(response);
  }

  Future<void> deleteProduct(int id) async {
    await _supabaseClient.from('products').delete().eq('id', id);
  }

  // Customer operations
  Future<List<Customer>> getCustomers(String userId) async {
    final response = await _supabaseClient
        .from('customers')
        .select()
        .eq('owner_id', userId);
    return response.map((json) => Customer.fromJson(json)).toList();
  }

  Future<Customer> addCustomer(Customer customer) async {
    // Get the current user's ID
    final currentUser = await _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }

    // Ensure owner_id is set to the current user
    final customerData = customer.toJson();
    customerData['owner_id'] = currentUser.id;

    final response = await _supabaseClient
        .from('customers')
        .insert(customerData)
        .select()
        .single();
    return Customer.fromJson(response);
  }

  Future<Customer> updateCustomer({
    required int id,
    required String name,
    String? phone,
  }) async {
    final data = {'name': name};
    if (phone != null) {
      data['phone'] = phone;
    }
    
    final response = await _supabaseClient
        .from('customers')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    
    return Customer.fromJson(response);
  }

  Future<Customer?> getCustomerByUsername(String username) async {
    try {
      final response = await _supabaseClient
          .from('customers')
          .select()
          .eq('name', username)
          .maybeSingle();
      
      return response != null ? Customer.fromJson(response) : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteCustomer(int id) async {
    // First get the customer's name
    final customerResponse = await _supabaseClient
        .from('customers')
        .select('name')
        .eq('id', id)
        .single();
        
    final customerName = customerResponse['name'] as String;
    
    // Delete all transactions where this customer is either the seller or the buyer
    await _supabaseClient
        .from('transactions')
        .delete()
        .or('seller_name.eq.${customerName},buyer_name.eq.${customerName}');
        
    // Finally delete the customer
    await _supabaseClient.from('customers').delete().eq('id', id);
  }

  // Transaction operations
  Future<List<Transaction>> getTransactions(String userId) async {
    final response = await _supabaseClient
        .from('transactions')
        .select()
        .eq('created_by', userId)
        .order('created_at', ascending: false);
    return response.map((json) => Transaction.fromJson(json)).toList();
  }

  Future<List<Transaction>> getTransactionsWithCustomer(String userId, String customerName) async {
    final response = await _supabaseClient
        .from('transactions')
        .select()
        .eq('created_by', userId)
        .eq('customer_name', customerName)
        .order('created_at', ascending: false);
    return response.map((json) => Transaction.fromJson(json)).toList();
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      final totalAmount = transaction.pricePerUnit * transaction.quantity;
      
      // Determine buyer and seller based on transaction type
      String buyerName = transaction.buyerName;
      String sellerName = transaction.sellerName;

      // Only check for matching transactions if this is for a registered customer
      if (transaction.matched == 'mismatched') {
        // Check for counterpart transactions
        final counterpartTransactions = await _supabaseClient
            .from('transactions')
            .select()
            .eq('product', transaction.product)
            .eq('quantity', transaction.quantity)
            .eq('price_per_unit', transaction.pricePerUnit)
            .neq('created_by', transaction.createdBy)
            .eq('seller_name', sellerName)
            .eq('buyer_name', buyerName);

        // If there's a matching counterpart, update both transactions
        if (counterpartTransactions.isNotEmpty) {
          final counterpartTransaction = counterpartTransactions.first;
          
          // First insert our new transaction
          final response = await _supabaseClient
              .from('transactions')
              .insert({
                'seller_name': sellerName,
                'buyer_name': buyerName,
                'product': transaction.product,
                'quantity': transaction.quantity,
                'price_per_unit': transaction.pricePerUnit,
                'total_amount': totalAmount,
                'type': transaction.type,
                'created_by': transaction.createdBy,
                'matched': 'matched',
                'counterpart_id': counterpartTransaction['id'],
                'counterpart_created_by': counterpartTransaction['created_by'],
              })
              .select()
              .single();
          
          // Then update the counterpart transaction
          await _supabaseClient
              .from('transactions')
              .update({
                'matched': 'matched',
                'counterpart_id': response['id'],
                'counterpart_created_by': transaction.createdBy,
              })
              .eq('id', counterpartTransaction['id']);
          
          return;
        }
      }

      Map<String, dynamic> data = {
        'seller_name': sellerName,
        'buyer_name': buyerName,
        'product': transaction.product,
        'quantity': transaction.quantity,
        'price_per_unit': transaction.pricePerUnit,
        'total_amount': totalAmount,
        'type': transaction.type,
        'created_by': transaction.createdBy,
        'matched': transaction.matched,
      };

      if (transaction.counterpartCreatedBy != null) {
        data['counterpart_created_by'] = transaction.counterpartCreatedBy as String;
      }
      
      if (transaction.counterpartId != null) {
        data['counterpart_id'] = transaction.counterpartId as int;
      }

      await _supabaseClient
          .from('transactions')
          .insert(data)
          .select()
          .single();
    } catch (e) {
      throw Exception('Failed to add transaction');
    }
  }

  // Statistics operations
  Future<Map<String, dynamic>> getTransactionStatistics(String userEmail) async {
    try {
      final transactions = await getTransactions(userEmail);
      
      // Count transactions by status
      int matchedTransactions = transactions.where((t) => t.matched == 'matched').length;
      int mismatchedTransactions = transactions.where((t) => t.matched == 'mismatched').length;
      int unregisteredTransactions = transactions.where((t) => t.matched == 'pending').length;
      
      // Calculate amounts with proper rounding
      double totalAmount = transactions.fold(0.0, (sum, t) => sum + t.totalAmount);
      
      double matchedAmount = transactions
          .where((t) => t.matched == 'matched')
          .fold(0.0, (sum, t) => sum + t.totalAmount);
          
      double mismatchedAmount = transactions
          .where((t) => t.matched == 'mismatched')
          .fold(0.0, (sum, t) => sum + t.totalAmount);
          
      double unregisteredAmount = transactions
          .where((t) => t.matched == 'pending')
          .fold(0.0, (sum, t) => sum + t.totalAmount);
          
      double buyAmount = transactions
          .where((t) => t.type == 'Buying')
          .fold(0.0, (sum, t) => sum + t.totalAmount);
          
      double sellAmount = transactions
          .where((t) => t.type == 'Selling')
          .fold(0.0, (sum, t) => sum + t.totalAmount);
      
      return {
        'matched': matchedTransactions,
        'mismatched': mismatchedTransactions,
        'unregistered': unregisteredTransactions,
        'total': transactions.length,
        'totalAmount': double.parse(totalAmount.toStringAsFixed(2)),
        'matchedAmount': double.parse(matchedAmount.toStringAsFixed(2)),
        'mismatchedAmount': double.parse(mismatchedAmount.toStringAsFixed(2)),
        'unregisteredAmount': double.parse(unregisteredAmount.toStringAsFixed(2)),
        'buyAmount': double.parse(buyAmount.toStringAsFixed(2)),
        'sellAmount': double.parse(sellAmount.toStringAsFixed(2)),
      };
    } catch (e) {
      throw Exception('Failed to load transaction statistics');
    }
  }
} 
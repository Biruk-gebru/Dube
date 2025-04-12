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
    print('Getting profile for user: $userId');
    try {
      final response = await _supabaseClient
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      print('Profile response: $response');
      return response != null ? Profile.fromJson(response) : null;
    } catch (e) {
      print('Error getting profile: $e');
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
    print('Getting products for user: $userId');
    try {
      final response = await _supabaseClient
          .from('products')
          .select()
          .eq('user_id', userId);
      
      print('Products response: $response');
      return response.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error getting products: $e');
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
        .eq('user_id', userId);
    return response.map((json) => Customer.fromJson(json)).toList();
  }

  Future<Customer> addCustomer(Customer customer) async {
    final response = await _supabaseClient
        .from('customers')
        .insert(customer.toJson())
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
      print('Error getting customer by username: $e');
      return null;
    }
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

  Future<Transaction> addTransaction(Transaction transaction) async {
    try {
      print('=== Starting Transaction Creation ===');
      print('Transaction details: ${transaction.toJson()}');
      
      // Calculate total amount
      final totalAmount = transaction.price * transaction.quantity;
      print('Total amount calculated: $totalAmount');
      
      // Determine seller and buyer based on transaction type
      final currentUser = await getProfile(transaction.userId);
      if (currentUser == null) {
        throw Exception('Current user profile not found');
      }
      final currentUserName = currentUser.username;
      
      final String sellerName;
      final String buyerName;
      
      if (transaction.type == TransactionType.sell) {
        sellerName = currentUserName;
        buyerName = transaction.customerName;
      } else {
        sellerName = transaction.customerName;
        buyerName = currentUserName;
      }

      print('Transaction parties - Seller: $sellerName, Buyer: $buyerName');

      // Check if a similar transaction already exists
      final existingTransaction = await _supabaseClient
          .from('transactions')
          .select()
          .eq('seller_name', sellerName)
          .eq('buyer_name', buyerName)
          .eq('product', transaction.productName)
          .eq('quantity', transaction.quantity)
          .eq('price_per_unit', transaction.price)
          .eq('created_by', transaction.userId)
          .maybeSingle();

      if (existingTransaction != null) {
        print('Similar transaction already exists: ${existingTransaction['id']}');
        throw Exception('A similar transaction already exists');
      }

      // Find matching transaction with proper matching criteria
      final matchingTransactions = await _supabaseClient
          .from('transactions')
          .select()
          .eq('product', transaction.productName)
          .eq('quantity', transaction.quantity)
          .eq('price_per_unit', transaction.price)
          .or('and(seller_name.eq.${buyerName},buyer_name.eq.${sellerName}),and(seller_name.eq.${sellerName},buyer_name.eq.${buyerName})')
          .neq('created_by', transaction.userId) // Don't match with own transactions
          .limit(1);

      String matchStatus = 'mismatched'; // Default to mismatched
      String? counterpartId;
      String? counterpartCreatedBy;

      if (matchingTransactions.isNotEmpty) {
        final match = matchingTransactions.first;
        final matchType = match['type'] as String;
        print('Match type: $matchType, Transaction type: ${transaction.type}');
        
        // Convert transaction type to string for comparison
        final transactionTypeString = transaction.type == TransactionType.buy ? 'Buying' : 'Selling';
        
        final isProperMatch =
            (transactionTypeString == 'Buying' && matchType == 'Selling') ||
            (transactionTypeString == 'Selling' && matchType == 'Buying');

        if (isProperMatch) {
          matchStatus = 'matched';
          counterpartId = match['id'].toString();
          counterpartCreatedBy = match['created_by'] as String;
          print('Found a proper match! Transaction will be marked as MATCHED');
        } else {
          print('Found a transaction but not a proper match. Will be marked as MISMATCHED');
        }
      } else {
        print('No matching transaction found, will be marked as MISMATCHED');
      }

      // Insert the transaction with the correct status
      final transactionData = {
        'seller_name': sellerName,
        'buyer_name': buyerName,
        'type': transaction.type == TransactionType.buy ? 'Buying' : 'Selling',
        'product': transaction.productName,
        'quantity': transaction.quantity,
        'price_per_unit': transaction.price,
        'total_amount': totalAmount,
        'created_by': transaction.userId,
        'matched': matchStatus,
        'counterpart_id': counterpartId,
        'counterpart_created_by': counterpartCreatedBy,
      };

      print('Inserting transaction with data: $transactionData');
      final response = await _supabaseClient
          .from('transactions')
          .insert(transactionData)
          .select()
          .single();

      print('Transaction created successfully: ${response.toString()}');
      
      // If we found a matching transaction, update it as well
      if (counterpartId != null && matchStatus == 'matched') {
        print('Updating matching transaction: $counterpartId');
        await _supabaseClient
            .from('transactions')
            .update({
              'matched': 'matched',
              'counterpart_id': response['id'].toString(),
              'counterpart_created_by': transaction.userId,
            })
            .eq('id', counterpartId);
      }

      return Transaction.fromJson(response);
    } catch (e, stackTrace) {
      print('Error creating transaction: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Statistics operations
  Future<Map<String, dynamic>> getTransactionStatistics(String userId) async {
    final transactions = await getTransactions(userId);
    
    int totalTransactions = transactions.length;
    int matchedTransactions = transactions.where((t) => t.status == TransactionStatus.matched).length;
    int mismatchedTransactions = transactions.where((t) => t.status == TransactionStatus.mismatched).length;
    
    double totalAmount = transactions.fold(0, (sum, t) => sum + t.price);
    double matchedAmount = transactions
        .where((t) => t.status == TransactionStatus.matched)
        .fold(0, (sum, t) => sum + t.price);
    
    double buyAmount = transactions
        .where((t) => t.type == TransactionType.buy)
        .fold(0, (sum, t) => sum + t.price);
    
    double sellAmount = transactions
        .where((t) => t.type == TransactionType.sell)
        .fold(0, (sum, t) => sum + t.price);
    
    return {
      'total': totalTransactions,
      'matched': matchedTransactions,
      'mismatched': mismatchedTransactions,
      'totalAmount': totalAmount,
      'matchedAmount': matchedAmount,
      'buyAmount': buyAmount,
      'sellAmount': sellAmount,
    };
  }
} 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/customer.dart';
import '../../models/transaction.dart';
import '../../models/product.dart';
import '../../models/profile.dart';
import '../../services/supabase_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Customer> _customers = [];
  List<Profile> _allProfiles = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = context.read<AuthService>().currentUser?.id;
      if (userId != null) {
        final customers = await context.read<SupabaseService>().getCustomers(userId);
        final profiles = await context.read<SupabaseService>().getAllProfiles();
        
        // Filter out the current user from profiles
        final filteredProfiles = profiles.where((profile) => profile.id != userId).toList();
        
        setState(() {
          _customers = customers;
          _allProfiles = filteredProfiles;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addCustomer(Profile profile) async {
    try {
      final userId = context.read<AuthService>().currentUser?.id;
      if (userId != null) {
        // Create customer with current user as owner
        final customer = Customer(
          id: 0, // This will be replaced by the database
          name: profile.username,
          userId: userId, // Current user is the owner
          amountOwed: 0,
          amountPaid: 0,
          matched: false,
        );
        
        print('Adding customer with userId (owner): ${customer.userId}');
        print('Customer profile ID: ${profile.id}');
        await context.read<SupabaseService>().addCustomer(customer);
        await _loadData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${profile.username} added as a customer')),
        );
      }
    } catch (e) {
      print('Error adding customer: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding customer: $e')),
      );
    }
  }

  Future<void> _addTransaction(Customer customer) async {
    try {
      final result = await showDialog<Transaction>(
        context: context,
        builder: (context) => TransactionDialog(customer: customer),
      );

      if (result != null) {
        setState(() => _isLoading = true);
        try {
          await context.read<SupabaseService>().addTransaction(result);
          await _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaction added successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          print('Error adding transaction: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error adding transaction: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      }
    } catch (e) {
      print('Error in transaction dialog: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  List<Profile> get _filteredProfiles {
    if (_searchQuery.isEmpty) {
      return _allProfiles;
    }
    return _allProfiles.where((profile) => 
      profile.username.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Customers'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Customers'),
              Tab(text: 'Add Customers'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(
          children: [
            // My Customers Tab
            _customers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No customers yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            DefaultTabController.of(context).animateTo(1);
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Customers'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _customers.length,
                    itemBuilder: (context, index) {
                      final customer = _customers[index];
                      return Card(
                        child: ExpansionTile(
                          title: Text(customer.name),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Amount Owed: \$${customer.amountOwed.toStringAsFixed(2)} | '
                                    'Amount Paid: \$${customer.amountPaid.toStringAsFixed(2)}',
                                  ),
                                  const SizedBox(height: 16),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, size: 32),
                                    onPressed: () => _addTransaction(customer),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            
            // Add Customers Tab
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Users',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _filteredProfiles.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'No users found'
                                : 'No users match your search',
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredProfiles.length,
                          itemBuilder: (context, index) {
                            final profile = _filteredProfiles[index];
                            final isCustomer = _customers.any(
                              (c) => c.name == profile.username,
                            );
                            
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(profile.username[0].toUpperCase()),
                              ),
                              title: Text(profile.username),
                              subtitle: Text(profile.email),
                              trailing: isCustomer
                                  ? const Chip(
                                      label: Text('Customer'),
                                      backgroundColor: Colors.green,
                                    )
                                  : TextButton.icon(
                                      onPressed: () => _addCustomer(profile),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add'),
                                    ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(TransactionStatus status) {
    Color color;
    switch (status) {
      case TransactionStatus.matched:
        color = AppTheme.statusColors['matched']!;
        break;
      case TransactionStatus.mismatched:
        color = AppTheme.statusColors['mismatched']!;
        break;
      default:
        color = AppTheme.statusColors['pending']!;
    }

    return Chip(
      label: Text(
        status.toString().split('.').last,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }
}

class TransactionDialog extends StatefulWidget {
  final Customer customer;

  const TransactionDialog({super.key, required this.customer});

  @override
  State<TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<TransactionDialog> {
  TransactionType _type = TransactionType.buy;
  Product? _selectedProduct;
  List<Product> _myProducts = [];
  List<Product> _customerProducts = [];
  bool _isLoading = true;
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    
    try {
      final authService = context.read<AuthService>();
      final supabaseService = context.read<SupabaseService>();
      final userId = authService.currentUser?.id;
      
      if (userId != null) {
        // Load my products (for selling)
        print('Loading my products for user: $userId');
        final myProducts = await supabaseService.getProducts(userId);
        print('My products loaded: ${myProducts.length} products');
        
        // Get all profiles to find the customer's profile
        print('Loading all profiles to find customer: ${widget.customer.name}');
        final profiles = await supabaseService.getAllProfiles();
        
        // First try to find by username
        var customerProfile = profiles.firstWhere(
          (profile) => profile.username == widget.customer.name,
          orElse: () => throw Exception('Customer not found by username'),
        );
        
        // If not found by username, try to find by user_id
        if (customerProfile == null) {
          print('Customer not found by username, trying to find by user_id');
          // We need to get the customer's user_id from the customers table
          final customerResponse = await supabaseService.getCustomerByUsername(widget.customer.name);
              
          if (customerResponse != null) {
            final customerUserId = customerResponse.userId;
            customerProfile = profiles.firstWhere(
              (profile) => profile.userId == customerUserId,
              orElse: () => throw Exception('Customer profile not found'),
            );
          } else {
            throw Exception('Customer not found');
          }
        }
        
        print('Found customer profile: ${customerProfile.id}');
        // Load customer's products (for buying)
        final customerProducts = await supabaseService.getProducts(customerProfile.userId);
        print('Customer products loaded: ${customerProducts.length} products');

        if (!mounted) return;
        
        setState(() {
          _myProducts = myProducts;
          _customerProducts = customerProducts;
          _isLoading = false;
        });

        print('Current mode: ${_type == TransactionType.buy ? "Buying" : "Selling"}');
        print('Available products: ${_currentProducts.length}');
      } else {
        print('Error: No user ID available');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: User not logged in')),
          );
        }
      }
    } catch (e, stackTrace) {
      print('Error loading products: $e');
      print('Stack trace: $stackTrace');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading products: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  List<Product> get _currentProducts {
    // When buying, show customer's products (we're buying from them)
    // When selling, show my products (we're selling to them)
    return _type == TransactionType.buy ? _customerProducts : _myProducts;
  }

  @override
  Widget build(BuildContext context) {
    final products = _currentProducts;
    
    return Dialog(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Transaction with ${widget.customer.name}',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SegmentedButton<TransactionType>(
                      segments: const [
                        ButtonSegment(
                          value: TransactionType.buy,
                          label: Text('Buy'),
                        ),
                        ButtonSegment(
                          value: TransactionType.sell,
                          label: Text('Sell'),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (Set<TransactionType> selected) {
                        setState(() {
                          _type = selected.first;
                          _selectedProduct = null; // Reset selection when switching types
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (products.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _type == TransactionType.buy
                              ? 'No products available from this customer'
                              : 'You have no products to sell',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      DropdownButtonFormField<Product>(
                        value: _selectedProduct,
                        decoration: InputDecoration(
                          labelText: _type == TransactionType.buy
                              ? 'Select Product to Buy'
                              : 'Select Product to Sell',
                          border: const OutlineInputBorder(),
                        ),
                        items: products.map((product) {
                          return DropdownMenuItem(
                            value: product,
                            child: Text('${product.name} (\$${product.price})'),
                          );
                        }).toList(),
                        onChanged: (Product? value) {
                          setState(() {
                            _selectedProduct = value;
                            if (value != null) {
                              _priceController.text = value.price.toString();
                            }
                          });
                        },
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price per unit',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: products.isEmpty
                              ? null
                              : () {
                                  if (_selectedProduct != null &&
                                      _quantityController.text.isNotEmpty &&
                                      _priceController.text.isNotEmpty) {
                                    final transaction = Transaction(
                                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                                      userId: context.read<AuthService>().currentUser!.id,
                                      customerName: widget.customer.name,
                                      productId: _selectedProduct!.id,
                                      productName: _selectedProduct!.name,
                                      type: _type,
                                      quantity: int.parse(_quantityController.text),
                                      price: int.parse(_priceController.text),
                                      status: TransactionStatus.pending,
                                      createdAt: DateTime.now(),
                                    );
                                    Navigator.pop(context, transaction);
                                  }
                                },
                          child: const Text('Add Transaction'),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
} 
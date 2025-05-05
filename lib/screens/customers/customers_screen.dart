import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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

class _CustomersScreenState extends State<CustomersScreen> with SingleTickerProviderStateMixin {
  List<Customer> _customers = [];
  List<Profile> _allProfiles = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
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
        final filteredProfiles = profiles.where((profile) => 
          profile.id != userId && profile.userId != userId
        ).toList();
        
        setState(() {
          _customers = customers;
          _allProfiles = filteredProfiles;
        });
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorLoadingCustomers(e.toString()))),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _deleteCustomer(Customer customer, {bool skipConfirmation = false}) async {
    bool shouldDelete = skipConfirmation;
    final l10n = AppLocalizations.of(context)!;
    
    if (!skipConfirmation) {
      shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.deleteCustomer),
          content: Text(l10n.confirmDeleteCustomer(customer.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.delete),
            ),
          ],
        ),
      ) ?? false;
    }

    if (shouldDelete) {
      setState(() => _isLoading = true);
      try {
        await context.read<SupabaseService>().deleteCustomer(customer.id);
        _loadData();
        return true; // Successfully deleted
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorDeletingCustomer(e.toString()))),
        );
        setState(() => _isLoading = false);
        return false; // Failed to delete
      }
    }
    return false; // User cancelled deletion
  }

  Future<void> _addCustomer(Profile profile) async {
    try {
      final userId = context.read<AuthService>().currentUser?.id;
      if (userId != null) {
        // First check if this user is already a customer
        final existingCustomers = _customers.where((c) => c.name == profile.username).toList();
        
        if (existingCustomers.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${profile.username} is already your customer')),
          );
          return;
        }
        
        // Create customer with:
        // - user_id as the customer's auth ID (profile.userId)
        // - owner_id as the current user's ID
        final customer = Customer(
          id: 0, // This will be replaced by the database
          name: profile.username,
          userId: profile.userId, // The customer's auth ID
          ownerId: userId, // Current user is the owner
          isRegistered: true, // This is a registered customer
        );
        
        await context.read<SupabaseService>().addCustomer(customer);
        await _loadData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${profile.username} added as a customer')),
        );
      }
    } catch (e) {
      print('Error adding customer: $e'); // Add debug print
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorAddingCustomer(e.toString()))),
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to add transaction. Please try again.'),
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
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorAddingTransaction(e.toString())),
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

  void _showAddCustomerDialog() {
    final l10n = AppLocalizations.of(context)!;
    _nameController.clear();
    _phoneController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addUnregisteredCustomer),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.name,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterName;
                      }
                      return null;
                    },
                  ),
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: l10n.phoneNumber,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                Chip(
                  label: Text(l10n.unregisteredCustomerStatus),
                  backgroundColor: Colors.orange,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    l10n.unregisteredCustomerInfo,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelAction),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _addManualCustomer();
                Navigator.pop(context);
              }
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }

  Future<void> _addManualCustomer() async {
    try {
      final userId = context.read<AuthService>().currentUser?.id;
      if (userId != null) {
        // Create customer with:
        // - user_id as null (unregistered)
        // - owner_id as the current user's ID
        final customer = Customer(
          id: 0, // This will be replaced by the database
          name: _nameController.text.trim(),
          userId: null, // No auth user for unregistered customers
          ownerId: userId, // Current user is the owner
          isRegistered: false, // Manual customers are always unregistered
        );
        
        await context.read<SupabaseService>().addCustomer(customer);
        await _loadData();
        
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.customerAdded(_nameController.text.trim()))),
          );
        }
      }
    } catch (e) {
      print('Error adding manual customer: $e'); // Add debug print
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorAddingCustomer(e.toString()))),
        );
      }
    }
  }

  Future<void> _updateCustomer(Customer customer) async {
    final l10n = AppLocalizations.of(context)!;
    _nameController.text = customer.name;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editCustomer),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.name,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterName;
                      }
                      return null;
                    },
                  ),
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: l10n.phoneNumber,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.update),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() => _isLoading = true);
      try {
        await context.read<SupabaseService>().updateCustomer(
          id: customer.id,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        );
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorUpdatingCustomer(e.toString()))),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Tooltip(
                message: l10n.myCustomersTooltip,
                child: Icon(Icons.people),
              ),
            ),
            Tab(
              icon: Tooltip(
                message: l10n.addCustomersTooltip,
                child: Icon(Icons.person_add),
              ),
            ),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // My Customers Tab
          _customers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noCustomersYet,
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _customers.length,
                  itemBuilder: (context, index) {
                    final customer = _customers[index];
                    return Dismissible(
                      key: Key('customer-${customer.id}'),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await _deleteCustomer(customer);
                      },
                      onDismissed: (direction) {
                        // Nothing needed here, the customer is already deleted
                      },
                      child: Card(
                        child: ListTile(
                          title: Row(
                            children: [
                              Text(customer.name),
                              if (!customer.isRegistered)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Chip(
                                    label: Text(l10n.unregistered),
                                    backgroundColor: Colors.orange,
                                    labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 24),
                            onPressed: () => _addTransaction(customer),
                            tooltip: l10n.addTransactionTooltip,
                          ),
                        ),
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
                            trailing: isCustomer
                                ? Chip(
                                    label: Text(l10n.customer),
                                    backgroundColor: Colors.green,
                                  )
                                : TextButton.icon(
                                    onPressed: () => _addCustomer(profile),
                                    icon: const Icon(Icons.add),
                                    label: Text(l10n.add),
                                  ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0 
          ? FloatingActionButton(
              onPressed: _showAddCustomerDialog,
              tooltip: l10n.addCustomer,
              child: const Icon(Icons.person_add),
            )
          : null,
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
  final _productNameController = TextEditingController();

  // Handle null isRegistered values
  bool get _isCustomerRegistered => 
    widget.customer.isRegistered ?? false;

  @override
  void initState() {
    super.initState();
    print('TransactionDialog initialized');
    print('Customer: ${widget.customer.name}');
    print('Customer registration status: ${widget.customer.isRegistered}');
    _loadProducts();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _productNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    print('Loading products for customer: ${widget.customer.name}');
    print('Customer registration status: ${widget.customer.isRegistered}');
    print('Customer userId: ${widget.customer.userId}');
    
    try {
      final authService = context.read<AuthService>();
      final supabaseService = context.read<SupabaseService>();
      final userId = authService.currentUser?.id;
      
      if (userId != null) {
        print('Current user ID: $userId');
        
        // Always load my products for selling
        final myProducts = await supabaseService.getProducts(userId);
        print('My products loaded: ${myProducts.length}');
        
        // Initialize empty customer products list
        List<Product> customerProducts = [];
        
        // Only load customer products if they are registered and have a userId
        if (widget.customer.isRegistered ?? false) {
          print('Customer is registered, loading their products');
          if (widget.customer.userId != null) {
            customerProducts = await supabaseService.getProducts(widget.customer.userId!);
            print('Loaded customer products: ${customerProducts.length}');
          } else {
            print('Customer userId is null, cannot load their products');
          }
        } else {
          print('Customer is not registered, skipping product load');
        }

        if (mounted) {
          setState(() {
            _myProducts = myProducts;
            _customerProducts = customerProducts;
            _isLoading = false;
          });
        }
      } else {
        print('Current user ID is null');
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorUserNotLoggedIn)),
          );
        }
      }
    } catch (e) {
      print('Error loading products: $e');
      if (!mounted) return;
      
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorLoadingProducts(e.toString()))),
      );
      setState(() => _isLoading = false);
    }
  }

  Widget _buildProductSelection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    print('Building product selection');
    print('Transaction type: $_type');
    print('Customer registered: ${widget.customer.isRegistered}');
    print('Available customer products: ${_customerProducts.length}');
    print('Available my products: ${_myProducts.length}');

    // When buying
    if (_type == TransactionType.buy) {
      if (!(widget.customer.isRegistered ?? false)) {
        print('Showing text input for unregistered customer');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                l10n.enterManualProduct,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            TextFormField(
              controller: _productNameController,
              decoration: InputDecoration(
                labelText: l10n.manualProductName,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.pleaseEnterName;
                }
                return null;
              },
            ),
          ],
        );
      }
      
      // For registered customers, show their products or message if none
      print('Showing products for registered customer');
      if (_customerProducts.isEmpty) {
        print('No customer products available');
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            l10n.noProductsFromCustomer,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        );
      }

      print('Showing customer products dropdown');
      return DropdownButtonFormField<Product>(
        value: _selectedProduct,
        decoration: InputDecoration(
          labelText: l10n.selectProductToBuy,
          border: const OutlineInputBorder(),
        ),
        items: _customerProducts.map((product) {
          return DropdownMenuItem(
            value: product,
            child: Text(product.name),
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
      );
    }
    
    // When selling (to any customer)
    print('Showing selling UI');
    if (_myProducts.isEmpty) {
      print('No products available to sell');
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          l10n.noProductsToSell,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    print('Showing my products dropdown for selling');
    return DropdownButtonFormField<Product>(
      value: _selectedProduct,
      decoration: InputDecoration(
        labelText: l10n.selectProductToSell,
        border: const OutlineInputBorder(),
      ),
      items: _myProducts.map((product) {
        return DropdownMenuItem(
          value: product,
          child: Text(product.name),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
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
                      l10n.transactionWith(widget.customer.name),
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (!_isCustomerRegistered)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          children: [
                            Chip(
                              label: Text(l10n.unregistered),
                              backgroundColor: Colors.orange,
                              labelStyle: const TextStyle(color: Colors.white),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Text(
                                l10n.unregisteredCustomerNote,
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    SegmentedButton<TransactionType>(
                      segments: [
                        ButtonSegment(
                          value: TransactionType.buy,
                          icon: const Icon(Icons.shopping_cart),
                          label: Text(l10n.buy),
                        ),
                        ButtonSegment(
                          value: TransactionType.sell,
                          icon: const Icon(Icons.monetization_on),
                          label: Text(l10n.sell),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (Set<TransactionType> selected) {
                        setState(() {
                          _type = selected.first;
                          _selectedProduct = null;
                          _productNameController.clear();
                          _priceController.clear();
                        });
                      },
                      showSelectedIcon: false,
                    ),
                    const SizedBox(height: 16),
                    _buildProductSelection(context),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: l10n.quantityLabel,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.pleaseEnterValidNumber;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: l10n.priceLabel,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.pleaseEnterValidNumber;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.cancelButton),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final quantity = int.tryParse(_quantityController.text);
                            final price = int.tryParse(_priceController.text);
                            
                            final isValid = (_type == TransactionType.buy && !_isCustomerRegistered && 
                                _productNameController.text.isNotEmpty && quantity != null && price != null) ||
                                (_selectedProduct != null && quantity != null && price != null);
                            
                            if (isValid) {
                              final currentUser = context.read<AuthService>().currentUser!;
                              final productName = _selectedProduct?.name ?? _productNameController.text;
                              
                              print('Creating transaction:');
                              print('Current user email: ${currentUser.email}');
                              print('Customer name: ${widget.customer.name}');
                              print('Transaction type: $_type');
                              print('Product: $productName');
                              print('Quantity: $quantity');
                              print('Price: $price');
                              print('Customer registered: ${_isCustomerRegistered}');
                              
                              final transaction = Transaction(
                                id: 0, // Will be generated by database
                                sellerName: _type == TransactionType.buy ? widget.customer.name : currentUser.email!,
                                buyerName: _type == TransactionType.buy ? currentUser.email! : widget.customer.name,
                                type: _type == TransactionType.buy ? 'Buying' : 'Selling',
                                product: productName,
                                quantity: quantity,
                                pricePerUnit: price.toDouble(),
                                totalAmount: (quantity * price).toDouble(),
                                matched: _isCustomerRegistered ? 'mismatched' : 'pending',
                                createdBy: currentUser.email!,
                                counterpartCreatedBy: _isCustomerRegistered ? widget.customer.name : null,
                                counterpartId: null,
                              );
                              
                              print('Transaction object created:');
                              print('Seller: ${transaction.sellerName}');
                              print('Buyer: ${transaction.buyerName}');
                              print('Type: ${transaction.type}');
                              print('Product: ${transaction.product}');
                              print('Quantity: ${transaction.quantity}');
                              print('Price: ${transaction.pricePerUnit}');
                              print('Total: ${transaction.totalAmount}');
                              
                              Navigator.pop(context, transaction);
                            }
                          },
                          child: Text(l10n.addTransactionButton),
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
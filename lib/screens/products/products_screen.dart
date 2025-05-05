import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/product.dart';
import '../../services/supabase_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> _products = [];
  bool _isLoading = true;
  final _nameController = TextEditingController();
  final _stockController = TextEditingController();
  final _priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final userId = context.read<AuthService>().currentUser?.id;
      if (userId != null) {
        final products = await context.read<SupabaseService>().getProducts(userId);
        setState(() => _products = products);
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorLoadingProducts(e.toString()))),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final userId = context.read<AuthService>().currentUser?.id;
      if (userId != null) {
        await context.read<SupabaseService>().addProductWithParams(
          name: _nameController.text.trim(),
          stock: int.parse(_stockController.text.trim()),
          price: int.parse(_priceController.text.trim()),
          userId: userId,
        );
        
        _nameController.clear();
        _stockController.clear();
        _priceController.clear();
        Navigator.pop(context);
        _loadProducts();
        
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.productAddedSuccessfully)),
        );
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorAddingProduct(e.toString()))),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProduct(Product product) async {
    final l10n = AppLocalizations.of(context)!;
    _nameController.text = product.name;
    _stockController.text = product.stock.toString();
    _priceController.text = product.price.toString();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editProduct),
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextFormField(
                    controller: _stockController,
                    decoration: InputDecoration(
                      labelText: l10n.stock,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterStock;
                      }
                      if (int.tryParse(value) == null) {
                        return l10n.pleaseEnterValidNumber;
                      }
                      return null;
                    },
                  ),
                ),
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: l10n.price,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterPrice;
                    }
                    if (int.tryParse(value) == null) {
                      return l10n.pleaseEnterValidNumber;
                    }
                    return null;
                  },
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
            child: Text(l10n.save),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
        titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 8.0),
      ),
    );

    if (result == true) {
      setState(() => _isLoading = true);
      try {
        await context.read<SupabaseService>().updateProduct(
          id: product.id,
          name: _nameController.text.trim(),
          stock: int.parse(_stockController.text.trim()),
          price: int.parse(_priceController.text.trim()),
        );
        _loadProducts();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.productUpdatedSuccessfully)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorUpdatingProduct(e.toString()))),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteProduct(Product product, {bool skipConfirmation = false}) async {
    // Skip confirmation dialog if it was already shown (for swipe-to-delete)
    bool shouldDelete = skipConfirmation;
    final l10n = AppLocalizations.of(context)!;
    
    if (!skipConfirmation) {
      shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.deleteProduct),
          content: Text(l10n.confirmDeleteProduct(product.name)),
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
        await context.read<SupabaseService>().deleteProduct(product.id);
        _loadProducts();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.productDeletedSuccessfully)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorDeletingProduct(e.toString()))),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddProductDialog() {
    final l10n = AppLocalizations.of(context)!;
    _nameController.clear();
    _stockController.clear();
    _priceController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addProduct),
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextFormField(
                    controller: _stockController,
                    decoration: InputDecoration(
                      labelText: l10n.stock,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterStock;
                      }
                      if (int.tryParse(value) == null) {
                        return l10n.pleaseEnterValidNumber;
                      }
                      return null;
                    },
                  ),
                ),
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: l10n.price,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterPrice;
                    }
                    if (int.tryParse(value) == null) {
                      return l10n.pleaseEnterValidNumber;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: _addProduct,
            child: Text(l10n.add),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
        titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 8.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noProductsYet,
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return Dismissible(
                      key: Key('product-${product.id}'),
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
                        return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l10n.deleteProduct),
                            content: Text(l10n.confirmDeleteProduct(product.name)),
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
                        );
                      },
                      onDismissed: (direction) {
                        _deleteProduct(product, skipConfirmation: true);
                      },
                      child: Card(
                        child: ListTile(
                          title: Text(product.name),
                          subtitle: Text(l10n.stockInfo(
                              product.stock,
                              product.sold, 
                              product.price)),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _updateProduct(product),
                            tooltip: l10n.editProduct,
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        tooltip: l10n.addProduct,
        child: const Icon(Icons.add),
      ),
    );
  }
} 
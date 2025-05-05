import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaction.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Transaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      final supabaseService = context.read<SupabaseService>();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser != null) {
        final transactions = await supabaseService.getTransactions(currentUser.username);
        setState(() {
          _transactions = transactions;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addTransaction() async {
    final result = await showDialog<Transaction>(
      context: context,
      builder: (context) => const AddTransactionDialog(),
    );

    if (result != null) {
      try {
        final supabaseService = context.read<SupabaseService>();
        await supabaseService.addTransaction(result);
        await _loadTransactions();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: ListView.builder(
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(transaction.product),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${transaction.type.toString().split('.').last}: ${transaction.quantity} units'),
                  Text('Price: \$${transaction.pricePerUnit} per unit'),
                  Text('Total: \$${transaction.totalAmount}'),
                  Text('Status: ${transaction.status.toString().split('.').last}'),
                ],
              ),
              trailing: _getStatusIcon(transaction.status),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _getStatusIcon(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.matched:
        return const Icon(Icons.check_circle, color: Colors.green);
      case TransactionStatus.mismatched:
        return const Icon(Icons.warning, color: Colors.orange);
      case TransactionStatus.pending:
        return const Icon(Icons.hourglass_empty, color: Colors.grey);
    }
  }
}

class AddTransactionDialog extends StatefulWidget {
  const AddTransactionDialog({super.key});

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _productController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _buyerController = TextEditingController();
  TransactionType _type = TransactionType.sale;

  @override
  void dispose() {
    _productController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _buyerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Transaction'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<TransactionType>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Transaction Type',
                ),
                items: TransactionType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _type = value!;
                  });
                },
              ),
              TextFormField(
                controller: _productController,
                decoration: const InputDecoration(
                  labelText: 'Product',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a quantity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price per Unit',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _buyerController,
                decoration: const InputDecoration(
                  labelText: 'Counterparty Username',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
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
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final quantity = int.parse(_quantityController.text);
              final pricePerUnit = double.parse(_priceController.text);
              final totalAmount = quantity * pricePerUnit;

              final transaction = Transaction(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                sellerName: _type == TransactionType.sale
                    ? 'current_user' // This will be replaced with actual username
                    : _buyerController.text,
                buyerName: _type == TransactionType.sale
                    ? _buyerController.text
                    : 'current_user', // This will be replaced with actual username
                type: _type,
                product: _productController.text,
                quantity: quantity,
                pricePerUnit: pricePerUnit,
                totalAmount: totalAmount,
                createdAt: DateTime.now(),
                status: TransactionStatus.pending,
              );

              Navigator.pop(context, transaction);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaction.dart';
import '../../services/supabase_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class ReconciliationScreen extends StatefulWidget {
  const ReconciliationScreen({super.key});

  @override
  State<ReconciliationScreen> createState() => _ReconciliationScreenState();
}

class _ReconciliationScreenState extends State<ReconciliationScreen> {
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final userId = context.read<AuthService>().currentUser?.id;
      if (userId != null) {
        final transactions = await context
            .read<SupabaseService>()
            .getTransactions(userId);
        setState(() => _transactions = transactions);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading transactions: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Transaction> get _filteredTransactions {
    switch (_filter) {
      case 'matched':
        return _transactions
            .where((t) => t.status == TransactionStatus.matched)
            .toList();
      case 'mismatched':
        return _transactions
            .where((t) => t.status == TransactionStatus.mismatched)
            .toList();
      default:
        return _transactions;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'all',
                  label: Text('All'),
                ),
                ButtonSegment(
                  value: 'matched',
                  label: Text('Matched'),
                ),
                ButtonSegment(
                  value: 'mismatched',
                  label: Text('Mismatched'),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => _filter = newSelection.first);
              },
            ),
          ),
          Expanded(
            child: _transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No transactions yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _filteredTransactions[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                            '${transaction.type == TransactionType.buy ? 'Buy' : 'Sell'} - ${transaction.productName}',
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Customer: ${transaction.customerName}'),
                              Text(
                                'Quantity: ${transaction.quantity} | Price: \$${transaction.price}',
                              ),
                              Text(
                                'Date: ${transaction.createdAt.toString().split('.')[0]}',
                              ),
                            ],
                          ),
                          trailing: _buildStatusChip(transaction.status),
                        ),
                      );
                    },
                  ),
          ),
        ],
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
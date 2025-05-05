import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaction.dart';
import '../../services/supabase_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
      final currentUser = context.read<AuthService>().currentUser;
      if (currentUser?.email != null) {
        final transactions = await context.read<SupabaseService>().getTransactions(currentUser!.email!);
        setState(() {
          switch (_filter) {
            case 'matched':
              _transactions = transactions
                  .where((t) => t.matched == 'matched')
                  .toList();
              break;
            case 'mismatched':
              _transactions = transactions
                  .where((t) => t.matched == 'mismatched')
                  .toList();
              break;
            case 'unregistered':
              _transactions = transactions
                  .where((t) => t.matched == 'pending')
                  .toList();
              break;
            default:
              _transactions = transactions;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorLoadingTransactions(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildClassificationChip(String filter, String label, Color color, int count, String emoji) {
    return Tooltip(
      message: label,
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: () {
          setState(() {
            _filter = _filter == filter ? 'all' : filter;
            _loadTransactions();
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _filter == filter ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _filter == filter ? color : color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 16),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Text(
                  count.toString(),
                  style: TextStyle(
                    color: _filter == filter ? color : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Calculate counts for each category
    final matchedCount = _transactions.where((t) => t.matched == 'matched').length;
    final mismatchedCount = _transactions.where((t) => t.matched == 'mismatched').length;
    final unregisteredCount = _transactions.where((t) => t.matched == 'pending').length;
    final totalCount = _transactions.length;

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildClassificationChip(
                    'all',
                    l10n.all,
                    Colors.blue,
                    totalCount,
                    '•',
                  ),
                  const SizedBox(width: 8),
                  _buildClassificationChip(
                    'matched',
                    l10n.matched,
                    Colors.green,
                    matchedCount,
                    '✓',
                  ),
                  const SizedBox(width: 8),
                  _buildClassificationChip(
                    'mismatched',
                    l10n.mismatched,
                    Colors.orange,
                    mismatchedCount,
                    '!',
                  ),
                  const SizedBox(width: 8),
                  _buildClassificationChip(
                    'unregistered',
                    l10n.unregistered,
                    Colors.purple,
                    unregisteredCount,
                    '○',
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noTransactionsFound,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(
                            transaction.type == 'Buying'
                                ? l10n.buyingTransaction(transaction.product)
                                : l10n.sellingTransaction(transaction.product),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.customerLabel(
                                transaction.type == 'Buying' 
                                    ? transaction.sellerName 
                                    : transaction.buyerName
                              )),
                              Text(l10n.quantityAndPrice(
                                transaction.quantity,
                                transaction.pricePerUnit.toInt(),
                              )),
                              Text('${l10n.totalAmount}: \$${transaction.totalAmount.toStringAsFixed(2)}'),
                            ],
                          ),
                          trailing: _buildStatusChip(transaction.matched, l10n),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, AppLocalizations l10n) {
    Color color;
    String label;
    
    switch (status) {
      case 'matched':
        color = Colors.green;
        label = l10n.matched;
        break;
      case 'mismatched':
        color = Colors.orange;
        label = l10n.mismatched;
        break;
      case 'pending':
        color = Colors.purple;
        label = l10n.unregistered;
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }
} 
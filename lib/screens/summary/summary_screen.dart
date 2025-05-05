import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/supabase_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = context.read<AuthService>().currentUser;
      
      if (currentUser?.email != null) {
        final statistics = await context
            .read<SupabaseService>()
            .getTransactionStatistics(currentUser!.email!);
            
        if (mounted) {
          setState(() => _statistics = statistics);
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorLoadingStatistics(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.transactionStatistics,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildStatisticsCards(l10n),
            const SizedBox(height: 32),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.transactionStatusDistribution,
                      style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
                    const SizedBox(height: 24),
            SizedBox(
                      height: 250,
                      child: _buildTransactionChart(l10n),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.transactionAmounts,
                      style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
                    const SizedBox(height: 24),
            SizedBox(
                      height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (_statistics['totalAmount']?.toDouble() ?? 0) * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(l10n.buy),
                              );
                            case 1:
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(l10n.sell),
                              );
                            default:
                              return const Text('');
                          }
                        },
                                reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Text('\$${value.toInt()}'),
                                  );
                        },
                                reservedSize: 40,
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: _statistics['buyAmount']?.toDouble() ?? 0,
                          color: AppTheme.primaryColor,
                                  width: 40,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: _statistics['sellAmount']?.toDouble() ?? 0,
                          color: AppTheme.secondaryColor,
                                  width: 40,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(AppLocalizations l10n) {
    final total = _statistics['total'] ?? 0;
    final matched = _statistics['matched'] ?? 0;
    final mismatched = _statistics['mismatched'] ?? 0;
    final unregistered = _statistics['unregistered'] ?? 0;
    final totalAmount = _statistics['totalAmount'] ?? 0.0;

    // Calculate responsive childAspectRatio based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final childAspectRatio = screenWidth < 400 ? 1.2 : 1.5;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: childAspectRatio,
      children: [
        _buildStatCard(
          l10n.totalTransactions,
          total.toString(),
          Icons.receipt_long,
          Theme.of(context).colorScheme.primary,
        ),
        _buildStatCard(
          l10n.matchedTransactions,
          matched.toString(),
          Icons.check_circle,
          AppTheme.statusColors['matched']!,
        ),
        _buildStatCard(
          l10n.mismatchedTransactions,
          mismatched.toString(),
          Icons.error,
          AppTheme.statusColors['mismatched']!,
        ),
        _buildStatCard(
          l10n.unregisteredTransactions,
          unregistered.toString(),
          Icons.person_outline,
          AppTheme.statusColors['pending']!,
        ),
        _buildStatCard(
          l10n.totalAmount,
          '\$${totalAmount.toStringAsFixed(2)}',
          Icons.attach_money,
          Theme.of(context).colorScheme.secondary,
        ),
      ],
    );
  }

  Widget _buildTransactionChart(AppLocalizations l10n) {
    if (_statistics['total'] == null || _statistics['total'] == 0) {
      return Center(
        child: Text(
          l10n.noTransactionsYet,
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    final matched = _statistics['matched'] ?? 0;
    final mismatched = _statistics['mismatched'] ?? 0;
    final unregistered = _statistics['unregistered'] ?? 0;
    final total = matched + mismatched + unregistered;
    
    if (total == 0) {
      return Center(
        child: Text(
          l10n.noTransactionsYet,
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sections: [
          if (matched > 0)
            PieChartSectionData(
              value: matched.toDouble(),
              title: '${((matched / total) * 100).round()}%',
              color: AppTheme.statusColors['matched'],
              radius: 100,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (mismatched > 0)
            PieChartSectionData(
              value: mismatched.toDouble(),
              title: '${((mismatched / total) * 100).round()}%',
              color: AppTheme.statusColors['mismatched'],
              radius: 100,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (unregistered > 0)
            PieChartSectionData(
              value: unregistered.toDouble(),
              title: '${((unregistered / total) * 100).round()}%',
              color: AppTheme.statusColors['pending'],
              radius: 100,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 4),
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  width: constraints.maxWidth,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 
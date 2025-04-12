import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../auth/auth_screen.dart';
import '../products/products_screen.dart';
import '../customers/customers_screen.dart';
import '../reconciliation/reconciliation_screen.dart';
import '../summary/summary_screen.dart';
import '../profile/profile_screen.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false;

  final List<Widget> _screens = [
    const ProductsScreen(),
    const CustomersScreen(),
    const ReconciliationScreen(),
    const SummaryScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    try {
      await context.read<AuthService>().signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'Reconciliation',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Summary',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
} 
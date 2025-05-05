import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../auth/auth_screen.dart';
import '../products/products_screen.dart';
import '../customers/customers_screen.dart';
import '../reconciliation/reconciliation_screen.dart';
import '../summary/summary_screen.dart';
import '../profile/profile_screen.dart';
import '../../theme/app_theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';

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
        setState(() => _isLoading = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to sign out. Please try again.')),
        );
      }
    }
  }

  void _toggleDarkMode(bool value) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.toggleTheme();
  }

  void _toggleLanguage() {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    languageProvider.toggleLanguage();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isAmharic = languageProvider.locale.languageCode == 'am';
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 35,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<String?>(
                      future: _getUserName(),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        );
                      }
                    ),
                    const SizedBox(height: 5),
                    FutureBuilder<String?>(
                      future: _getUserEmail(),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? 'email@example.com',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        );
                      }
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(l10n.profile),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: Text(l10n.settings),
                    onTap: () {
                      Navigator.pop(context);
                      _showSettingsDialog();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.exit_to_app),
                    title: const Text('Logout'),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Made and maintained by Biruk G.Jember",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.inventory),
            label: l10n.products,
            tooltip: l10n.products,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people),
            label: l10n.customers,
            tooltip: l10n.customers,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long),
            label: l10n.reconciliation,
            tooltip: l10n.reconciliation,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart),
            label: l10n.summary,
            tooltip: l10n.summary,
          ),
        ],
      ),
    );
  }

  Future<String?> _getUserName() async {
    try {
      final profile = await context.read<AuthService>().getCurrentUser();
      return profile?.username;
    } catch (e) {
      return null;
    }
  }

  Future<String?> _getUserEmail() async {
    try {
      final profile = await context.read<AuthService>().getCurrentUser();
      return profile?.email;
    } catch (e) {
      return null;
    }
  }

  void _showSettingsDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final l10n = AppLocalizations.of(context)!;
            final isAmharic = languageProvider.locale.languageCode == 'am';
            
            return AlertDialog(
              title: Text(l10n.settings),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dark Mode Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.darkMode),
                      Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          _toggleDarkMode(value);
                          setState(() {}); // Refresh dialog UI
                        },
                        activeColor: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Language Selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.language),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isAmharic ? l10n.english : l10n.amharic),
                          Switch(
                            value: isAmharic,
                            onChanged: (value) async {
                              await languageProvider.toggleLanguage();
                              setState(() {}); // Refresh dialog UI
                            },
                            activeColor: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.close),
                ),
              ],
            );
          }
        );
      },
    );
  }
} 
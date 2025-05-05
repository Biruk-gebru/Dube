import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/customer.dart';
import '../../models/profile.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Customer> _customers = [];
  List<Profile> _allProfiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      final supabaseService = context.read<SupabaseService>();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser != null) {
        final customers = await supabaseService.getCustomers(currentUser.id);
        final profiles = await supabaseService.getAllProfiles();
        
        setState(() {
          _customers = customers;
          _allProfiles = profiles;
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

  Future<void> _addCustomer(Profile profile) async {
    try {
      final authService = context.read<AuthService>();
      final supabaseService = context.read<SupabaseService>();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser != null) {
        final customer = Customer(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: profile.username,
          userId: currentUser.id,
        );
        
        await supabaseService.addCustomer(customer);
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.primary,
            child: const TabBar(
            tabs: [
                Tab(
                  icon: Tooltip(
                    message: 'My Customers',
                    child: Icon(Icons.people),
                  ),
                ),
                Tab(
                  icon: Tooltip(
                    message: 'All Users',
                    child: Icon(Icons.person_search),
                  ),
                ),
            ],
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // My Customers Tab
                ListView.builder(
                  itemCount: _customers.length,
                  itemBuilder: (context, index) {
                    final customer = _customers[index];
                    return ListTile(
                      title: Text(customer.name),
                    );
                  },
                ),
                // All Users Tab
                ListView.builder(
                  itemCount: _allProfiles.length,
                  itemBuilder: (context, index) {
                    final profile = _allProfiles[index];
                    final isCustomer = _customers.any(
                      (c) => c.name == profile.username,
                    );
                    
                    return ListTile(
                      title: Text(profile.username),
                      trailing: isCustomer
                          ? const Icon(Icons.check, color: Colors.green)
                          : TextButton(
                              onPressed: () => _addCustomer(profile),
                              child: const Text('Add'),
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:product_catalogue/providers/product_provider.dart';
import 'package:product_catalogue/screens/product/product_detail_screen.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../auth/change_password_screen.dart';

// HomeScreen is the main landing page after login, showing a welcome message and navigation options.

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ScrollController to manage scrolling behavior, especially for lists or grids
  final ScrollController _scrollController = ScrollController();

  // Initialize state and set up listeners for scroll events to implement infinite scrolling
  @override
  void initState() {
    super.initState();

    // Load the first page of products after the first frame is rendered to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFirstPage());

    // Add a listener to the ScrollController to detect when the user scrolls near the bottom of the list
    _scrollController.addListener(_onScroll);
  }

  // Dispose the ScrollController to free up resources when the widget is removed from the widget tree
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Load the first page of products when the screen is initialized
  void _loadFirstPage() {
    final userId = context.read<AuthProvider>().user?.uid;
    if (userId != null) {
      context.read<ProductProvider>().loadProducts(userId);
    }
  }

  // Listener for scroll events to implement infinite scrolling
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final userId = context.read<AuthProvider>().user?.uid;
      if (userId != null) {
        context.read<ProductProvider>().loadMoreProducts(userId);
      }
    }
  }

  // Confirm logout with a dialog and clear product state before signing out
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Clear product state before signing out
      context.read<ProductProvider>().clear();
      await context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
        actions: [
          // Overflow menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'change password') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                );
              } else if (value == 'logout') {
                _confirmLogout();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'change password',
                child: Row(
                  children: [
                    Icon(Icons.security, size: 20),
                    SizedBox(width: 8),
                    Text('Change Password'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: AppTheme.error),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: AppTheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      // Body of Homescreen
      body: RefreshIndicator(
        // Pull-to-refresh reloads the first page
        onRefresh: () async => _loadFirstPage(),
        child: _buildBody(productProvider, auth),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductFormScreen()),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  // Builds the main body of the HomeScreen based on the product provider's state
  Widget _buildBody(ProductProvider provider, AuthProvider auth) {
    // Full-screen loader on initial load
    if (provider.status == ProductStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Full-screen error
    if (provider.status == ProductStatus.error && provider.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(provider.errorMessage ?? 'Something went wrong'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFirstPage,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (provider.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No products yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first product',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Welcome message
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Hello, ${auth.user?.displayName ?? 'there'} 👋',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        // Product grid
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate((context, index) {
              final product = provider.products[index];
              return ProductCard(
                product: product,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(product: product),
                  ),
                ),
              );
            }, childCount: provider.products.length),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 columns
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72, // Portrait card ratio
            ),
          ),
        ),

        // Loading indicator for infinite scroll
        if (provider.isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),

        // Message when all products are loaded
        if (!provider.hasMore && provider.products.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'All products loaded',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import 'login_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> with SingleTickerProviderStateMixin {
  List<Product> _products = [];
  List<Product> _recommendations = [];
  bool _isLoading = true;
  String? _searchQuery;
  String? _selectedCategory;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      final products = await apiService.getProducts(
        search: _searchQuery,
        category: _selectedCategory,
      );
      final recommendations = await apiService.getRecommendations();

      if (mounted) {
        setState(() {
          _products = products;
          _recommendations = recommendations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _logout() async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B46C1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.store,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Smart Cashier',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF6B46C1)),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF6B46C1)),
                onPressed: () {
                  // Navigate to cart
                },
                tooltip: 'Cart',
              ),
              if (cartProvider.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${cartProvider.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B46C1)),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                color: const Color(0xFF6B46C1),
                child: CustomScrollView(
                  slivers: [
                    // Search and Filter Section
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Search Field
                            TextField(
                              decoration: InputDecoration(
                                hintText: 'Search products...',
                                hintStyle: TextStyle(color: Colors.grey.shade400),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Color(0xFF6B46C1),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              onChanged: (value) {
                                _searchQuery = value.isEmpty ? null : value;
                                _loadData();
                              },
                            ),
                            const SizedBox(height: 16),
                            // Category Filter
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  hint: Text(
                                    'All Categories',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                  value: _selectedCategory,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Color(0xFF6B46C1),
                                  ),
                                  items: ['Food', 'Drink', 'Dessert'].map((category) {
                                    return DropdownMenuItem(
                                      value: category,
                                      child: Text(
                                        category,
                                        style: const TextStyle(
                                          color: Color(0xFF1F2937),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() => _selectedCategory = value);
                                    _loadData();
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Recommendations Section
                    if (_recommendations.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 24,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF6B46C1), Color(0xFF8B5CF6)],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Recommended for You',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const Icon(
                                Icons.star,
                                color: Color(0xFFF59E0B),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 140,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _recommendations.length,
                            itemBuilder: (context, index) {
                              final product = _recommendations[index];
                              return Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                          gradient: LinearGradient(
                                            colors: product.quantity > 0
                                                ? [const Color(0xFF6B46C1), const Color(0xFF8B5CF6)]
                                                : [Colors.grey.shade300, Colors.grey.shade400],
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.star,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        children: [
                                          Text(
                                            product.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Color(0xFF1F2937),
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Rp ${product.price.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              color: Color(0xFF6B46C1),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 28,
                                            child: ElevatedButton(
                                              onPressed: product.quantity > 0
                                                  ? () => cartProvider.addItem(product)
                                                  : null,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: product.quantity > 0
                                                    ? const Color(0xFF6B46C1)
                                                    : Colors.grey,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                padding: EdgeInsets.zero,
                                                textStyle: const TextStyle(fontSize: 10),
                                              ),
                                              child: const Text('Add'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],

                    // Products Grid
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = _products[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Image
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                        gradient: LinearGradient(
                                          colors: product.quantity > 0
                                              ? [const Color(0xFFEDE9FE), const Color(0xFFF3F4F6)]
                                              : [Colors.grey.shade200, Colors.grey.shade300],
                                        ),
                                      ),
                                      child: product.imagePath != null
                                          ? ClipRRect(
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                              child: Image.network(
                                                'http://127.0.0.1:8000/storage/${product.imagePath}',
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.image_not_supported,
                                                    size: 40,
                                                    color: Colors.grey,
                                                  );
                                                },
                                              ),
                                            )
                                          : const Icon(
                                              Icons.inventory_2,
                                              size: 40,
                                              color: Color(0xFF6B46C1),
                                            ),
                                    ),
                                  ),
                                  // Product Info
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Color(0xFF1F2937),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Rp ${product.price.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              color: Color(0xFF6B46C1),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.inventory,
                                                size: 12,
                                                color: product.quantity > 0 ? Colors.green : Colors.red,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${product.quantity}',
                                                style: TextStyle(
                                                  color: product.quantity > 0 ? Colors.green : Colors.red,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 32,
                                            child: ElevatedButton(
                                              onPressed: product.quantity > 0
                                                  ? () => cartProvider.addItem(product)
                                                  : null,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: product.quantity > 0
                                                    ? const Color(0xFF6B46C1)
                                                    : Colors.grey,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                padding: EdgeInsets.zero,
                                                elevation: 0,
                                              ),
                                              child: Text(
                                                product.quantity > 0 ? 'Add to Cart' : 'Out of Stock',
                                                style: const TextStyle(fontSize: 11),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          childCount: _products.length,
                        ),
                      ),
                    ),

                    // Empty State
                    if (_products.isEmpty && !_isLoading)
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No products found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your search or filters',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
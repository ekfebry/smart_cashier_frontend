import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/sidebar_provider.dart';
import '../widgets/sidebar_widget.dart';
import 'login_screen.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'checkout_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class ProductListScreen extends StatefulWidget {
  final Category? category;

  const ProductListScreen({super.key, this.category});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> with SingleTickerProviderStateMixin {
  List<Product> _products = [];
  List<Product> _recommendations = [];
  List<Category> _sidebarCategories = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _searchQuery;
  String? _selectedCategory;
  List<String> _selectedTags = [];
  final List<String> _categories = ['All', 'Makanan', 'Minuman', 'Dessert'];
  final List<String> _availableTags = ['Spicy', 'Vegetarian', 'Vegan', 'Gluten-Free', 'Halal', 'Popular'];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showFilters = false;
  RangeValues _priceRange = const RangeValues(0, 100000);
  bool _inStockOnly = false;
  String _sortBy = 'name';
  String _sortOrder = 'asc';

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
    if (widget.category != null) {
      _selectedCategory = widget.category!.name;
    }
    _loadData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();

      // Load products and recommendations in parallel
      final results = await Future.wait([
        apiService.getProducts(
          search: _searchQuery,
          category: _selectedCategory,
          minPrice: _priceRange.start > 0 ? _priceRange.start : null,
          maxPrice: _priceRange.end < 100000 ? _priceRange.end : null,
          tags: _selectedTags.isNotEmpty ? _selectedTags : null,
          sortBy: _sortBy,
          sortOrder: _sortOrder,
          inStock: _inStockOnly,
        ),
        apiService.getRecommendations(),
        apiService.getAllCategories(),
      ]);

      if (mounted) {
        setState(() {
          _products = results[0] as List<Product>;
          _recommendations = results[1] as List<Product>;
          _sidebarCategories = results[2] as List<Category>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to load data: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadData,
            ),
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

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 4; // Large desktop
    if (width >= 900) return 3;  // Desktop
    if (width >= 600) return 2;  // Tablet
    return 1; // Mobile
  }

  void _openDrawer(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6B46C1), Color(0xFF8B5CF6)],
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.store,
                    color: Colors.white,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Smart Cashier',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Navigation Items
            _buildDrawerItem(
              context,
              icon: Icons.dashboard,
              label: 'Dashboard',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.search,
              label: 'Browse Products',
              isSelected: true,
              onTap: () => Navigator.pop(context),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.receipt_long,
              label: 'Orders',
              onTap: () => Navigator.pop(context),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.person,
              label: 'Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            // Categories
            if (_sidebarCategories.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                      'Categories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
              ..._sidebarCategories.map((category) => _buildCategoryDrawerItem(context, category)),
            ],
            const Spacer(),
            // Logout Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _logout();
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF6B46C1) : Colors.grey.shade600,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? const Color(0xFF6B46C1) : Colors.grey.shade600,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: const Color(0xFF6B46C1).withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildCategoryDrawerItem(BuildContext context, Category category) {
    return ListTile(
      leading: const Icon(
        Icons.category,
        color: Color(0xFF6B46C1),
      ),
      title: Text(
        category.name,
        style: const TextStyle(
          color: Color(0xFF1F2937),
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductListScreen(category: category),
          ),
        );
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(context),
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * 50)),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value * 0.7,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Image skeleton
                        Expanded(
                          flex: 3,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              color: Colors.grey.shade200,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.image,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        // Advanced Filters Panel
                        if (_showFilters) ...[
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Price Range Filter
                                const Text(
                                  'Price Range',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                RangeSlider(
                                  values: _priceRange,
                                  min: 0,
                                  max: 100000,
                                  divisions: 100,
                                  labels: RangeLabels(
                                    'Rp ${_priceRange.start.toInt()}',
                                    'Rp ${_priceRange.end.toInt()}',
                                  ),
                                  inactiveColor: Colors.grey.shade300,
                                  onChanged: (RangeValues values) {
                                    setState(() => _priceRange = values);
                                  },
                                  onChangeEnd: (_) => _loadData(),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Rp ${_priceRange.start.toInt()}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'Rp ${_priceRange.end.toInt()}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
 
                                // Stock Filter
                                Row(
                                  children: [
                                    const Text(
                                      'In Stock Only',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    const Spacer(),
                                    Switch(
                                      value: _inStockOnly,
                                      activeThumbColor: const Color(0xFF6B46C1),
                                      onChanged: (value) {
                                        setState(() => _inStockOnly = value);
                                        _loadData();
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
 
                                // Sort Options
                                const Text(
                                  'Sort By',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        initialValue: _sortBy,
                                        decoration: InputDecoration(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                        items: const [
                                          DropdownMenuItem(value: 'name', child: Text('Name')),
                                          DropdownMenuItem(value: 'price', child: Text('Price')),
                                          DropdownMenuItem(value: 'stock_quantity', child: Text('Stock')),
                                          DropdownMenuItem(value: 'created_at', child: Text('Newest')),
                                        ],
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() => _sortBy = value);
                                            _loadData();
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.white,
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          _sortOrder == 'asc' ? Icons.arrow_upward : Icons.arrow_downward,
                                          color: const Color(0xFF6B46C1),
                                        ),
                                        onPressed: () {
                                          setState(() => _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc');
                                          _loadData();
                                        },
                                        tooltip: _sortOrder == 'asc' ? 'Ascending' : 'Descending',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Content skeleton
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title skeleton
                                Container(
                                  height: 16,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Price skeleton
                                Container(
                                  height: 18,
                                  width: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const Spacer(),
                                // Button skeleton
                                Container(
                                  height: 44,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          childCount: 6, // Show 6 skeleton cards
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Failed to load products. Please check your connection.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B46C1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    // List of available asset images
    const assetImages = [
      'air_mineral.jpeg',
      'ayam_bakar.jpg',
      'ayam_teriyaki.jpg',
      'bakso.jpg',
      'bebek_goreng.jpeg',
      'capcay.jpeg',
      'cheesecake.jpg',
      'chicken_katsu.jpeg',
      'es_teh.jpeg',
      'ice_cream.jpeg',
      'ikan_bakar.jpeg',
      'jus_jeruk.jpg',
      'kelapa_muda.jpeg',
      'kentang_goreng.jpeg',
      'kopi_susu.jpeg',
      'kopi.jpeg',
      'lemon_tea.jpeg',
      'mango_dessert.jpeg',
      'mix_platter.jpeg',
      'nasi_goreng.jpeg',
      'puding.jpeg',
      'rawon.jpeg',
      'sate.jpeg',
      'strawberry_cake.jpeg',
      'tiramissu.webp',
    ];

    Widget imageWidget;

    if (product.imagePath != null && assetImages.contains(product.imagePath)) {
      // Load from assets
      imageWidget = Image.asset(
        'assets/images/${product.imagePath}',
        fit: BoxFit.cover,
        width: double.infinity,
        semanticLabel: 'Image of ${product.name}',
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultImage();
        },
      );
    } else if (product.imagePath != null) {
      // Load from network
      imageWidget = Image.network(
        'http://127.0.0.1:8000/storage/${product.imagePath}',
        fit: BoxFit.cover,
        width: double.infinity,
        semanticLabel: 'Image of ${product.name}',
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B46C1)),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultImage();
        },
      );
    } else {
      // No image available
      imageWidget = _buildDefaultImage();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: imageWidget,
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      color: const Color(0xFFEDE9FE),
      child: const Icon(
        Icons.restaurant_menu,
        size: 40,
        color: Color(0xFF6B46C1),
      ),
    );
  }

  Widget _buildRecommendationImage(Product product) {
    const assetImages = [
      'air_mineral.jpeg',
      'ayam_bakar.jpg',
      'ayam_teriyaki.jpg',
      'bakso.jpg',
      'bebek_goreng.jpeg',
      'capcay.jpeg',
      'cheesecake.jpg',
      'chicken_katsu.jpeg',
      'es_teh.jpeg',
      'ice_cream.jpeg',
      'ikan_bakar.jpeg',
      'jus_jeruk.jpg',
      'kelapa_muda.jpeg',
      'kentang_goreng.jpeg',
      'kopi_susu.jpeg',
      'kopi.jpeg',
      'lemon_tea.jpeg',
      'mango_dessert.jpeg',
      'mix_platter.jpeg',
      'nasi_goreng.jpeg',
      'puding.jpeg',
      'rawon.jpeg',
      'sate.jpeg',
      'strawberry_cake.jpeg',
      'tiramissu.webp',
    ];

    if (assetImages.contains(product.imagePath)) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Image.asset(
          'assets/images/${product.imagePath}',
          fit: BoxFit.cover,
          width: double.infinity,
          semanticLabel: 'Image of ${product.name}',
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.star,
              color: Colors.white,
              size: 32,
            );
          },
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Image.network(
          'http://127.0.0.1:8000/storage/${product.imagePath}',
          fit: BoxFit.cover,
          width: double.infinity,
          semanticLabel: 'Image of ${product.name}',
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.star,
              color: Colors.white,
              size: 32,
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final sidebarProvider = Provider.of<SidebarProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768; // Mobile/tablet breakpoint

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
          if (!isMobile) ...[
            IconButton(
              icon: Icon(sidebarProvider.isOpen ? Icons.menu_open : Icons.menu),
              onPressed: () => sidebarProvider.toggle(),
              tooltip: 'Toggle Sidebar',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _openDrawer(context),
              tooltip: 'Menu',
            ),
          ],
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
                tooltip: 'Cart',
              ),
              if (orderProvider.totalItems > 0)
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
                      '${orderProvider.totalItems}',
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
      drawer: isMobile ? _buildDrawer(context) : null,
      floatingActionButton: orderProvider.hasItems
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                );
              },
              backgroundColor: const Color(0xFF6B46C1),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.shopping_cart_checkout),
              label: Text('Buat Pesanan (${orderProvider.totalItems})'),
              elevation: 4,
            )
          : null,
      body: Row(
        children: [
          if (!isMobile) SidebarWidget(
            selectedIndex: 1, // Product list
            onItemSelected: (index) {
              if (index == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              } else if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              }
              // For index 1, stay
              // For index 2, perhaps navigate to orders if implemented
            },
            categories: _sidebarCategories,
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: const Color(0xFF6B46C1),
                child: _isLoading
                    ? CustomScrollView(
                        slivers: [_buildSkeletonLoader()],
                      )
                    : _errorMessage != null
                        ? CustomScrollView(
                            slivers: [_buildErrorState()],
                          )
                        : CustomScrollView(
                  slivers: [
                    // Search and Filter Section
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Search Field with Enhanced Design
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6B46C1).withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search delicious food...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 16,
                                  ),
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(12),
                                    child: const Icon(
                                      Icons.search,
                                      color: Color(0xFF6B46C1),
                                      size: 24,
                                    ),
                                  ),
                                  suffixIcon: Container(
                                    margin: const EdgeInsets.all(8),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: _showFilters
                                            ? const Color(0xFF6B46C1)
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          _showFilters ? Icons.filter_list_off : Icons.filter_list,
                                          color: _showFilters ? Colors.white : const Color(0xFF6B46C1),
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() => _showFilters = !_showFilters);
                                        },
                                      ),
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF6B46C1),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF1F2937),
                                ),
                                onChanged: (value) {
                                  _searchQuery = value.isEmpty ? null : value;
                                  _loadData();
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Advanced Filters
                            if (_showFilters) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Price Range',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            decoration: InputDecoration(
                                              hintText: 'Min price',
                                              prefixText: 'Rp ',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                            keyboardType: TextInputType.number,
                                            controller: TextEditingController(text: _priceRange.start > 0 ? _priceRange.start.toStringAsFixed(0) : ''),
                                            onChanged: (value) {
                                              final parsed = value.isEmpty ? 0.0 : double.tryParse(value) ?? 0.0;
                                              setState(() {
                                                _priceRange = RangeValues(parsed.clamp(0, _priceRange.end), _priceRange.end);
                                              });
                                              _loadData();
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextField(
                                            decoration: InputDecoration(
                                              hintText: 'Max price',
                                              prefixText: 'Rp ',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                            keyboardType: TextInputType.number,
                                            controller: TextEditingController(text: _priceRange.end < 100000 ? _priceRange.end.toStringAsFixed(0) : ''),
                                            onChanged: (value) {
                                              final parsed = value.isEmpty ? 100000.0 : double.tryParse(value) ?? 100000.0;
                                              setState(() {
                                                _priceRange = RangeValues(_priceRange.start, parsed.clamp(_priceRange.start, 100000));
                                              });
                                              _loadData();
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Tags',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _availableTags.map((tag) {
                                        final isSelected = _selectedTags.contains(tag);
                                        return FilterChip(
                                          label: Text(
                                            tag,
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : const Color(0xFF6B46C1),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          selected: isSelected,
                                          onSelected: (selected) {
                                            setState(() {
                                              if (selected) {
                                                _selectedTags.add(tag);
                                              } else {
                                                _selectedTags.remove(tag);
                                              }
                                            });
                                            _loadData();
                                          },
                                          backgroundColor: Colors.white,
                                          selectedColor: const Color(0xFF6B46C1),
                                          checkmarkColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                            side: BorderSide(
                                              color: isSelected ? const Color(0xFF6B46C1) : Colors.grey.shade300,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 12),
                                    Center(
                                      child: TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _priceRange = const RangeValues(0, 100000);
                                            _selectedTags.clear();
                                          });
                                          _loadData();
                                        },
                                        icon: const Icon(Icons.clear, color: Colors.red),
                                        label: const Text(
                                          'Clear Filters',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Enhanced Category Tabs
                            Container(
                              height: 56,
                              margin: const EdgeInsets.only(top: 16),
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _categories.length,
                                itemBuilder: (context, index) {
                                  final category = _categories[index];
                                  final isSelected = (_selectedCategory == null && category == 'All') ||
                                                    (_selectedCategory == category);

                                  return TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.8, end: 1.0),
                                    duration: Duration(milliseconds: 200 + (index * 50)),
                                    curve: Curves.elasticOut,
                                    builder: (context, scale, child) {
                                      return Transform.scale(
                                        scale: scale,
                                        child: Container(
                                          margin: const EdgeInsets.only(right: 12),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            child: FilterChip(
                                              label: Row(
                                                children: [
                                                  Icon(
                                                    category == 'All' ? Icons.grid_view :
                                                    category == 'Makanan' ? Icons.restaurant :
                                                    category == 'Minuman' ? Icons.local_drink :
                                                    Icons.icecream,
                                                    size: 16,
                                                    color: isSelected ? Colors.white : const Color(0xFF6B46C1),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    category,
                                                    style: TextStyle(
                                                      color: isSelected ? Colors.white : const Color(0xFF6B46C1),
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              selected: isSelected,
                                              onSelected: (selected) {
                                                setState(() {
                                                  _selectedCategory = category == 'All' ? null : category;
                                                });
                                                _loadData();
                                              },
                                              backgroundColor: Colors.grey.shade50,
                                              selectedColor: const Color(0xFF6B46C1),
                                              checkmarkColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(25),
                                                side: BorderSide(
                                                  color: isSelected
                                                      ? const Color(0xFF6B46C1)
                                                      : Colors.grey.shade300,
                                                  width: isSelected ? 2 : 1,
                                                ),
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              elevation: isSelected ? 4 : 0,
                                              shadowColor: const Color(0xFF6B46C1).withValues(alpha: 0.3),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Recommendations Section
                    if (_recommendations.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xFF6B46C1), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6B46C1).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.recommend,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Recommended for You',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Personalized picks based on your preferences',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 180,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _recommendations.length,
                            itemBuilder: (context, index) {
                              final product = _recommendations[index];
                              return TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                duration: Duration(milliseconds: 400 + (index * 150)),
                                curve: Curves.elasticOut,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: child,
                                  );
                                },
                                child: Container(
                                  width: 140,
                                  margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Stack(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                                gradient: LinearGradient(
                                                  colors: product.quantity > 0
                                                      ? [const Color(0xFF6B46C1), const Color(0xFF8B5CF6)]
                                                      : [Colors.grey.shade300, Colors.grey.shade400],
                                                ),
                                              ),
                                              child: product.imagePath != null
                                                  ? _buildRecommendationImage(product)
                                                  : const Icon(
                                                      Icons.star,
                                                      color: Colors.white,
                                                      size: 32,
                                                    ),
                                            ),
                                            if (product.quantity > 0)
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.withValues(alpha: 0.9),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.check,
                                                    color: Colors.white,
                                                    size: 12,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            children: [
                                              Text(
                                                product.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                  color: Color(0xFF1F2937),
                                                  height: 1.2,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Rp ${product.price.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  color: Color(0xFF6B46C1),
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const Spacer(),
                                              SizedBox(
                                                width: double.infinity,
                                                height: 32,
                                                child: ElevatedButton(
                                                  onPressed: product.quantity > 0
                                                      ? () {
                                                          orderProvider.addItem(product);
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text('${product.name} added!'),
                                                              duration: const Duration(seconds: 2),
                                                              backgroundColor: const Color(0xFF6B46C1),
                                                              behavior: SnackBarBehavior.floating,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(12),
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      : null,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: product.quantity > 0
                                                        ? const Color(0xFF6B46C1)
                                                        : Colors.grey.shade400,
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    elevation: product.quantity > 0 ? 3 : 0,
                                                    shadowColor: const Color(0xFF6B46C1).withValues(alpha: 0.3),
                                                    padding: EdgeInsets.zero,
                                                  ),
                                                  child: Text(
                                                    product.quantity > 0 ? 'Add' : 'Out',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],

                    // Responsive Products Grid
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _getCrossAxisCount(context),
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          childAspectRatio: 0.75,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = _products[index];
                            return TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 300 + (index * 100)),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 50 * (1 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: child,
                                  ),
                                );
                              },
                              child: Card(
                                elevation: 0,
                                margin: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) =>
                                            ProductDetailScreen(product: product),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          );
                                        },
                                        transitionDuration: const Duration(milliseconds: 300),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white,
                                          Colors.grey.shade50.withValues(alpha: 0.3),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Product Image with Overlay
                                        Expanded(
                                          flex: 3,
                                          child: Stack(
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                                  gradient: LinearGradient(
                                                    colors: product.quantity > 0
                                                        ? [const Color(0xFFEDE9FE), const Color(0xFFF3F4F6)]
                                                        : [Colors.grey.shade200, Colors.grey.shade300],
                                                  ),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                                  child: _buildProductImage(product),
                                                ),
                                              ),
                                              // Stock Badge
                                              Positioned(
                                                top: 12,
                                                right: 12,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: product.quantity > 0
                                                        ? Colors.green.withValues(alpha: 0.9)
                                                        : Colors.red.withValues(alpha: 0.9),
                                                    borderRadius: BorderRadius.circular(12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withValues(alpha: 0.1),
                                                        blurRadius: 4,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        product.quantity > 0 ? Icons.check_circle : Icons.cancel,
                                                        size: 14,
                                                        color: Colors.white,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        product.quantity > 0 ? '${product.quantity} left' : 'Out of stock',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              // Favorite Button
                                              Positioned(
                                                top: 12,
                                                left: 12,
                                                child: Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withValues(alpha: 0.9),
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withValues(alpha: 0.1),
                                                        blurRadius: 4,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: IconButton(
                                                    icon: Icon(
                                                      Icons.favorite_border,
                                                      size: 16,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                    onPressed: () {
                                                      // TODO: Implement favorite functionality
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text('Favorites feature coming soon!'),
                                                          duration: Duration(seconds: 2),
                                                        ),
                                                      );
                                                    },
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Product Info
                                        Expanded(
                                          flex: 2,
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Product Name
                                                Text(
                                                  product.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 16,
                                                    color: Color(0xFF1F2937),
                                                    height: 1.2,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 8),
                                                // Price with discount indicator
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Rp ${product.price.toStringAsFixed(0)}',
                                                      style: const TextStyle(
                                                        color: Color(0xFF6B46C1),
                                                        fontWeight: FontWeight.w800,
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    // Rating indicator (mock)
                                                    Row(
                                                      children: List.generate(5, (starIndex) {
                                                        return Icon(
                                                          Icons.star,
                                                          size: 12,
                                                          color: starIndex < 4 ? Colors.amber : Colors.grey.shade300,
                                                        );
                                                      }),
                                                    ),
                                                  ],
                                                ),
                                                const Spacer(),
                                                // Add to Cart Button
                                                SizedBox(
                                                  width: double.infinity,
                                                  height: 44,
                                                  child: AnimatedContainer(
                                                    duration: const Duration(milliseconds: 200),
                                                    child: ElevatedButton(
                                                      onPressed: product.quantity > 0
                                                          ? () {
                                                              orderProvider.addItem(product);
                                                              // Add haptic feedback
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(
                                                                  content: Text('${product.name} added to cart!'),
                                                                  duration: const Duration(seconds: 2),
                                                                  backgroundColor: const Color(0xFF6B46C1),
                                                                  behavior: SnackBarBehavior.floating,
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.circular(12),
                                                                  ),
                                                                  action: SnackBarAction(
                                                                    label: 'View Cart',
                                                                    textColor: Colors.white,
                                                                    onPressed: () {
                                                                      Navigator.push(
                                                                        context,
                                                                        MaterialPageRoute(builder: (_) => const CartScreen()),
                                                                      );
                                                                    },
                                                                  ),
                                                                ),
                                                              );
                                                            }
                                                          : null,
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: product.quantity > 0
                                                            ? const Color(0xFF6B46C1)
                                                            : Colors.grey.shade400,
                                                        foregroundColor: Colors.white,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        elevation: product.quantity > 0 ? 4 : 0,
                                                        shadowColor: const Color(0xFF6B46C1).withValues(alpha: 0.3),
                                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(
                                                            product.quantity > 0 ? Icons.add_shopping_cart : Icons.block,
                                                            size: 18,
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Text(
                                                            product.quantity > 0 ? 'Add to Cart' : 'Out of Stock',
                                                            style: const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
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
          ),
        ],
      ),
    );
  }
}

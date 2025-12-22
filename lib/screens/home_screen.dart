import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/sidebar_provider.dart';
import '../widgets/sidebar_widget.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'checkout_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<Product> _products = [];
  List<Product> _recommendations = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();

      // Load products with fallback
      List<Product> products = [];
      try {
        products = await apiService.getProducts(search: _searchQuery, category: _selectedCategory);
      } catch (e) {
        debugPrint('Failed to load products: $e');
        products = [
          Product(
            id: 1,
            name: 'Mock Product 1',
            description: 'Mock description',
            price: 10.0,
            category: 'Mock Category',
            imagePath: null,
            stockQuantity: 100,
          ),
          Product(
            id: 2,
            name: 'Mock Product 2',
            description: 'Mock description 2',
            price: 15.0,
            category: 'Mock Category',
            imagePath: null,
            stockQuantity: 50,
          ),
        ];
      }

      // Load recommendations with fallback
      List<Product> recommendations = [];
      try {
        recommendations = await apiService.getRecommendations();
      } catch (e) {
        debugPrint('Failed to load recommendations: $e');
        recommendations = [];
      }

      // Load categories with fallback
      List<Category> categories = [];
      try {
        categories = await apiService.getAllCategories();
      } catch (e) {
        debugPrint('Failed to load categories: $e');
        categories = [];
      }

      if (mounted) {
        setState(() {
          _products = products;
          _recommendations = recommendations;
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Widget _buildQuantityControl(Product product, OrderProvider orderProvider, {double height = 36.0}) {
    final quantity = orderProvider.getQuantity(product);
    final isSelected = orderProvider.isSelected(product);

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF6B46C1) : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: product.quantity > 0
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Minus button
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF6B46C1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {
                      orderProvider.decrementQuantity(product);
                    },
                    icon: const Icon(
                      Icons.remove,
                      color: Colors.white,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Quantity display
                Text(
                  quantity > 0 ? '$quantity' : '0',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(width: 16),
                // Plus button
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF6B46C1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {
                      if (quantity == 0) {
                        orderProvider.addItem(product);
                      } else {
                        orderProvider.incrementQuantity(product);
                      }
                    },
                    icon: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: Text(
                'Out of Stock',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }

  void _createOrder() {
    // Navigate to checkout
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CheckoutScreen(),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 4;
    if (width >= 900) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  Widget _getProductImage(String? imagePath) {
    const assetImages = [
      'ayam_bakar.jpg',
      'ayam_teriyaki.jpg',
      'bakso.jpg',
      'es_teh.jpeg',
      'jus_jeruk.jpg',
      'nasi_goreng.jpeg',
      'air_mineral.jpeg',
      'bebek_goreng.jpeg',
      'capcay.jpeg',
      'cheesecake.jpg',
      'chicken_katsu.jpeg',
      'ice_cream.jpeg',
      'ikan_bakar.jpeg',
      'kelapa_muda.jpeg',
      'kentang_goreng.jpeg',
      'kopi_susu.jpeg',
      'kopi.jpeg',
      'lemon_tea.jpeg',
      'mango_dessert.jpeg',
      'mix_platter.jpeg',
      'puding.jpeg',
      'rawon.jpeg',
      'sate.jpeg',
      'strawberry_cake.jpeg',
      'tiramissu.webp',
    ];

    Widget imageWidget;

    if (imagePath != null && assetImages.contains(imagePath)) {
      imageWidget = Image.asset(
        'assets/images/${imagePath}',
        fit: BoxFit.cover,
        width: double.infinity,
        semanticLabel: 'Image of product',
        errorBuilder: (context, error, stackTrace) {
          return _getFallbackImage();
        },
      );
    } else {
      imageWidget = _getFallbackImage();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: imageWidget,
    );
  }

  Widget _getFallbackImage() {
    return Container(
      color: const Color(0xFFEDE9FE),
      child: const Icon(
        Icons.restaurant_menu,
        color: Color(0xFF6B46C1),
        size: 40,
      ),
    );
  }

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final sidebarProvider = Provider.of<SidebarProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) => orderProvider.hasItems
            ? FloatingActionButton(
                onPressed: _createOrder,
                backgroundColor: const Color(0xFF6B46C1),
                child: const Icon(Icons.arrow_forward, color: Colors.white),
                tooltip: 'Proceed to Checkout',
              )
            : const SizedBox.shrink(),
      ),
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
            icon: Icon(sidebarProvider.isOpen ? Icons.menu_open : Icons.menu),
            onPressed: () => sidebarProvider.toggle(),
            tooltip: 'Toggle Sidebar',
          ),
          // Smart cashier doesn't use traditional cart
        ],
      ),
      body: Row(
        children: [
          SidebarWidget(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            categories: _categories,
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B46C1)),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Enhanced Search Section
                          Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF6B46C1), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6B46C1).withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Search Header
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.search,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Find Your Favorite Food',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Search from our delicious menu',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                // Enhanced Search Bar
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Search for delicious food...',
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 14,
                                      ),
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(10),
                                        child: const Icon(
                                          Icons.search,
                                          color: Color(0xFF6B46C1),
                                          size: 20,
                                        ),
                                      ),
                                      suffixIcon: Container(
                                        margin: const EdgeInsets.all(6),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6B46C1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.filter_list,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            onPressed: () {
                                              // TODO: Show advanced filters
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Advanced filters coming soon!'),
                                                  backgroundColor: Color(0xFF6B46C1),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF6B46C1),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF1F2937),
                                    ),
                                    onChanged: (value) {
                                      _searchQuery = value.isEmpty ? null : value;
                                      _loadData();
                                    },
                                  ),
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Quick Category Buttons
                                if (_categories.isNotEmpty)
                                  SizedBox(
                                    height: 36,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _categories.length > 5 ? 5 : _categories.length,
                                      itemBuilder: (context, index) {
                                        final category = _categories[index];
                                        final isSelected = _selectedCategory == category.name;
                                        
                                        return Container(
                                          margin: const EdgeInsets.only(right: 6),
                                          child: FilterChip(
                                            label: Text(
                                              category.name,
                                              style: TextStyle(
                                                color: isSelected ? Colors.white : const Color(0xFF6B46C1),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                            selected: isSelected,
                                            onSelected: (selected) {
                                              setState(() {
                                                _selectedCategory = selected ? category.name : null;
                                              });
                                              _loadData();
                                            },
                                            backgroundColor: Colors.white,
                                            selectedColor: const Color(0xFF8B5CF6),
                                            checkmarkColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(18),
                                              side: BorderSide(
                                                color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade300,
                                                width: 1,
                                              ),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Products Grid Section
                          Container(
                            margin: const EdgeInsets.all(16),
                            child: _isLoading
                                ? GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: _getCrossAxisCount(context),
                                      mainAxisSpacing: 20,
                                      crossAxisSpacing: 20,
                                      childAspectRatio: 0.6,
                                    ),
                                    itemCount: 6,
                                    itemBuilder: (context, index) {
                                      return Container(
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
                                            Expanded(
                                              flex: 2,
                                              child: Padding(
                                                padding: const EdgeInsets.all(16),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      height: 16,
                                                      width: double.infinity,
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.shade200,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Container(
                                                      height: 18,
                                                      width: 80,
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.shade200,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                    ),
                                                    const Spacer(),
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
                                      );
                                    },
                                  )
                                : _errorMessage != null
                                    ? Center(
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
                                      )
                                    : _products.isEmpty
                                        ? Center(
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
                                          )
                                        : GridView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: _getCrossAxisCount(context),
                                              mainAxisSpacing: 20,
                                              crossAxisSpacing: 20,
                                              childAspectRatio: 0.6,
                                            ),
                                            itemCount: _products.length,
                                            itemBuilder: (context, index) {
                                              final product = _products[index];
                                              return Card(
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
                                                      ],
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                                                        ? [const Color(0xFFEDE9FE), const Color(0xFFF3F4F6)]
                                                                        : [Colors.grey.shade200, Colors.grey.shade300],
                                                                  ),
                                                                ),
                                                                child: ClipRRect(
                                                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                                                  child: _getProductImage(product.imagePath),
                                                                ),
                                                              ),
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
                                                                  ),
                                                                  child: Text(
                                                                    product.quantity > 0 ? '${product.quantity} left' : 'Out of stock',
                                                                    style: const TextStyle(
                                                                      color: Colors.white,
                                                                      fontSize: 10,
                                                                      fontWeight: FontWeight.w600,
                                                                    ),
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
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Flexible(
                                                                  child: Text(
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
                                                                ),
                                                                const SizedBox(height: 4),
                                                                Flexible(
                                                                  child: Text(
                                                                    'Rp ${product.price.toStringAsFixed(0)}',
                                                                    style: const TextStyle(
                                                                      color: Color(0xFF6B46C1),
                                                                      fontWeight: FontWeight.w800,
                                                                      fontSize: 18,
                                                                    ),
                                                                  ),
                                                                ),
                                                                const Spacer(),
                                                                // Quantity Controls
                                                                Consumer<OrderProvider>(
                                                                  builder: (context, orderProvider, _) => _buildQuantityControl(product, orderProvider),
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
                                            },
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

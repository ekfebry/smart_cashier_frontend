import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _selectedImageIndex = 0;
  String? _selectedVariant;
  int _quantity = 1;
  final TextEditingController _notesController = TextEditingController();

  // Product images - use actual product image or fallback
  List<String> get _productImages {
    if (widget.product.imagePath != null) {
      // Check if it's an asset image
      const assetImages = [
        'ayam_bakar.jpg',
        'bakso.jpg',
        'es_teh.jpeg',
        'jus_jeruk.jpg',
        'nasi_goreng.jpeg',
        'banner.jpg',
      ];
      if (assetImages.contains(widget.product.imagePath)) {
        return ['assets/images/${widget.product.imagePath}'];
      } else {
        return ['http://127.0.0.1:8000/storage/${widget.product.imagePath}'];
      }
    }
    // Fallback to placeholder
    return ['https://via.placeholder.com/400x300/6B46C1/FFFFFF?text=No+Image'];
  }

  final List<String> _variants = ['Regular', 'Large', 'Extra Large'];
  final List<String> _kitchenNotes = [
    'No onions',
    'Extra spicy',
    'Less salt',
    'Well done',
    'Medium rare',
  ];

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
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addToCart() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Create a modified product with selected options
    final modifiedProduct = Product(
      id: widget.product.id,
      name: '${widget.product.name}${_selectedVariant != null ? ' (${_selectedVariant})' : ''}',
      description: widget.product.description,
      price: widget.product.price + (_selectedVariant == 'Large' ? 5000 : _selectedVariant == 'Extra Large' ? 10000 : 0),
      category: widget.product.category,
      imagePath: widget.product.imagePath,
      stockQuantity: widget.product.stockQuantity,
      minStockLevel: widget.product.minStockLevel,
    );

    for (int i = 0; i < _quantity; i++) {
      cartProvider.addItem(modifiedProduct);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_quantity}x ${modifiedProduct.name} added to cart'),
        backgroundColor: const Color(0xFF6B46C1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = (widget.product.price + (_selectedVariant == 'Large' ? 5000 : _selectedVariant == 'Extra Large' ? 10000 : 0)) * _quantity;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Left Sidebar
          Container(
            width: 300,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Product Summary Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6B46C1),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Product Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (_selectedVariant != null)
                        Text(
                          'Variant: $_selectedVariant',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Quantity: $_quantity',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Total Price
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Rp ${totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B46C1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Add to Cart Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: widget.product.quantity > 0 ? _addToCart : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.product.quantity > 0
                            ? const Color(0xFF6B46C1)
                            : Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        widget.product.quantity > 0 ? 'Add to Cart' : 'Out of Stock',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          // Main Content Area
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                slivers: [
                  // App Bar with Image
                  SliverAppBar(
                    expandedHeight: 300,
                    pinned: true,
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1F2937),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        children: [
                          PageView.builder(
                            itemCount: _productImages.length,
                            onPageChanged: (index) {
                              setState(() => _selectedImageIndex = index);
                            },
                            itemBuilder: (context, index) {
                              final imagePath = _productImages[index];
                              if (imagePath.startsWith('assets/')) {
                                return Image.asset(
                                  imagePath,
                                  fit: BoxFit.cover,
                                  semanticLabel: 'Image of ${widget.product.name}',
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: const Color(0xFFEDE9FE),
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        size: 80,
                                        color: Color(0xFF6B46C1),
                                      ),
                                    );
                                  },
                                );
                              } else {
                                return Image.network(
                                  imagePath,
                                  fit: BoxFit.cover,
                                  semanticLabel: 'Image of ${widget.product.name}',
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
                                    return Container(
                                      color: const Color(0xFFEDE9FE),
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        size: 80,
                                        color: Color(0xFF6B46C1),
                                      ),
                                    );
                                  },
                                );
                              }
                            },
                          ),
                          // Image indicators
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _productImages.length,
                                (index) => Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _selectedImageIndex == index
                                        ? const Color(0xFF6B46C1)
                                        : Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Product Details
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Name and Price
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.product.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                              Text(
                                'Rp ${widget.product.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6B46C1),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Stock Status
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: widget.product.quantity > 0
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: widget.product.quantity > 0
                                    ? Colors.green.shade200
                                    : Colors.red.shade200,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.product.quantity > 0 ? Icons.check_circle : Icons.cancel,
                                  size: 16,
                                  color: widget.product.quantity > 0 ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.product.quantity > 0
                                      ? '${widget.product.quantity} in stock'
                                      : 'Out of stock',
                                  style: TextStyle(
                                    color: widget.product.quantity > 0 ? Colors.green.shade700 : Colors.red.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Description
                          if (widget.product.description != null) ...[
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.product.description!,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Variants
                          const Text(
                            'Size/Variant',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _variants.map((variant) {
                              final isSelected = _selectedVariant == variant;
                              final extraPrice = variant == 'Large' ? 5000 : variant == 'Extra Large' ? 10000 : 0;
                              return ChoiceChip(
                                label: Text(
                                  extraPrice > 0 ? '$variant (+Rp ${extraPrice.toStringAsFixed(0)})' : variant,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : const Color(0xFF6B46C1),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() => _selectedVariant = selected ? variant : null);
                                },
                                backgroundColor: Colors.white,
                                selectedColor: const Color(0xFF6B46C1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected ? const Color(0xFF6B46C1) : Colors.grey.shade300,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 20),

                          // Quantity
                          const Text(
                            'Quantity',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _quantity > 1
                                    ? () => setState(() => _quantity--)
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline),
                                color: const Color(0xFF6B46C1),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$_quantity',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(() => _quantity++),
                                icon: const Icon(Icons.add_circle_outline),
                                color: const Color(0xFF6B46C1),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Kitchen Notes
                          const Text(
                            'Special Instructions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _kitchenNotes.map((note) {
                              return ActionChip(
                                label: Text(note),
                                onPressed: () {
                                  final currentText = _notesController.text;
                                  final newText = currentText.isEmpty ? note : '$currentText, $note';
                                  _notesController.text = newText;
                                },
                                backgroundColor: Colors.grey.shade100,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              hintText: 'Add special instructions for the kitchen...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            maxLines: 3,
                          ),
                        ],
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
  }
}

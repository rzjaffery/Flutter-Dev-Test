import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_text_field.dart';

// Shared form for creating a new product OR editing an existing one.
// Pass [product] to pre-fill the form for editing; leave null to create.

class ProductFormScreen extends StatefulWidget {
  /// When non-null, the form operates in edit mode.
  final ProductModel? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _imageCtrl;

  // Category is managed separately because it uses a DropdownButtonFormField
  String _selectedCategory = 'Electronics';

  // Predefined categories (extend as needed)
  static const List<String> _categories = [
    'Electronics',
    'Clothing',
    'Books',
    'Home & Garden',
    'Sports',
    'Toys',
    'Food & Beverage',
    'Other',
  ];

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();

    // Pre-fill controllers when editing
    _nameCtrl = TextEditingController(text: widget.product?.name ?? '');
    _descCtrl = TextEditingController(text: widget.product?.description ?? '');
    _priceCtrl = TextEditingController(
      text: widget.product != null
          ? widget.product!.price.toStringAsFixed(2)
          : '',
    );
    _imageCtrl = TextEditingController(text: widget.product?.imageUrl ?? '');

    if (_isEditing &&
        _categories.contains(widget.product!.category)) {
      _selectedCategory = widget.product!.category;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  // Handles form submission for both creating and updating products.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final productProvider = context.read<ProductProvider>();
    final userId = context.read<AuthProvider>().user!.uid;

    bool success;

    if (_isEditing) {
      // Update existing product
      success = await productProvider.updateProduct(
        productId: widget.product!.id,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        category: _selectedCategory,
        imageUrl: _imageCtrl.text.trim().isEmpty
            ? null
            : _imageCtrl.text.trim(),
      );
    } else {
      // Create new product
      success = await productProvider.createProduct(
        userId: userId,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        category: _selectedCategory,
        imageUrl: _imageCtrl.text.trim().isEmpty
            ? null
            : _imageCtrl.text.trim(),
      );
    }

    // Show feedback to the user based on the operation's success or failure
    if (mounted) {
      if (success) {
        Navigator.pop(context); // Go back to the previous screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Product updated successfully!'
                  : 'Product created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              productProvider.errorMessage ?? 'Failed to save product',
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  // Builds the UI for the product form, including fields for name, description, price, category, and image URL.
  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final isBusy = productProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'New Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Name field
              CustomTextField(
                controller: _nameCtrl,
                label: 'Product Name',
                hint: 'e.g. Wireless Headphones',
                prefixIcon: Icons.inventory_2_outlined,
                validator: (val) => Validators.required(val, 'Product name'),
              ),
              const SizedBox(height: 16),

              // Product Description field
              CustomTextField(
                controller: _descCtrl,
                label: 'Description',
                hint: 'Describe your product...',
                isMultiline: true,
                validator: (val) => Validators.required(val, 'Description'),
              ),
              const SizedBox(height: 16),

              // Product Price field
              CustomTextField(
                controller: _priceCtrl,
                label: 'Price (USD)',
                hint: '0.00',
                prefixIcon: Icons.attach_money,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                validator: Validators.price,
              ),
              const SizedBox(height: 16),

              // Product Category dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 16),

              // Product Image URL field (optional)
              CustomTextField(
                controller: _imageCtrl,
                label: 'Image URL (optional)',
                hint: 'https://example.com/image.jpg',
                prefixIcon: Icons.image_outlined,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 8),

              // Preview image if a URL has been entered
              if (_imageCtrl.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _imageCtrl.text,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 60,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Text('Invalid image URL'),
                        ),
                      ),
                    ),
                  ),
                ),

              // Trigger preview on URL change
              TextButton.icon(
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.preview),
                label: const Text('Preview Image'),
              ),
              const SizedBox(height: 24),

              // Submit button
              ElevatedButton(
                onPressed: isBusy ? null : _submit,
                child: isBusy
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(_isEditing ? 'Update Product' : 'Create Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
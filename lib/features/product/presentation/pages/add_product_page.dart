import 'package:billing_app/core/widgets/input_label.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../bloc/product_bloc.dart';
import '../../domain/entities/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_validators.dart';
import '../../../../core/service_locator.dart';
import '../../domain/repositories/product_lookup_repository.dart';
import '../../domain/entities/lookup_product.dart';

class AddProductPage extends StatefulWidget {
  final String? barcode;
  const AddProductPage({super.key, this.barcode});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _barcodeController;
  late TextEditingController _nameController;
  double _price = 0.0;
  bool _isLookingUp = false;
  LookupProduct? _fetchedProduct;

  @override
  void initState() {
    super.initState();
    _barcodeController = TextEditingController(text: widget.barcode ?? '');
    _nameController = TextEditingController();
    _barcodeController.addListener(_onBarcodeChanged);
    if (widget.barcode != null && widget.barcode!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performLookup(widget.barcode!);
      });
    }
  }

  void _onBarcodeChanged() {
    if (_fetchedProduct != null) {
      setState(() {
        _fetchedProduct = null;
      });
    }
  }

  @override
  void dispose() {
    _barcodeController.removeListener(_onBarcodeChanged);
    _barcodeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _scanBarcode() async {
    final result = await context.push<String>('/scanner');
    if (result != null && result.isNotEmpty) {
      _barcodeController.text = result;
      _performLookup(result);
    }
  }

  void _performLookup(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return;

    // 1. Search Local Database first (loaded in ProductBloc)
    final productState = context.read<ProductBloc>().state;
    final existingProduct = productState.products
        .where((p) => p.barcode.trim().toLowerCase() == trimmed.toLowerCase())
        .firstOrNull;
    if (existingProduct != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product with barcode "$trimmed" already exists!'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _fetchedProduct = null;
        _nameController.text = existingProduct.name;
      });
      return;
    }

    // 2. Call External Product Database API
    setState(() {
      _isLookingUp = true;
    });

    try {
      final lookupRepo = sl<ProductLookupRepository>();
      final result = await lookupRepo.lookup(trimmed);
      if (result != null && mounted) {
        setState(() {
          _fetchedProduct = result;
          String displayName = result.productName;
          if (result.brand != null && result.brand!.isNotEmpty) {
            displayName = '${result.brand} - $displayName';
          }
          if (result.quantity != null && result.quantity!.isNotEmpty) {
            displayName = '$displayName (${result.quantity})';
          }
          _nameController.text = displayName;
        });
      } else if (mounted) {
        setState(() {
          _fetchedProduct = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product not found in database. Please create manually.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _fetchedProduct = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to lookup product details.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLookingUp = false;
        });
      }
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final barcode = _barcodeController.text.trim();
      final name = _nameController.text.trim();

      final productState = context.read<ProductBloc>().state;
      final existingProduct =
          productState.products.where((p) => p.barcode == barcode).firstOrNull;

      if (existingProduct != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product with barcode "$barcode" already exists!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final product = Product(
        id: const Uuid().v4(),
        name: name,
        barcode: barcode,
        price: _price,
      );

      context.read<ProductBloc>().add(AddProduct(product));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left,
                size: 28, color: Theme.of(context).primaryColor),
            onPressed: () => context.pop(),
          ),
          title: const Text('Add Product',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const InputLabel(text: 'Barcode'),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _barcodeController,
                          decoration: const InputDecoration(
                            hintText: 'Scan or enter barcode',
                          ),
                          textInputAction: TextInputAction.search,
                          onFieldSubmitted: _performLookup,
                          validator:
                              AppValidators.required('Please enter a barcode'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _isLookingUp
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.primaryColor),
                                  ),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.qr_code_scanner,
                                    color: AppTheme.primaryColor),
                                onPressed: _scanBarcode,
                                padding: const EdgeInsets.all(14),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('Tap the icon to open camera scanner or press Search on keyboard',
                      style: TextStyle(fontSize: 12, color: Color(0xFF4C669A))),
                  if (_fetchedProduct != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_fetchedProduct!.imageUrl != null &&
                              _fetchedProduct!.imageUrl!.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _fetchedProduct!.imageUrl!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[100],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                      size: 32,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Enriched Product Details',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_fetchedProduct!.brand != null &&
                                    _fetchedProduct!.brand!.isNotEmpty)
                                  _buildDetailRow(
                                    'Brand:',
                                    _fetchedProduct!.brand!,
                                  ),
                                if (_fetchedProduct!.category != null &&
                                    _fetchedProduct!.category!.isNotEmpty)
                                  _buildDetailRow(
                                    'Category:',
                                    _fetchedProduct!.category!,
                                  ),
                                if (_fetchedProduct!.quantity != null &&
                                    _fetchedProduct!.quantity!.isNotEmpty)
                                  _buildDetailRow(
                                    'Quantity/Size:',
                                    _fetchedProduct!.quantity!,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const InputLabel(text: 'Product Name'),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Basmati Rice',
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: AppValidators.required('Please enter a name'),
                  ),
                  const SizedBox(height: 24),
                  const InputLabel(text: 'Price'),
                  TextFormField(
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      prefixText: '₹ ',
                      prefixStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black),
                    ),
                    validator: AppValidators.price,
                    onSaved: (value) => _price = double.parse(value!),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: PrimaryButton(
          onPressed: _submit,
          icon: Icons.add_circle,
          label: 'Add Product',
        ));
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

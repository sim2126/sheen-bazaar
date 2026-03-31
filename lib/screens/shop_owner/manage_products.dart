import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/product_model.dart';
import '../../services/claude_service.dart';
import '../../services/image_upload_service.dart';
import '../../widgets/image_picker_field.dart';

class ManageProducts extends StatefulWidget {
  final String shopId;
  const ManageProducts({
    super.key,
    required this.shopId,
  });

  @override
  State<ManageProducts> createState() => _ManageProductsState();
}

class _ManageProductsState extends State<ManageProducts> {
  Stream<QuerySnapshot> get _productsStream =>
      FirebaseFirestore.instance
          .collection('shops')
          .doc(widget.shopId)
          .collection('products')
          .snapshots();

  Future<void> _deleteProduct(String productId) async {
    await FirebaseFirestore.instance
        .collection('shops')
        .doc(widget.shopId)
        .collection('products')
        .doc(productId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE0),
      appBar: AppBar(
        title: const Text('Manage Products'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF3D2B1F),
        icon: const Icon(Icons.add, color: Color(0xFFF5EDE0)),
        label: const Text(
          'Add Product',
          style: TextStyle(color: Color(0xFFF5EDE0)),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditProduct(shopId: widget.shopId),
            ),
          );
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _productsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFC8821A)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/wicker_basket.png', height: 80),
                  const SizedBox(height: 16),
                  Text(
                    'No products yet.\nTap + to add your first product.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            );
          }

          final products = snapshot.data!.docs
              .map((doc) => ProductModel.fromMap(
                    doc.id,
                    doc.data() as Map<String, dynamic>,
                  ))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3D2B1F).withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: p.image.isNotEmpty
                        ? Image.network(
                            p.image,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _imgFallback(),
                          )
                        : _imgFallback(),
                  ),
                  title: Text(
                    p.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3D2B1F),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        '₹${p.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Color(0xFFB5603A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Stock: ${p.stock}',
                        style: TextStyle(
                          fontSize: 12,
                          color: p.stock > 0
                              ? Colors.green[600]
                              : Colors.red[400],
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF3D2B1F),
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditProduct(
                                shopId: widget.shopId,
                                existingProduct: p,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red[400],
                          size: 20,
                        ),
                        onPressed: () => _confirmDelete(context, p),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProductModel p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Remove "${p.name}" from your shop?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(p.id);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgFallback() {
    return Container(
      width: 56,
      height: 56,
      color: const Color(0xFFEDE0CC),
      child: Center(child: Image.asset('assets/images/wicker_basket.png', height: 28, color: const Color(0x333D2B1F))),
    );
  }
}

// ── Add / Edit Product ──
class AddEditProduct extends StatefulWidget {
  final String shopId;
  final ProductModel? existingProduct;

  const AddEditProduct({
    super.key,
    required this.shopId,
    this.existingProduct,
  });

  @override
  State<AddEditProduct> createState() => _AddEditProductState();
}

class _AddEditProductState extends State<AddEditProduct> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();

  XFile? _imageFile;

  String _categoryId = 'pashmina';
  bool _loading = false;
  bool get _isEditing => widget.existingProduct != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.existingProduct!;
      _nameCtrl.text = p.name;
      _descCtrl.text = p.description;
      _priceCtrl.text = p.price.toStringAsFixed(0);
      _stockCtrl.text = p.stock.toString();
      _categoryId = p.categoryId;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final col = FirebaseFirestore.instance
          .collection('shops')
          .doc(widget.shopId)
          .collection('products');

      // Pre-generate or reuse doc reference for Storage path
      final docRef = _isEditing ? col.doc(widget.existingProduct!.id) : col.doc();
      final productId = docRef.id;

      // Upload image if a new file was picked, otherwise keep existing URL
      String imageUrl = _isEditing ? widget.existingProduct!.image : '';
      if (_imageFile != null) {
        imageUrl = await ImageUploadService.upload(
          image: _imageFile!,
          storagePath: 'shops/${widget.shopId}/products/$productId.jpg',
        );
      }

      final data = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'image': imageUrl,
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0,
        'stock': int.tryParse(_stockCtrl.text.trim()) ?? 0,
        'categoryId': _categoryId,
        'createdAt': _isEditing
            ? widget.existingProduct!.createdAt
            : Timestamp.now(),
      };

      if (_isEditing) {
        await docRef.update(data);
      } else {
        await docRef.set(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Product updated!' : 'Product added!'),
            backgroundColor: const Color(0xFF3D2B1F),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE0),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Product Name'),
              _field(
                controller: _nameCtrl,
                hint: 'e.g. Pure Pashmina Shawl',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),

              _label('Description'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field(
                      controller: _descCtrl,
                      hint: 'Describe the craft and its origin...',
                      maxLines: 4,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _AiGenerateButton(
                      onGenerated: (text) =>
                          setState(() => _descCtrl.text = text),
                      getProductName: () => _nameCtrl.text.trim(),
                      getCategoryId: () => _categoryId,
                    ),
                  ),
                ],
              ),

              ImagePickerField(
                label: 'Product Image',
                aspectRatio: 1.0,
                pickedFile: _imageFile,
                existingUrl: _isEditing ? widget.existingProduct!.image : '',
                onPick: (file) => setState(() => _imageFile = file),
              ),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Price (₹)'),
                        _field(
                          controller: _priceCtrl,
                          hint: '4500',
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Stock'),
                        _field(
                          controller: _stockCtrl,
                          hint: '10',
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              _label('Category'),
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF3D2B1F)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _categoryId,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'pashmina',
                        child: Text('Pashmina'),
                      ),
                      DropdownMenuItem(
                        value: 'papier_mache',
                        child: Text('Papier Mache'),
                      ),
                      DropdownMenuItem(
                        value: 'wood',
                        child: Text('Walnut Wood'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _categoryId = v!),
                  ),
                ),
              ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Save Changes' : 'Add Product',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF3D2B1F),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}

class _AiGenerateButton extends StatefulWidget {
  final Function(String) onGenerated;
  final String Function() getProductName;
  final String Function() getCategoryId;

  const _AiGenerateButton({
    required this.onGenerated,
    required this.getProductName,
    required this.getCategoryId,
  });

  @override
  State<_AiGenerateButton> createState() => _AiGenerateButtonState();
}

class _AiGenerateButtonState extends State<_AiGenerateButton> {
  bool _loading = false;

  Future<void> _generate() async {
    final name = widget.getProductName();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a product name first'),
          backgroundColor: Color(0xFFB5603A),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final category = widget.getCategoryId();
    final categoryName = category == 'pashmina'
        ? 'Pashmina'
        : category == 'papier_mache'
            ? 'Papier Mache'
            : 'Walnut Wood';

    final response = await ClaudeService.sendMessage(
      systemPrompt:
          'You are an expert in Kashmiri handicrafts with deep knowledge '
          'of the cultural heritage, craftsmanship techniques, and artisan '
          'traditions of Kashmir. Write rich, authentic product descriptions '
          'for a marketplace app. Keep descriptions between 2-4 sentences. '
          'Be evocative and highlight the handmade nature and cultural significance. '
          'Do not use markdown formatting — plain text only.',
      messages: [
        {
          'role': 'user',
          'content': 'Write a product description for: "$name" '
              'Category: $categoryName Kashmiri handicraft.',
        },
      ],
    );

    widget.onGenerated(response);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Generate with AI',
      child: GestureDetector(
        onTap: _loading ? null : _generate,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF3D2B1F),
            borderRadius: BorderRadius.circular(10),
          ),
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFFC9A55A),
                    strokeWidth: 2,
                  ),
                )
              : const Icon(LucideIcons.sparkles, color: Color(0xFFF5EDE0), size: 20),
        ),
      ),
    );
  }
}

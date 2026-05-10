import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/product_model.dart';
import '../../services/gemini_service.dart';
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
                      Row(
                        children: [
                          Text(
                            'Stock: ${p.stock}',
                            style: TextStyle(
                              fontSize: 14,
                              color: p.stock == 0
                                  ? Colors.red[400]
                                  : p.stock <= 3
                                      ? Colors.orange[700]
                                      : Colors.green[600],
                            ),
                          ),
                          if (p.stock == 0) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.warning_rounded, size: 13, color: Colors.red),
                          ] else if (p.stock <= 3) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.warning_amber_rounded, size: 13, color: Colors.orange),
                          ],
                        ],
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
  ProductDetails? _generatedDetails;

  String? _categoryId;
  List<Map<String, String>> _categories = [];
  bool _categoriesLoading = true;
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
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final snap = await FirebaseFirestore.instance
        .collection('categories')
        .get();
    final cats = snap.docs
        .map((d) => {'id': d.id, 'name': d.data()['name'] as String})
        .toList()
      ..sort((a, b) => a['name']!.compareTo(b['name']!));
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _categoriesLoading = false;
      if (_categoryId == null ||
          !cats.any((c) => c['id'] == _categoryId)) {
        _categoryId = cats.isNotEmpty ? cats.first['id'] : null;
      }
    });
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
    if (_categoryId == null) return;
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
        if (_generatedDetails != null)
          'details': _generatedDetails!.toMap(),
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
              _label('Category'),
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF3D2B1F)),
                ),
                child: _categoriesLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF3D2B1F),
                            ),
                          ),
                        ),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _categoryId,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          style: const TextStyle(
                            color: Color(0xFF3D2B1F),
                            fontSize: 15,
                          ),
                          iconEnabledColor: const Color(0xFF3D2B1F),
                          items: _categories
                              .map((c) => DropdownMenuItem(
                                    value: c['id'],
                                    child: Text(c['name']!),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _categoryId = v),
                        ),
                      ),
              ),

              _label('Product Name'),
              _field(
                controller: _nameCtrl,
                hint: 'e.g. Pure Pashmina Shawl',
                validator: (v) => v!.isEmpty ? 'Required' : null,
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

              ImagePickerField(
                label: 'Product Image',
                aspectRatio: 1.0,
                pickedFile: _imageFile,
                existingUrl: _isEditing ? widget.existingProduct!.image : '',
                onPick: (file) => setState(() => _imageFile = file),
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
                      onGenerated: (text, details) => setState(() {
                        _descCtrl.text = text;
                        _generatedDetails = details;
                      }),
                      getProductName: () => _nameCtrl.text.trim(),
                      getCategoryName: () => _categories
                          .firstWhere(
                            (c) => c['id'] == _categoryId,
                            orElse: () => {'name': 'Kashmiri Handicraft'},
                          )['name']!,
                      getImageFile: () => _imageFile,
                    ),
                  ),
                ],
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
                          style: const TextStyle(fontSize: 18),
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
          fontSize: 15,
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
        style: const TextStyle(color: Color(0xFF3D2B1F), fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}

class _AiGenerateButton extends StatefulWidget {
  final Function(String description, ProductDetails? details) onGenerated;
  final String Function() getProductName;
  final String Function() getCategoryName;
  final XFile? Function() getImageFile;

  const _AiGenerateButton({
    required this.onGenerated,
    required this.getProductName,
    required this.getCategoryName,
    required this.getImageFile,
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

    try {
      final categoryName = widget.getCategoryName();
      final imageFile = widget.getImageFile();
      final imageBytes = imageFile == null ? null : await imageFile.readAsBytes();
      final rawResponse = await GeminiService.describeProduct(
        productName: name,
        categoryName: categoryName,
        imageBytes: imageBytes,
        mediaType: imageFile == null ? 'image/jpeg' : _mediaTypeFor(imageFile),
      );

      final cleaned = rawResponse
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();
      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
      final details = ProductDetails.fromMap(parsed);
      final plainDescription = _plainDescription(details);

      if (plainDescription.isEmpty) {
        throw Exception('AI returned an empty product description.');
      }

      if (!mounted) return;
      final apply = await _showGeneratedPreview(details: details);
      if (apply && mounted) {
        widget.onGenerated(plainDescription, details);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFB5603A),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _plainDescription(ProductDetails details) {
    return [
      if (details.tagline != null) details.tagline!,
      if (details.narrative != null) details.narrative!,
      if (details.material != null) 'Material: ${details.material}',
      if (details.craft != null) 'Craft: ${details.craft}',
      if (details.color != null) 'Color: ${details.color}',
      if (details.dimensions != null) 'Dimensions: ${details.dimensions}',
      if (details.occasion != null) 'Occasion: ${details.occasion}',
      if (details.care != null) 'Care: ${details.care}',
    ].join('\n').trim();
  }

  String _mediaTypeFor(XFile imageFile) {
    final lower = imageFile.name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<bool> _showGeneratedPreview({
    required ProductDetails details,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Review AI description',
          style: TextStyle(color: Color(0xFF3D2B1F)),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Check these details before applying them to the product listing.',
                style: TextStyle(color: Color(0xFF6B5A4A), fontSize: 14),
              ),
              const SizedBox(height: 14),
              _previewRow('Tagline', details.tagline),
              _previewRow('Narrative', details.narrative),
              _previewRow('Material', details.material),
              _previewRow('Craft', details.craft),
              _previewRow('Color', details.color),
              _previewRow('Dimensions', details.dimensions),
              _previewRow('Occasion', details.occasion),
              _previewRow('Care', details.care),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _previewRow(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB5603A),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF3D2B1F),
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.getImageFile() != null;
    return Tooltip(
      message: hasImage ? 'Generate from image' : 'Generate with product name only',
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

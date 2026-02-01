import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:storage_client/storage_client.dart';
import '../theme/coffee_palette.dart';

class AdminMenuEditorScreen extends StatefulWidget {
  const AdminMenuEditorScreen({super.key});

  @override
  State<AdminMenuEditorScreen> createState() => _AdminMenuEditorScreenState();
}

class _AdminMenuEditorScreenState extends State<AdminMenuEditorScreen> {
  final _service = _AdminMenuService();
  late Future<_MenuData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _service.loadMenu();
  }

  void _refresh() {
    setState(() => _dataFuture = _service.loadMenu());
  }

  Future<void> _openEditor({
    required List<CategoryItem> categories,
    AdminItem? item,
  }) async {
    final result = await showModalBottomSheet<_ItemDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: CoffeePalette.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ItemEditorSheet(
        item: item,
        categories: categories,
      ),
    );
    if (result == null) return;
    if (item == null) {
      await _service.createItem(result);
    } else {
      await _service.updateItem(item.id, result);
    }
    _refresh();
  }

  Future<void> _openDeletePicker(List<AdminItem> items) async {
    final picked = await showModalBottomSheet<AdminItem>(
      context: context,
      backgroundColor: CoffeePalette.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DeleteItemSheet(items: items),
    );
    if (picked == null) return;
    await _service.deleteItem(picked.id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeePalette.cream,
      appBar: AppBar(
        backgroundColor: CoffeePalette.cream,
        elevation: 0,
        title: Text('Menu Editor', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: FutureBuilder<_MenuData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load menu.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          final data = snapshot.data ?? _MenuData.empty();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Products',
                          style: Theme.of(context).textTheme.titleMedium),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () =>
                                _openEditor(categories: data.categories),
                            icon: const Icon(Icons.add_circle_outline),
                            color: CoffeePalette.espresso,
                          ),
                          IconButton(
                            onPressed: data.items.isEmpty
                                ? null
                                : () => _openDeletePicker(data.items),
                        icon: const Icon(Icons.remove_circle_outline),
                        color: CoffeePalette.espresso,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (data.items.isEmpty)
                Text('No items yet.',
                    style: Theme.of(context).textTheme.bodyMedium)
              else
                ...data.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                      onTap: () =>
                          _openEditor(categories: data.categories, item: item),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: CoffeePalette.card,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _ItemImage(imageUrl: item.imageUrl),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.categoryName ?? 'Uncategorized',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.description.isEmpty
                                        ? 'No description'
                                        : item.description,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '\$${item.price.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: CoffeePalette.espresso),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminMenuService {
  Future<_MenuData> loadMenu() async {
    final categories = await _fetchCategories();
    final items = await _fetchItems();
    return _MenuData(categories: categories, items: items);
  }

  Future<List<CategoryItem>> _fetchCategories() async {
    final response = await supabase
        .from('categories')
        .select()
        .order('sort_order', ascending: true);
    return (response as List<dynamic>)
        .map((row) => CategoryItem.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<AdminItem>> _fetchItems() async {
    final response = await supabase
        .from('items')
        .select('id,name,description,price,image_url,is_active,category_id,categories(name)')
        .order('name');
    return (response as List<dynamic>)
        .map((row) => AdminItem.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> createItem(_ItemDraft draft) async {
    await supabase.from('items').insert({
      'name': draft.name,
      'description': draft.description,
      'price': draft.price,
      'image_url': draft.imageUrl,
      'category_id': draft.categoryId,
      'is_active': draft.isActive,
    });
  }

  Future<void> updateItem(String id, _ItemDraft draft) async {
    await supabase.from('items').update({
      'name': draft.name,
      'description': draft.description,
      'price': draft.price,
      'image_url': draft.imageUrl,
      'category_id': draft.categoryId,
      'is_active': draft.isActive,
    }).eq('id', id);
  }

  Future<void> deleteItem(String id) async {
    await supabase.from('items').delete().eq('id', id);
  }
}

class _MenuData {
  const _MenuData({required this.categories, required this.items});

  final List<CategoryItem> categories;
  final List<AdminItem> items;

  factory _MenuData.empty() => const _MenuData(categories: [], items: []);
}

class CategoryItem {
  const CategoryItem({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory CategoryItem.fromMap(Map<String, dynamic> data) {
    return CategoryItem(
      id: data['id'] as String,
      name: data['name'] as String,
    );
  }
}

class AdminItem {
  const AdminItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
    required this.categoryName,
    required this.isActive,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String? categoryId;
  final String? categoryName;
  final bool isActive;

  factory AdminItem.fromMap(Map<String, dynamic> data) {
    final category = data['categories'] as Map<String, dynamic>?;
    return AdminItem(
      id: data['id'] as String,
      name: data['name'] as String,
      description: (data['description'] as String?) ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      imageUrl: (data['image_url'] as String?) ?? '',
      categoryId: data['category_id'] as String?,
      categoryName: category == null ? null : category['name'] as String?,
      isActive: (data['is_active'] as bool?) ?? true,
    );
  }
}

class _ItemImage extends StatelessWidget {
  const _ItemImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: 56,
      decoration: BoxDecoration(
        color: CoffeePalette.caramelSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: imageUrl.isEmpty
          ? const Icon(Icons.image_outlined, color: CoffeePalette.espresso)
          : ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: 56,
                height: 56,
              ),
            ),
    );
  }
}

class _DeleteItemSheet extends StatelessWidget {
  const _DeleteItemSheet({required this.items});

  final List<AdminItem> items;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delete Product',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.name),
                trailing: const Icon(Icons.delete_outline,
                    color: CoffeePalette.espressoSoft),
                onTap: () => Navigator.of(context).pop(item),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemDraft {
  const _ItemDraft({
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
    required this.isActive,
  });

  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String? categoryId;
  final bool isActive;
}

class _ItemEditorSheet extends StatefulWidget {
  const _ItemEditorSheet({
    required this.item,
    required this.categories,
  });

  final AdminItem? item;
  final List<CategoryItem> categories;

  @override
  State<_ItemEditorSheet> createState() => _ItemEditorSheetState();
}

class _ItemEditorSheetState extends State<_ItemEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _imageController;
  final _picker = ImagePicker();
  bool _uploading = false;
  String? _selectedCategoryId;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.item?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.item?.description ?? '');
    _priceController = TextEditingController(
      text: widget.item?.price.toStringAsFixed(2) ?? '',
    );
    _imageController =
        TextEditingController(text: widget.item?.imageUrl ?? '');
    _selectedCategoryId = widget.item?.categoryId;
    _isActive = widget.item?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final path =
          'products/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('product-images').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      final publicUrl =
          supabase.storage.from('product-images').getPublicUrl(path);
      _imageController.text = publicUrl;
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload photo.')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.item == null ? 'Add Item' : 'Edit Item',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Center(child: _ItemImage(imageUrl: _imageController.text)),
          const SizedBox(height: 10),
          Center(
            child: OutlinedButton.icon(
              onPressed: _uploading ? null : _pickAndUploadImage,
              icon: _uploading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_library_outlined),
              label: const Text('Upload photo'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: CoffeePalette.espresso),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              filled: true,
              fillColor: CoffeePalette.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              filled: true,
              fillColor: CoffeePalette.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Price',
              filled: true,
              fillColor: CoffeePalette.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedCategoryId,
            items: widget.categories
                .map(
                  (category) => DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(category.name),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedCategoryId = value),
            decoration: InputDecoration(
              labelText: 'Category',
              filled: true,
              fillColor: CoffeePalette.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            title: const Text('Active'),
            activeColor: CoffeePalette.espresso,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: CoffeePalette.espresso),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final price =
                        double.tryParse(_priceController.text.trim()) ?? 0;
                    Navigator.pop(
                      context,
                      _ItemDraft(
                        name: _nameController.text.trim(),
                        description: _descriptionController.text.trim(),
                        price: price,
                        imageUrl: _imageController.text.trim(),
                        categoryId: _selectedCategoryId,
                        isActive: _isActive,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CoffeePalette.espresso,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:storage_client/storage_client.dart';
import '../theme/coffee_palette.dart';

String _resolveProductImageUrl(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '';
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }
  final path = value.startsWith('/') ? value.substring(1) : value;
  return supabase.storage.from('product-images').getPublicUrl(path);
}

class AdminMenuEditorScreen extends StatefulWidget {
  const AdminMenuEditorScreen({super.key});

  @override
  State<AdminMenuEditorScreen> createState() => _AdminMenuEditorScreenState();
}

class _AdminMenuEditorScreenState extends State<AdminMenuEditorScreen> {
  final _service = _AdminMenuService();
  late Future<_MenuData> _dataFuture;
  RealtimeChannel? _menuRealtimeChannel;

  @override
  void initState() {
    super.initState();
    _dataFuture = _service.loadMenu();
    _menuRealtimeChannel = supabase
        .channel('admin-menu-editor-live')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'items',
          callback: (_) => _refreshNow(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'categories',
          callback: (_) => _refreshNow(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    final channel = _menuRealtimeChannel;
    if (channel != null) {
      supabase.removeChannel(channel);
    }
    super.dispose();
  }

  void _refresh() {
    setState(() => _dataFuture = _service.loadMenu());
  }

  Future<void> _refreshNow() async {
    final fresh = await _service.loadMenu();
    if (!mounted) return;
    setState(() => _dataFuture = Future<_MenuData>.value(fresh));
  }

  Future<void> _openEditor({
    required List<CategoryItem> categories,
    AdminItem? item,
  }) async {
    final result = await Navigator.of(context).push<_ItemDraft>(
      MaterialPageRoute(
        builder: (_) => _ItemEditorPage(
          item: item,
          categories: categories,
        ),
      ),
    );
    if (result == null) return;
    if (item == null) {
      await _service.createItem(result);
    } else {
      await _service.updateItem(item.id, result);
    }
    await _refreshNow();
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
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete item?'),
            content: Text('Remove "${picked.name}" from the menu?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CoffeePalette.espresso,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldDelete) return;
    await _service.deleteItem(picked.id);
    await _refreshNow();
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
    final resolvedUrl = _resolveProductImageUrl(imageUrl);
    final hasImage = resolvedUrl.isNotEmpty;
    return Container(
      height: 56,
      width: 56,
      decoration: BoxDecoration(
        color: CoffeePalette.caramelSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: !hasImage
          ? const Icon(Icons.image_outlined, color: CoffeePalette.espresso)
          : ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                resolvedUrl,
                fit: BoxFit.cover,
                width: 56,
                height: 56,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.image_outlined,
                  color: CoffeePalette.espresso,
                ),
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

class _ItemEditorPage extends StatefulWidget {
  const _ItemEditorPage({
    required this.item,
    required this.categories,
  });

  final AdminItem? item;
  final List<CategoryItem> categories;

  @override
  State<_ItemEditorPage> createState() => _ItemEditorPageState();
}

class _ItemEditorPageState extends State<_ItemEditorPage> {
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
      final ext = file.path.contains('.')
          ? file.path.split('.').last.toLowerCase()
          : 'jpg';
      final unique = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
      final path = 'products/$unique.$ext';
      await supabase.storage.from('product-images').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: file.mimeType ?? 'image/jpeg',
              upsert: true,
            ),
          );
      final publicUrl =
          supabase.storage.from('product-images').getPublicUrl(path);

      // If editing an existing item, persist image immediately as well.
      if (widget.item != null) {
        await supabase.from('items').update({'image_url': publicUrl}).eq(
              'id',
              widget.item!.id,
            );
      }

      _imageController.text = publicUrl;
      setState(() {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo uploaded successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload photo: $error')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _section({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CoffeePalette.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeePalette.cream,
      appBar: AppBar(
        backgroundColor: CoffeePalette.cream,
        elevation: 0,
        title: Text(widget.item == null ? 'Add Item' : 'Edit Item'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: double.infinity,
                        height: 220,
                        color: CoffeePalette.caramelSoft,
                child: _imageController.text.trim().isEmpty
                            ? const Icon(
                                Icons.image_outlined,
                                color: CoffeePalette.espresso,
                                size: 48,
                              )
                            : Image.network(
                                _resolveProductImageUrl(_imageController.text.trim()),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.broken_image_outlined,
                                  color: CoffeePalette.espresso,
                                  size: 48,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _uploading ? null : _pickAndUploadImage,
                        icon: _uploading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.photo_library_outlined),
                        label: Text(
                            _uploading ? 'Uploading...' : 'Upload product photo'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: CoffeePalette.espresso),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _section(
                      title: 'Item Details',
                      child: Column(
                        children: [
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Name',
                              filled: true,
                              fillColor: CoffeePalette.cream,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _descriptionController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              filled: true,
                              fillColor: CoffeePalette.cream,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _section(
                      title: 'Pricing & Category',
                      child: Column(
                        children: [
                          TextField(
                            controller: _priceController,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Price',
                              prefixText: '\$ ',
                              filled: true,
                              fillColor: CoffeePalette.cream,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
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
                            onChanged: (value) =>
                                setState(() => _selectedCategoryId = value),
                            decoration: InputDecoration(
                              labelText: 'Category',
                              filled: true,
                              fillColor: CoffeePalette.cream,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _section(
                      title: 'Availability',
                      child: Row(
                        children: [
                          const Expanded(child: Text('Active item')),
                          Switch(
                            value: _isActive,
                            onChanged: (value) =>
                                setState(() => _isActive = value),
                            activeColor: CoffeePalette.espresso,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              decoration: const BoxDecoration(
                color: CoffeePalette.cream,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
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
                      child: const Text('Save Item'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

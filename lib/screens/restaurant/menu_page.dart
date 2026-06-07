import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/food_models.dart';
import '../../services/food_service.dart';
import '../../models/app_user.dart';

class RestaurantMenuPage extends StatefulWidget {
  final AppUser currentUser;
  const RestaurantMenuPage({super.key, required this.currentUser});

  @override
  State<RestaurantMenuPage> createState() => _RestaurantMenuPageState();
}

class _RestaurantMenuPageState extends State<RestaurantMenuPage> {
  final FoodService _foodSvc = FoodService();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Menu Manager',
          style: textTheme.headlineMedium,
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plusSquare, color: Color(0xFF4285F4), size: 28),
            onPressed: _showAddCategoryDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search categories or items...',
                prefixIcon: const Icon(LucideIcons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<FoodCategory>>(
              stream: _foodSvc.getMenu(widget.currentUser.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                var categories = snapshot.data ?? [];
                
                // Filtering logic
                if (_searchQuery.isNotEmpty) {
                  categories = categories.where((cat) {
                    final catNameMatch = cat.name.toLowerCase().contains(_searchQuery);
                    final hasMatchingItems = cat.items.any((item) => item.name.toLowerCase().contains(_searchQuery));
                    return catNameMatch || hasMatchingItems;
                  }).map((cat) {
                    if (cat.name.toLowerCase().contains(_searchQuery)) return cat; // include all items
                    // Filter items to only match
                    final filteredItems = cat.items.where((item) => item.name.toLowerCase().contains(_searchQuery)).toList();
                    return FoodCategory(id: cat.id, name: cat.name, items: filteredItems);
                  }).toList();
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    if (categories.isEmpty && _searchQuery.isEmpty)
                      _buildEmptyState(isDark)
                    else if (categories.isEmpty)
                      Center(child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Text("No results found.", style: textTheme.bodyMedium),
                      ))
                    else ...[
                      Text(
                        'ACTIVE CATEGORIES',
                        style: textTheme.labelSmall?.copyWith(letterSpacing: 2),
                      ),
                      const SizedBox(height: 16),
                      ...categories.map((cat) => _CategoryCard(
                        category: cat, 
                        shopId: widget.currentUser.id, 
                        isDark: isDark,
                        onDelete: () => _deleteCategory(cat.id),
                      )).toList(),
                    ]
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategoryDialog,
        backgroundColor: const Color(0xFF4285F4),
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: Text('New Category', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 100),
      child: Column(
        children: [
          Icon(LucideIcons.utensils, size: 80, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 24),
          Text('Your menu is empty', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey)),
          const SizedBox(height: 8),
          Text('Start by adding a food category like "Starters"', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }

  void _deleteCategory(String categoryId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: const Text('This will remove all items inside this category.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _foodSvc.deleteMenuCategory(widget.currentUser.id, categoryId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Add Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. Main Course',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _foodSvc.addMenuCategory(widget.currentUser.id, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final FoodCategory category;
  final String shopId;
  final bool isDark;
  final VoidCallback onDelete;

  const _CategoryCard({required this.category, required this.shopId, required this.isDark, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(category.name, style: textTheme.titleMedium),
            subtitle: Text('${category.items.length} items available', style: textTheme.bodySmall),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF4285F4).withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(LucideIcons.utensilsCrossed, color: Color(0xFF4285F4), size: 20),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(LucideIcons.moreVertical),
              onSelected: (val) {
                if (val == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Rename Category')),
                const PopupMenuItem(value: 'delete', child: Text('Delete Category', style: TextStyle(color: Colors.red))),
              ],
            ),
          ),
          const Divider(height: 1),
          if (category.items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('No items yet. Add something delicious!', style: textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: category.items.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 20, endIndent: 20),
              itemBuilder: (context, index) {
                final item = category.items[index];
                return _ItemTile(item: item, category: category, shopId: shopId, isDark: isDark);
              },
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => _showAddItemDialog(context),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text('Add Item to ${category.name}'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('New Menu Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(hintText: 'Item Name (e.g. Burger)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(hintText: 'Price (₹)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Description (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                final newItem = FoodItem(
                  name: nameCtrl.text, 
                  price: double.parse(priceCtrl.text), 
                  isAvailable: true,
                  description: descCtrl.text,
                );
                final newItems = [...category.items, newItem];
                FoodService().updateMenuCategory(shopId, category.id, {'items': newItems.map((i) => i.toMap()).toList()});
                Navigator.pop(context);
              }
            },
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final FoodItem item;
  final FoodCategory category;
  final String shopId;
  final bool isDark;

  const _ItemTile({required this.item, required this.category, required this.shopId, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: textTheme.titleMedium?.copyWith(fontSize: 15)),
                const SizedBox(height: 4),
                Text('₹${item.price}', style: textTheme.bodyMedium?.copyWith(color: const Color(0xFF4285F4), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.isAvailable ? 'INSTOCK' : 'OUT', 
                style: textTheme.labelSmall?.copyWith(fontSize: 10, color: item.isAvailable ? const Color(0xFF34A853) : const Color(0xFFEA4335))),
              const SizedBox(height: 2),
              SizedBox(
                height: 24,
                child: Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: item.isAvailable,
                    activeColor: const Color(0xFF34A853),
                    onChanged: (val) {
                      final newItems = category.items.map((i) {
                        if (i.name == item.name) {
                          return FoodItem(name: i.name, price: i.price, isAvailable: val, description: i.description, imageUrl: i.imageUrl);
                        }
                        return i;
                      }).toList();
                      FoodService().updateMenuCategory(shopId, category.id, {'items': newItems.map((i) => i.toMap()).toList()});
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(LucideIcons.fileEdit, color: Colors.grey, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _showEditItemDialog(context),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl = TextEditingController(text: item.price.toString());
    final descCtrl = TextEditingController(text: item.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Edit ${item.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(hintText: 'Item Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(hintText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final newItems = category.items.where((i) => i.name != item.name).toList();
              FoodService().updateMenuCategory(shopId, category.id, {'items': newItems.map((i) => i.toMap()).toList()});
              Navigator.pop(context);
            }, 
            child: const Text('Delete Item', style: TextStyle(color: Colors.red))
          ),
          const Spacer(),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                final newItems = category.items.map((i) {
                  if (i.name == item.name) {
                    return FoodItem(
                      name: nameCtrl.text, 
                      price: double.parse(priceCtrl.text), 
                      isAvailable: i.isAvailable,
                      description: descCtrl.text,
                    );
                  }
                  return i;
                }).toList();
                FoodService().updateMenuCategory(shopId, category.id, {'items': newItems.map((i) => i.toMap()).toList()});
                Navigator.pop(context);
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}

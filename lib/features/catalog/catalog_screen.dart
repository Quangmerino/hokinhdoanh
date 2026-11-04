import 'package:flutter/material.dart';
import '../../core/controllers/business_controller.dart';
import '../../core/models/models.dart';
import '../../core/utils/formatters.dart';
import 'dialogs/category_dialog.dart';
import 'dialogs/product_dialog.dart';
import 'dialogs/supplier_dialog.dart';

class CatalogScreen extends StatefulWidget {
  final BusinessController controller;
  final VoidCallback onSwitchToPos;

  const CatalogScreen({
    super.key,
    required this.controller,
    required this.onSwitchToPos,
  });

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String _searchQuery = '';
  bool _lowStockOnly = false;

  BusinessController get ctrl => widget.controller;

  @override
  Widget build(BuildContext context) {
    final roots = ctrl.categories.where((c) => c.parentId == null).toList();
    final subtreeIds = ctrl.selectedCategoryId != null
        ? ctrl.getCategorySubtreeIds(ctrl.selectedCategoryId)
        : null;

    final filteredSuppliers = ctrl.suppliers.where((s) {
      if (ctrl.selectedSupplierId != null && s.id != ctrl.selectedSupplierId) {
        return false;
      }
      if (subtreeIds != null) {
        return s.categoryIds.any((cid) => subtreeIds.contains(cid));
      }
      return true;
    }).toList();

    final filteredProducts = ctrl.products.where((p) {
      if (subtreeIds != null && !subtreeIds.contains(p.categoryId)) return false;
      if (ctrl.selectedSupplierId != null &&
          p.primarySupplierId != ctrl.selectedSupplierId &&
          !p.supplierIds.contains(ctrl.selectedSupplierId)) {
        return false;
      }
      if (_lowStockOnly && p.stockQty > p.minStock) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!p.name.toLowerCase().contains(q) &&
            !p.sku.toLowerCase().contains(q) &&
            !p.specNote.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Top Action Bar
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'category',
                      label: Text('Danh mục ➔ NCC ➔ SP', style: TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: 'supplier',
                      label: Text('NCC ➔ Danh mục ➔ SP', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                  selected: {ctrl.treeMode},
                  onSelectionChanged: (val) => ctrl.setTreeMode(val.first),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => showCategoryDialog(context, ctrl),
                      icon: const Icon(Icons.create_new_folder_outlined, size: 16),
                      label: const Text('+ Danh Mục'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => showSupplierDialog(context, ctrl),
                      icon: const Icon(Icons.local_shipping_outlined, size: 16),
                      label: const Text('+ Nhà Cung Cấp'),
                    ),
                    FilledButton.icon(
                      onPressed: () => showProductDialog(context, ctrl),
                      icon: const Icon(Icons.add_box_outlined, size: 16),
                      label: const Text('+ Mặt Hàng Mới'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Empty State Onboarding Banner (When user starts with 0 items)
        if (ctrl.categories.isEmpty && ctrl.suppliers.isEmpty && ctrl.products.isEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF134E4A), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Khởi tạo dữ liệu tự do 100%',
                  style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Chào mừng bạn! Hãy tự tạo Danh mục, Nhà cung cấp và Mặt hàng theo đúng mô hình kinh doanh của bạn.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () => showCategoryDialog(context, ctrl),
                      child: const Text('Bước 1: + Tự tạo Danh mục'),
                    ),
                    ElevatedButton(
                      onPressed: () => showSupplierDialog(context, ctrl),
                      child: const Text('Bước 2: + Tự tạo Nhà cung cấp'),
                    ),
                    ElevatedButton(
                      onPressed: () => showProductDialog(context, ctrl),
                      child: const Text('Bước 3: + Tự thêm Mặt hàng'),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Hierarchical Tree Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🌳 Cây Phân Cấp Quản Lý',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () => ctrl.selectTreeFilter(categoryId: null, supplierId: null),
                      child: const Text('Xem tất cả'),
                    ),
                  ],
                ),
                const Divider(),
                if (ctrl.treeMode == 'category')
                  roots.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: Text('Chưa có danh mục nào. Hãy bấm "+ Danh Mục" để tạo.')),
                        )
                      : Column(
                          children: roots.map((r) => _buildCategoryTreeNode(context, r)).toList(),
                        )
                else
                  ctrl.suppliers.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: Text('Chưa có Nhà cung cấp nào. Hãy bấm "+ Nhà Cung Cấp" để tạo.')),
                        )
                      : Column(
                          children: ctrl.suppliers.map((s) => _buildSupplierTreeNode(context, s)).toList(),
                        ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Active Suppliers in Selected Branch
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '🚚 Nhà cung cấp thuộc nhánh (${filteredSuppliers.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    TextButton(
                      onPressed: () => showSupplierDialog(context, ctrl),
                      child: const Text('+ Thêm NCC'),
                    ),
                  ],
                ),
                if (filteredSuppliers.isEmpty)
                  const Text('Chưa có nhà cung cấp nào trong nhánh này.', style: TextStyle(fontSize: 12, color: Colors.grey))
                else
                  ...filteredSuppliers.map((s) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(child: Text('🚚')),
                        title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('SĐT: ${s.phone.isEmpty ? "---" : s.phone} • Nợ phải trả: ${AppFormatters.formatVnd(s.payableDebt)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => showSupplierDialog(context, ctrl, editSupplier: s),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              onPressed: () => ctrl.deleteSupplier(s.id),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Products List in Selected Branch
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Tìm mặt hàng, mã SKU...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Sắp hết kho', style: TextStyle(fontSize: 12)),
                      selected: _lowStockOnly,
                      onSelected: (v) => setState(() => _lowStockOnly = v),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (filteredProducts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Chưa có mặt hàng nào. Hãy bấm "+ Mặt Hàng Mới" để tự thêm.')),
                  )
                else
                  ...filteredProducts.map((p) {
                    final cat = ctrl.categories.where((c) => c.id == p.categoryId).firstOrNull;
                    final sup = ctrl.suppliers.where((s) => s.id == p.primarySupplierId).firstOrNull;
                    final isLow = p.stockQty <= p.minStock;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isLow ? Colors.amber.shade50 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isLow ? Colors.amber.shade300 : Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade700,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  cat?.icon ?? '📦',
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${p.name} (${p.sku})',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      '${cat?.name ?? "Chưa phân loại"} • NCC: ${sup?.name ?? "Chưa gán"}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                    Text(
                                      'Giá bán: ${AppFormatters.formatVnd(p.retailPrice)}/${p.baseUnit}'
                                      '${p.hasPackUnit ? " • ${p.packUnitName}: ${AppFormatters.formatVnd(p.packPrice)}" : ""}',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                                    ),
                                    Text(
                                      'Tồn kho: ${p.formattedStock}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isLow ? Colors.red.shade700 : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () => showProductDialog(context, ctrl, editProduct: p),
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text('Sửa'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => ctrl.deleteProduct(p.id),
                                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                    label: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  OutlinedButton(
                                    onPressed: () {
                                      ctrl.setPosOrderType('PURCHASE');
                                      ctrl.addProductToCart(p);
                                      widget.onSwitchToPos();
                                    },
                                    child: const Text('+ Nhập kho'),
                                  ),
                                  const SizedBox(width: 6),
                                  FilledButton(
                                    onPressed: () {
                                      ctrl.setPosOrderType('SALE');
                                      ctrl.addProductToCart(p);
                                      widget.onSwitchToPos();
                                    },
                                    child: const Text('🛒 Bán ngay'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTreeNode(BuildContext context, CategoryNode cat) {
    final nodeKey = 'cat-${cat.id}';
    final isExp = ctrl.expandedNodeKeys.contains(nodeKey);
    final children = ctrl.categories.where((c) => c.parentId == cat.id).toList();
    final subtreeIds = ctrl.getCategorySubtreeIds(cat.id);
    final prodCount = ctrl.products.where((p) => subtreeIds.contains(p.categoryId)).length;
    final directSups = ctrl.suppliers.where((s) => s.categoryIds.contains(cat.id)).toList();
    final isSelected = ctrl.selectedCategoryId == cat.id && ctrl.selectedSupplierId == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.teal.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isSelected ? Colors.teal : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            dense: true,
            onTap: () => ctrl.selectTreeFilter(categoryId: cat.id, supplierId: null),
            leading: Text(cat.icon, style: const TextStyle(fontSize: 18)),
            title: Text('${cat.name} ($prodCount SP)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Thêm nhánh con',
                  icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.teal),
                  onPressed: () => showCategoryDialog(context, ctrl, defaultParentId: cat.id),
                ),
                IconButton(
                  tooltip: 'Sửa danh mục',
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => showCategoryDialog(context, ctrl, editCategory: cat),
                ),
                IconButton(
                  tooltip: 'Xóa danh mục',
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  onPressed: () => ctrl.deleteCategory(cat.id),
                ),
                IconButton(
                  icon: Icon(isExp ? Icons.expand_less : Icons.expand_more, size: 18),
                  onPressed: () => ctrl.toggleNodeExpand(nodeKey),
                ),
              ],
            ),
          ),
          if (isExp && (directSups.isNotEmpty || children.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 8, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...directSups.map((sup) => InkWell(
                        onTap: () => ctrl.selectTreeFilter(categoryId: cat.id, supplierId: sup.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: Text(
                            '🚚 ${sup.name}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: ctrl.selectedSupplierId == sup.id ? FontWeight.bold : FontWeight.normal,
                              color: Colors.indigo.shade700,
                            ),
                          ),
                        ),
                      )),
                  ...children.map((child) => _buildCategoryTreeNode(context, child)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSupplierTreeNode(BuildContext context, SupplierModel sup) {
    final isSelected = ctrl.selectedSupplierId == sup.id && ctrl.selectedCategoryId == null;
    final supCats = ctrl.categories.where((c) => sup.categoryIds.contains(c.id)).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.indigo.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isSelected ? Colors.indigo : Colors.grey.shade300),
      ),
      child: ListTile(
        dense: true,
        onTap: () => ctrl.selectTreeFilter(categoryId: null, supplierId: sup.id),
        leading: const Text('🚚', style: TextStyle(fontSize: 18)),
        title: Text(sup.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(
          supCats.isEmpty ? 'Chưa gắn danh mục' : supCats.map((c) => '${c.icon} ${c.name}').join(' • '),
          style: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }
}

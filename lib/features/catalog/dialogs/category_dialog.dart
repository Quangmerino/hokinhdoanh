import 'package:flutter/material.dart';
import '../../../core/controllers/business_controller.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/validators.dart';

void showCategoryDialog(
  BuildContext context,
  BusinessController ctrl, {
  CategoryNode? editCategory,
  int? defaultParentId,
}) {
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController(text: editCategory?.name ?? '');
  final iconCtrl = TextEditingController(text: editCategory?.icon ?? '📦');
  int? parentId = editCategory != null ? editCategory.parentId : (defaultParentId ?? ctrl.selectedCategoryId);
  final forbiddenIds = editCategory != null ? ctrl.getCategorySubtreeIds(editCategory.id) : <int>[];

  const suggestedIcons = ['📦', '📁', '🌾', '🥤', '🥩', '🥬', '🥫', '🍺', '💊', '⚡', '👕', '🛒', '🧴', '🥚', '🍞'];

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.teal.shade100,
              child: Text(iconCtrl.text.isEmpty ? '📁' : iconCtrl.text, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                editCategory != null ? 'Sửa Danh Mục' : 'Tạo Danh Mục Mới',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<int?>(
                  initialValue: forbiddenIds.contains(parentId) ? null : parentId,
                  decoration: const InputDecoration(
                    labelText: 'Thuộc danh mục cha',
                    prefixIcon: Icon(Icons.account_tree_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('-- Danh mục gốc (Cấp 1) --')),
                    ...ctrl.categories
                        .where((c) => !forbiddenIds.contains(c.id))
                        .map((c) => DropdownMenuItem<int?>(
                              value: c.id,
                              child: Text(ctrl.getCategoryDepthLabel(c)),
                            )),
                  ],
                  onChanged: (v) => setDialogState(() => parentId = v),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Tên danh mục *',
                    hintText: 'VD: Bia nước ngọt, Lương thực...',
                    prefixIcon: const Icon(Icons.label_outline),
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    suffixIcon: nameCtrl.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setDialogState(() => nameCtrl.clear()))
                        : null,
                  ),
                  validator: (v) => Validators.required(v, 'Vui lòng nhập tên danh mục'),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: iconCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Biểu tượng / Icon',
                    prefixIcon: Icon(Icons.emoji_emotions_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 8),
                const Text('Gợi ý nhanh icon:', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: suggestedIcons.map((e) {
                    final isSel = iconCtrl.text == e;
                    return InkWell(
                      onTap: () => setDialogState(() => iconCtrl.text = e),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSel ? Colors.teal.shade100 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSel ? Colors.teal : Colors.grey.shade300),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 16)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton.icon(
            icon: const Icon(Icons.check, size: 18),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              ctrl.saveCategory(
                editId: editCategory?.id,
                name: nameCtrl.text.trim(),
                icon: iconCtrl.text.trim().isEmpty ? '📁' : iconCtrl.text.trim(),
                parentId: parentId,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã lưu danh mục: ${nameCtrl.text.trim()}'),
                  backgroundColor: Colors.teal.shade700,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            label: const Text('Lưu Danh Mục'),
          ),
        ],
      ),
    ),
  );
}

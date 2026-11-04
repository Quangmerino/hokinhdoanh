import 'package:flutter/material.dart';
import '../../../core/controllers/business_controller.dart';
import '../../../core/models/models.dart';

void showCategoryDialog(
  BuildContext context,
  BusinessController ctrl, {
  CategoryNode? editCategory,
  int? defaultParentId,
}) {
  final nameCtrl = TextEditingController(text: editCategory?.name ?? '');
  final iconCtrl = TextEditingController(text: editCategory?.icon ?? '📦');
  int? parentId = editCategory != null ? editCategory.parentId : (defaultParentId ?? ctrl.selectedCategoryId);
  final forbiddenIds = editCategory != null ? ctrl.getCategorySubtreeIds(editCategory.id) : <int>[];

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text(editCategory != null ? 'Sửa Danh Mục' : 'Tự Tạo Danh Mục Mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int?>(
                value: forbiddenIds.contains(parentId) ? null : parentId,
                decoration: const InputDecoration(labelText: 'Thuộc danh mục cha'),
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
              const SizedBox(height: 10),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên danh mục (Tự nhập)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: iconCtrl,
                decoration: const InputDecoration(labelText: 'Biểu tượng / Ký hiệu'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              ctrl.saveCategory(
                editId: editCategory?.id,
                name: nameCtrl.text.trim(),
                icon: iconCtrl.text.trim().isEmpty ? '📁' : iconCtrl.text.trim(),
                parentId: parentId,
              );
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    ),
  );
}

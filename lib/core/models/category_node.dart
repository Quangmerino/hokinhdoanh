class CategoryNode {
  final int id;
  final int? parentId;
  final String name;
  final String icon;
  final String materializedPath;

  const CategoryNode({
    required this.id,
    this.parentId,
    required this.name,
    this.icon = '📁',
    required this.materializedPath,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'parent_id': parentId,
        'name': name,
        'icon': icon,
        'materialized_path': materializedPath,
      };

  factory CategoryNode.fromMap(Map<String, dynamic> map) => CategoryNode(
        id: map['id'] as int,
        parentId: map['parent_id'] as int?,
        name: map['name'] as String,
        icon: map['icon'] as String? ?? '📁',
        materializedPath: map['materialized_path'] as String? ?? '/',
      );
}

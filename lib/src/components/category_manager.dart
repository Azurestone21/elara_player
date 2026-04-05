import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../src.dart';

final categoryServiceProvider = ChangeNotifierProvider<CategoryService>((ref) {
  return CategoryService();
});

class CategoryManager extends ConsumerStatefulWidget {
  final MediaType type;
  final String? selectedCategoryId;
  final Function(String)? onCategorySelected;

  const CategoryManager({
    super.key,
    required this.type,
    this.selectedCategoryId,
    this.onCategorySelected,
  });

  @override
  ConsumerState<CategoryManager> createState() => _CategoryManagerState();
}

class _CategoryManagerState extends ConsumerState<CategoryManager> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryService = ref.watch(categoryServiceProvider);
    final categories = categoryService.getCategoriesByType(widget.type);

    return Container(
      padding: const EdgeInsets.all(20),
      constraints: const BoxConstraints(minWidth: 400, maxWidth: 600),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '分类管理',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: IconButton(
                    onPressed: () => _showAddCategoryDialog(categoryService),
                    icon: const Icon(Icons.add),
                    tooltip: '新建分类',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: categories.map((category) {
              final isSelected = category.id == widget.selectedCategoryId;
              final isDefault = category.id == 'default_video' ||
                  category.id == 'default_audio';

              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(category.name,
                            style: const TextStyle(fontSize: 14)),
                        if (isDefault) ...[
                          const SizedBox(width: 6),
                          // const Icon(Icons.star, size: 14, color: Colors.amber),
                        ],
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected && widget.onCategorySelected != null) {
                        widget.onCategorySelected!(category.id);
                      }
                    },
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    selectedColor: theme.colorScheme.primaryContainer,
                    backgroundColor: theme.colorScheme.surface,
                    side: BorderSide(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(CategoryService categoryService) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建分类'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '分类名称',
            hintText: '请输入分类名称',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => AppRouter.pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                categoryService.createCategory(
                  name: name,
                  type: widget.type,
                );
                AppRouter.pop('create');
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
}

class CategorySelector extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final Function(String) onCategorySelected;

  const CategorySelector({
    super.key,
    required this.categories,
    this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (categories.isEmpty) {
      return const Center(
        child: Text('暂无分类'),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: categories.map((category) {
          final isSelected = category.id == selectedCategoryId;
          final isDefault =
              category.id == 'default_video' || category.id == 'default_audio';

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(category.name, style: const TextStyle(fontSize: 14)),
                      if (isDefault) ...[
                        const SizedBox(width: 6),
                        // const Icon(Icons.star, size: 14, color: Colors.amber),
                      ],
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      onCategorySelected(category.id);
                    }
                  },
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  selectedColor: theme.colorScheme.primaryContainer,
                  backgroundColor: theme.colorScheme.surface,
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  showCheckmark: false,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class CategoryEditDialog extends StatefulWidget {
  final Category category;
  final Function(String) onCategoryUpdated;

  const CategoryEditDialog({
    super.key,
    required this.category,
    required this.onCategoryUpdated,
  });

  @override
  State<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.category.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDefault = widget.category.id == 'default_video' ||
        widget.category.id == 'default_audio';

    return AlertDialog(
      title: const Text('编辑分类'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: '分类名称',
        ),
        enabled: !isDefault,
      ),
      actions: [
        if (!isDefault)
          TextButton(
            onPressed: () => _showDeleteConfirmDialog(),
            child: const Text('删除分类', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => AppRouter.pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final name = _controller.text.trim();
            if (name.isNotEmpty) {
              widget.onCategoryUpdated(name);
              AppRouter.pop();
            }
          },
          child: const Text('保存'),
        ),
      ],
    );
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除分类"${widget.category.name}"吗？该分类下的所有媒体文件将移动到默认分类。'),
        actions: [
          TextButton(
            onPressed: () => AppRouter.pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              AppRouter.pop('delete');
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

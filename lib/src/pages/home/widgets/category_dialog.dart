import 'package:elara_player/src/router/router.dart';
import 'package:flutter/material.dart';
import '../../../models/category.dart';
import '../../../models/media_item.dart';

/// 分类弹窗组件，支持创建和编辑分类
class CategoryDialog extends StatefulWidget {
  /// 分类（编辑模式下传入）
  final Category? category;
  
  /// 媒体类型（创建模式下传入）
  final MediaType? type;
  
  /// 分类服务回调
  final Future<void> Function({String? id, required String name, required MediaType type}) onSubmit;
  
  /// 删除分类回调
  final Future<void> Function(String id)? onDelete;

  const CategoryDialog({
    super.key,
    this.category,
    this.type,
    required this.onSubmit,
    this.onDelete,
  });

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  /// 分类名称控制器
  final TextEditingController _nameController = TextEditingController();
  
  /// 是否为默认分类
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    
    // 如果是编辑模式，初始化控制器和默认分类状态
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _isDefault = widget.category!.id == 'default_video' || widget.category!.id == 'default_audio';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// 显示删除确认弹窗
  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除分类"${widget.category!.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => AppRouter.pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              await widget.onDelete!(widget.category!.id);
              AppRouter.pop(); // 关闭确认弹窗
              AppRouter.pop(); // 关闭分类弹窗
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.category != null;
    final isDefault = _isDefault;

    return AlertDialog(
      title: Text(isEditMode ? '编辑分类' : '新建分类'),
      content: TextField(
        controller: _nameController,
        decoration: InputDecoration(
          labelText: '分类名称',
          hintText: isEditMode ? null : '请输入分类名称',
        ),
        autofocus: true,
        enabled: !isDefault,
      ),
      actions: [
        // 删除按钮（仅编辑模式且非默认分类显示）
        if (isEditMode && !isDefault && widget.onDelete != null) ...[
          TextButton(
            onPressed: () {
              _showDeleteConfirmDialog();
            },
            child: const Text('删除分类', style: TextStyle(color: Colors.red)),
          ),
        ],
        
        // 取消按钮
        TextButton(
          onPressed: () => AppRouter.pop(),
          child: const Text('取消'),
        ),
        
        // 确认按钮
        FilledButton(
          onPressed: () async {
            final name = _nameController.text.trim();
            if (name.isNotEmpty) {
              await widget.onSubmit(
                id: widget.category?.id,
                name: name,
                type: widget.category?.type ?? widget.type!,
              );
              AppRouter.pop(); // 关闭分类弹窗
            }
          },
          child: Text(isEditMode ? '保存' : '创建'),
        ),
      ],
    );
  }
}

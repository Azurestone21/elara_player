import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/category.dart';
import '../../../models/media_item.dart';
import '../../../router/router.dart';
import '../../../services/services.dart';

/// 媒体列表项
class MedioListTile extends StatelessWidget {
  final BuildContext context;
  final WidgetRef ref;
  final MediaType mediaType;
  final int index;
  final String id;
  final Widget? leadingChild;
  final String title;
  final String? subTitle;
  final Function() onSelected;

  const MedioListTile({
    super.key,
    required this.context,
    required this.ref,
    required this.mediaType,
    required this.index,
    required this.id,
    this.leadingChild,
    required this.title,
    this.subTitle,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: index % 2 == 1
            ? null
            : theme.sliderTheme.overlayColor?.withOpacity(0.04),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey[200],
          ),
          child: leadingChild,
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => onSelected(),
        trailing: PopupMenuButton<String>(
          tooltip: '',
          onSelected: (value) async {
            final categoryService = ref.read(categoryServiceProvider);

            if (value == 'move') {
              final categories = categoryService.getCategoriesByType(mediaType);
              if (categories.isNotEmpty) {
                final selectedCategory = await showDialog<Category>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('选择集合'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: categories.map((category) {
                        return ListTile(
                          title: Text(category.name),
                          onTap: () => AppRouter.pop(category),
                        );
                      }).toList(),
                    ),
                  ),
                );

                if (selectedCategory != null) {
                  categoryService.moveMediaItemToCategory(
                      id, selectedCategory.id);
                }
              }
            } else if (value == 'delete') {
              final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('确认删除'),
                      content: const Text('确定要删除这个视频吗？'),
                      actions: [
                        TextButton(
                          onPressed: () => AppRouter.pop(false),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () => AppRouter.pop(true),
                          child: const Text('删除'),
                        ),
                      ],
                    ),
                  ) ??
                  false;

              if (confirmed) {
                categoryService.removeMediaItem(id);
              }
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'move',
              child: Text('移动到集合'),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Text('删除'),
            ),
          ],
        ),
      ),
    );
  }
}

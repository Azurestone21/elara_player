import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elara_player/src/models/media_item.dart';
import 'package:elara_player/src/models/category.dart';
import 'package:elara_player/src/services/category_service.dart';
import 'package:elara_player/src/components/category_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

import '../components/add_primary_btn.dart';

class VideoTab extends ConsumerWidget {
  final CategoryService categoryService;
  final String selectedCategoryId;
  final String searchQuery;
  final Function(String) onCategorySelected;
  final Function(MediaItem) onVideoSelected;

  const VideoTab({
    Key? key,
    required this.categoryService,
    required this.selectedCategoryId,
    required this.searchQuery,
    required this.onCategorySelected,
    required this.onVideoSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildMediaList(
      context,
      ref,
      categoryService,
      selectedCategoryId,
      searchQuery,
      onCategorySelected,
      onVideoSelected,
    );
  }

  Widget _buildMediaList(
    BuildContext context,
    WidgetRef ref,
    CategoryService categoryService,
    String selectedCategoryId,
    String searchQuery,
    Function(String) onCategorySelected,
    Function(MediaItem) onMediaSelected,
  ) {
    final mediaItems = categoryService
        .getMediaItemsByCategory(selectedCategoryId)
        .where((item) =>
            item.title.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildAddButtons(context, ref),
            const SizedBox(width: 16),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _buildVideoList(context, ref, mediaItems, onMediaSelected),
        ),
      ],
    );
  }

  Widget _buildAddButtons(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AddPrimaryBtn(
            icon: Icons.add,
            onPressed: () => _pickFiles(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFiles(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.video,
    );

    if (result != null) {
      final categoryService = ref.read(categoryServiceProvider);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      for (int i = 0; i < result.files.length; i++) {
        final file = result.files[i];
        if (file.path != null) {
          final mediaItem = MediaItem(
            id: '$timestamp-$i',
            title: path.basenameWithoutExtension(file.name),
            artist: 'Unknown',
            uri: file.path!,
            type: MediaType.video,
          );
          categoryService.addMediaItem(mediaItem,
              categoryId: selectedCategoryId);
        }
      }
    }
  }

  Widget _buildVideoList(
    BuildContext context,
    WidgetRef ref,
    List<MediaItem> mediaItems,
    Function(MediaItem) onVideoSelected,
  ) {
    if (mediaItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text('没有视频'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: mediaItems.length,
      itemBuilder: (context, index) {
        final item = mediaItems[index];
        return _buildVideoItem(context, ref, item, onVideoSelected);
      },
    );
  }

  Widget _buildVideoItem(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
    Function(MediaItem) onVideoSelected,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.grey[200],
        ),
        child: const Icon(Icons.play_circle, size: 20, color: Colors.grey),
      ),
      title: Text(
        item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => onVideoSelected(item),
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          final categoryService = ref.read(categoryServiceProvider);

          if (value == 'move') {
            final categories =
                categoryService.getCategoriesByType(MediaType.video);
            if (categories.isNotEmpty) {
              final selectedCategory = await showDialog<Category>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('选择分类'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: categories.map((category) {
                      return ListTile(
                        title: Text(category.name),
                        onTap: () => Navigator.pop(context, category),
                      );
                    }).toList(),
                  ),
                ),
              );

              if (selectedCategory != null) {
                categoryService.moveMediaItemToCategory(
                    item.id, selectedCategory.id);
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
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('删除'),
                      ),
                    ],
                  ),
                ) ??
                false;

            if (confirmed) {
              categoryService.removeMediaItem(item.id);
            }
          }
        },
        itemBuilder: (BuildContext context) => [
          const PopupMenuItem<String>(
            value: 'move',
            child: Text('移动到分类'),
          ),
          const PopupMenuItem<String>(
            value: 'delete',
            child: Text('删除'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elara_player/src/models/media_item.dart';
import 'package:elara_player/src/models/category.dart';
import 'package:elara_player/src/services/category_service.dart';
import 'package:elara_player/src/services/player_controller.dart';
import 'package:elara_player/src/components/category_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:audiotags/audiotags.dart';

class MusicTab extends ConsumerWidget {
  final CategoryService categoryService;
  final String selectedCategoryId;
  final String searchQuery;
  final Function(String) onCategorySelected;
  final Function(MediaItem) onMusicSelected;

  const MusicTab({
    Key? key,
    required this.categoryService,
    required this.selectedCategoryId,
    required this.searchQuery,
    required this.onCategorySelected,
    required this.onMusicSelected,
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
      onMusicSelected,
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
          child: _buildMusicList(context, ref, mediaItems, onMediaSelected),
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
          ElevatedButton.icon(
            onPressed: () => _pickFiles(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('添加歌曲'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFiles(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.audio,
    );

    if (result != null) {
      final categoryService = ref.read(categoryServiceProvider);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      for (int i = 0; i < result.files.length; i++) {
        final file = result.files[i];
        if (file.path != null) {
          String title = path.basenameWithoutExtension(file.name);
          String artist = '未知';
          String album = '未知';

          // 从音频文件中提取元数据
          try {
            final tags = await AudioTags.read(file.path!);
            if (tags != null) {
              if (tags.title != null && tags.title!.isNotEmpty) {
                title = tags.title!;
              }
              if (tags.trackArtist != null && tags.trackArtist!.isNotEmpty) {
                artist = tags.trackArtist!;
              }
              if (tags.album != null && tags.album!.isNotEmpty) {
                album = tags.album!;
              }
            }
          } catch (e) {
            // 如果提取失败，使用文件名作为标题
            print('提取音频元数据失败: $e');
          }

          final mediaItem = MediaItem(
            id: '$timestamp-$i',
            title: title,
            artist: artist,
            album: album,
            uri: file.path!,
            type: MediaType.audio,
          );
          categoryService.addMediaItem(mediaItem,
              categoryId: selectedCategoryId);
          
          // 更新播放列表
          final controller = ref.read(playerControllerProvider);
          final categoryItems = categoryService.getMediaItemsByCategory(selectedCategoryId);
          controller.setPlaylistItems(categoryItems);
        }
      }
    }
  }

  Widget _buildMusicList(
    BuildContext context,
    WidgetRef ref,
    List<MediaItem> mediaItems,
    Function(MediaItem) onMusicSelected,
  ) {
    if (mediaItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text('没有歌曲'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: mediaItems.length,
      itemBuilder: (context, index) {
        final item = mediaItems[index];
        return _buildMusicItem(context, ref, item, onMusicSelected);
      },
    );
  }

  Widget _buildMusicItem(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
    Function(MediaItem) onMusicSelected,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.grey[200],
        ),
        child: const Icon(Icons.music_note, size: 20, color: Colors.grey),
      ),
      title: Text(
        item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        item.artist ?? 'Unknown Artist',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      onTap: () => onMusicSelected(item),
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          final categoryService = ref.read(categoryServiceProvider);

          if (value == 'move') {
            final categories =
                categoryService.getCategoriesByType(MediaType.audio);
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
                    content: const Text('确定要删除这首歌吗？'),
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

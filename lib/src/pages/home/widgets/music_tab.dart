import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:audiotags/audiotags.dart';

import '../../../src.dart';
import 'medio_list_tile.dart';

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
          final categoryItems =
              categoryService.getMediaItemsByCategory(selectedCategoryId);
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
      return const EmptyState(
        message: '没有歌曲',
        icon: Icons.music_note_outlined,
      );
    }

    return ListView.builder(
      itemCount: mediaItems.length,
      itemBuilder: (context, index) {
        final item = mediaItems[index];
        return _buildMusicItem(context, ref, item, index, onMusicSelected);
      },
    );
  }

  Widget _buildMusicItem(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
    int index,
    Function(MediaItem) onMusicSelected,
  ) {
    return MedioListTile(
      context: context,
      ref: ref,
      mediaType: MediaType.audio,
      index: index,
      id: item.id,
      title: item.title,
      subTitle: item.artist,
      leadingChild: const Icon(Icons.music_note, size: 20, color: Colors.grey),
      onSelected: () => onMusicSelected(item),
    );
  }
}

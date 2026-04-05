import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:elara_player/src/src.dart';
import 'widgets/video_tab.dart';
import 'widgets/music_tab.dart';
import 'widgets/category_dialog.dart';

/// 首页组件
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

/// 首页状态管理
class _HomePageState extends ConsumerState<HomePage> {
  /// 当前选中的标签页 (0: 视频, 1: 音乐)
  int _currentTab = 1;

  /// 选中的视频分类ID
  String? _selectedVideoCategoryId;

  /// 选中的音频分类ID
  String? _selectedAudioCategoryId;

  /// 侧边栏是否展开
  bool _sidebarExpanded = true;

  /// 搜索查询
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeDefaultCategories();
  }

  void _initializeDefaultCategories() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categoryService = ref.read(categoryServiceProvider);

      final videoCategories =
          categoryService.getCategoriesByType(MediaType.video);
      if (videoCategories.isNotEmpty && _selectedVideoCategoryId == null) {
        setState(() {
          _selectedVideoCategoryId = videoCategories.first.id;
        });
      }

      final audioCategories =
          categoryService.getCategoriesByType(MediaType.audio);
      if (audioCategories.isNotEmpty && _selectedAudioCategoryId == null) {
        setState(() {
          _selectedAudioCategoryId = audioCategories.first.id;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryService = ref.watch(categoryServiceProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: UniversalPlatform.isWindows
            ? WindowsAppBar(
                hideBackButton: true,
                leftWidget: Row(
                  children: [
                    // 切换播放模式
                    _buildTogglePlayerMode(),
                    // Expanded(child: _buildSearchBar()),
                    const SizedBox(width: 8),
                    // 搜索栏
                    CustomSearchBar(
                      onChange: (query) {
                        setState(() {
                          _searchQuery = query;
                        });
                      },
                     ),
                  ],
                ))
            : AppBar(
                title: const Text('Elara Player'),
                bottom: TabBar(
                  onTap: (index) => setState(() => _currentTab = index),
                  tabs: const [
                    Tab(text: 'Videos'),
                    Tab(text: 'Music'),
                  ],
                ),
              ),
        body: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  if (_sidebarExpanded)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 260,
                      color: theme.colorScheme.surface,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '分类',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () => _showCategoryDialog(
                                        type: _currentTab == 0
                                            ? MediaType.video
                                            : MediaType.audio,
                                        categoryService: categoryService),
                                    child: Icon(
                                      Icons.add,
                                      size: 14,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _buildSidebar(categoryService),
                          ),
                        ],
                      ),
                    ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _sidebarExpanded = !_sidebarExpanded;
                        });
                      },
                      child: Container(
                        width: 20,
                        color: theme.colorScheme.surface,
                        child: Center(
                          child: Icon(
                            _sidebarExpanded
                                ? Icons.chevron_left
                                : Icons.chevron_right,
                            size: 16,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _currentTab == 0
                        ? _buildVideoTab(categoryService)
                        : _buildMusicTab(categoryService),
                  ),
                ],
              ),
            ),
            if (_currentTab == 1) // Only show player controls for Music tab
              _buildMusicPlayerControls(),
          ],
        ),
      ),
    );
  }

  // 切换播放模式组件
  Widget _buildTogglePlayerMode() {
    final theme = Theme.of(context);
    return Container(
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => _currentTab = 1),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _currentTab == 1
                      ? theme.colorScheme.primary
                      // .withOpacity(0.7)
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: Text(
                  'Music',
                  style: TextStyle(
                    fontSize: 12,
                    color: _currentTab == 1
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                    fontWeight:
                        _currentTab == 1 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => _currentTab = 0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _currentTab == 0
                      ? theme.colorScheme.primary
                      // .withOpacity(0.7)
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Text(
                  'Videos',
                  style: TextStyle(
                    fontSize: 12,
                    color: _currentTab == 0
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                    fontWeight:
                        _currentTab == 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 侧边栏组件
  Widget _buildSidebar(CategoryService categoryService) {
    final theme = Theme.of(context);

    final currentType = _currentTab == 0 ? MediaType.video : MediaType.audio;
    final categories = categoryService.getCategoriesByType(currentType);
    final selectedCategoryId =
        _currentTab == 0 ? _selectedVideoCategoryId : _selectedAudioCategoryId;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 0),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = category.id == selectedCategoryId;
        final isDefault =
            category.id == 'default_video' || category.id == 'default_audio';

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          height: 40,
          child: InkWell(
            onTap: () {
              setState(() {
                if (_currentTab == 0) {
                  _selectedVideoCategoryId = category.id;
                } else {
                  _selectedAudioCategoryId = category.id;

                  // 切换音频分类时，更新播放列表
                  final controller = ref.read(playerControllerProvider);
                  final categoryItems =
                      categoryService.getMediaItemsByCategory(category.id);
                  controller.setPlaylistItems(categoryItems);
                }
              });
            },
            hoverColor: !isSelected ? const Color(0xFFF0E6F6) : null,
            child: ListTile(
              minVerticalPadding: 0,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (isDefault) ...[
                    const SizedBox(width: 4),
                    // const Icon(Icons.star, size: 16, color: Colors.amber),
                  ],
                  if (!isDefault) ...[
                    const SizedBox(width: 4),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _showCategoryDialog(
                            category: category,
                            categoryService: categoryService),
                        child: Icon(
                          Icons.edit,
                          size: 10,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              selected: isSelected,
              selectedTileColor:
                  theme.colorScheme.primaryContainer.withOpacity(0.3),
            ),
          ),
        );
      },
    );
  }

  /// 视频标签组件
  Widget _buildVideoTab(CategoryService categoryService) {
    if (_selectedVideoCategoryId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return VideoTab(
      categoryService: categoryService,
      selectedCategoryId: _selectedVideoCategoryId!,
      searchQuery: _searchQuery,
      onCategorySelected: (id) => setState(() => _selectedVideoCategoryId = id),
      onVideoSelected: (item) => _navigateToPlayer(item),
    );
  }

  /// 音乐标签组件
  Widget _buildMusicTab(CategoryService categoryService) {
    if (_selectedAudioCategoryId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return MusicTab(
      categoryService: categoryService,
      selectedCategoryId: _selectedAudioCategoryId!,
      searchQuery: _searchQuery,
      onCategorySelected: (id) => setState(() => _selectedAudioCategoryId = id),
      onMusicSelected: (item) => _navigateToMusicDetail(item),
    );
  }

  void _openMusicDetailFromControls() {
    final controller = ref.read(playerControllerProvider);
    final currentItem = controller.state.currentItem;

    if (currentItem == null || currentItem.type != MediaType.audio) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MusicPlayerPage(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }

  void _navigateToPlayer(MediaItem item) {
    final controller = ref.read(playerControllerProvider);
    final categoryService = ref.read(categoryServiceProvider);

    // 获取当前分类的所有视频项目
    final categoryItems =
        categoryService.getMediaItemsByCategory(_selectedVideoCategoryId!);

    // 设置播放列表，从当前选中的视频开始播放
    final startIndex = categoryItems.indexOf(item);
    controller.setPlaylistItems(categoryItems,
        startIndex: startIndex >= 0 ? startIndex : 0);

    AppRouter.push(Routes.videoPlayer, arguments: {
      'playlist': categoryItems,
      'startIndex': startIndex,
    });
  }

  void _navigateToMusicDetail(MediaItem item) {
    final controller = ref.read(playerControllerProvider);
    final categoryService = ref.read(categoryServiceProvider);

    // 获取当前分类的所有歌曲
    final categoryItems =
        categoryService.getMediaItemsByCategory(_selectedAudioCategoryId!);

    // 设置播放列表，从当前选中的歌曲开始播放
    final startIndex = categoryItems.indexOf(item);
    controller.setPlaylistItems(categoryItems,
        startIndex: startIndex >= 0 ? startIndex : 0);

    // 播放选中的歌曲
    controller.playMedia(item, autoPlay: true);
  }

  /// 新增/编辑分类弹窗
  void _showCategoryDialog({
    Category? category,
    MediaType? type,
    required CategoryService categoryService,
  }) {
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        category: category,
        type: type,
        onSubmit: (
            {String? id, required String name, required MediaType type}) async {
          if (id != null) {
            // 编辑分类
            categoryService.updateCategory(
              id: id,
              name: name,
            );
          } else {
            // 创建分类
            final newCategory = categoryService.createCategory(
              name: name,
              type: type,
            );
            setState(() {
              if (type == MediaType.video) {
                _selectedVideoCategoryId = newCategory.id;
              } else {
                _selectedAudioCategoryId = newCategory.id;
              }
            });
          }
        },
        onDelete: category != null
            ? (id) async {
                categoryService.deleteCategory(id);
                setState(() {
                  if (category.type == MediaType.video) {
                    final videoCategories =
                        categoryService.getCategoriesByType(MediaType.video);
                    if (videoCategories.isNotEmpty) {
                      _selectedVideoCategoryId = videoCategories.first.id;
                    } else {
                      _selectedVideoCategoryId = null;
                    }
                  } else {
                    final audioCategories =
                        categoryService.getCategoriesByType(MediaType.audio);
                    if (audioCategories.isNotEmpty) {
                      _selectedAudioCategoryId = audioCategories.first.id;
                    } else {
                      _selectedAudioCategoryId = null;
                    }
                  }
                });
              }
            : null,
      ),
    );
  }

  Widget _buildMusicPlayerControls() {
    final theme = Theme.of(context);
    final playerController = ref.watch(playerControllerProvider);
    final state = playerController.state;

    return GestureDetector(
      onTap: () {
        if (state.currentItem != null &&
            state.currentItem!.type == MediaType.audio) {
          _openMusicDetailFromControls();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
              top: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.3))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 进度条
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ProgressBarWithTime(
                position: state.position,
                duration: state.duration,
                buffered: state.buffered,
                onSeek: (position) => playerController.seek(position),
              ),
            ),
            // 控制按钮
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Album art and song info
                  if (state.currentItem != null)
                    Row(
                      children: [
                        Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: theme.colorScheme.secondaryContainer,
                            ),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: state.currentItem!.thumbnailUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(
                                        state.currentItem!.thumbnailUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _buildMusicPlaceholder(),
                                      ),
                                    )
                                  : _buildMusicPlaceholder(),
                            )),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.currentItem!.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              state.currentItem!.artist ?? 'Unknown Artist',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Container(width: 160),
                  const Spacer(),
                  // Playback controls
                  Row(
                    children: [
                      // Play mode
                      IconButton(
                        onPressed: playerController.cyclePlayMode,
                        icon: Icon(
                          _getPlayModeIcon(state.playMode),
                          size: 18,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 上一个按钮
                      IconButton(
                        onPressed: state.hasPrevious
                            ? playerController.previous
                            : null,
                        icon: Icon(
                          Icons.skip_previous,
                          size: 24,
                          color: state.hasPrevious
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 播放/暂停按钮
                      IconButton(
                        onPressed: state.currentItem != null
                            ? playerController.togglePlayPause
                            : null,
                        icon: Icon(
                          state.isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 32,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 下一个按钮
                      IconButton(
                        onPressed: state.hasNext ? playerController.next : null,
                        icon: Icon(
                          Icons.skip_next,
                          size: 24,
                          color: state.hasNext
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const Spacer(),
                  // 音量控制
                  Row(
                    children: [
                      // 静音按钮
                      IconButton(
                        onPressed: playerController.toggleMute,
                        icon: Icon(
                          state.isMuted ? Icons.volume_off : Icons.volume_up,
                          size: 18,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      // 音量滑块
                      SizedBox(
                        width: 100,
                        child: Slider(
                          value: state.volume,
                          onChanged: (value) =>
                              playerController.setVolume(value),
                          min: 0.0,
                          max: 1.0,
                          activeColor: theme.colorScheme.primary,
                          inactiveColor:
                              theme.colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicPlaceholder() {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.secondaryContainer,
      child: Icon(
        Icons.music_note,
        size: 24,
        color: theme.colorScheme.onSecondaryContainer,
      ),
    );
  }

  IconData _getPlayModeIcon(PlayMode mode) {
    switch (mode) {
      case PlayMode.sequence:
        return Icons.play_arrow;
      case PlayMode.loop:
        return Icons.repeat;
      case PlayMode.singleLoop:
        return Icons.repeat_one;
      case PlayMode.shuffle:
        return Icons.shuffle;
    }
  }
}

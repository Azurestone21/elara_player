import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:window_manager/window_manager.dart';

import '../models/models.dart';
import '../services/services.dart';
import '../components/components.dart';
import '../widgets/widgets.dart';
import 'player_page.dart';
import 'music_detail_page.dart';
import 'video_tab.dart';
import 'music_tab.dart';

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
      
      final videoCategories = categoryService.getCategoriesByType(MediaType.video);
      if (videoCategories.isNotEmpty && _selectedVideoCategoryId == null) {
        setState(() {
          _selectedVideoCategoryId = videoCategories.first.id;
        });
      }
      
      final audioCategories = categoryService.getCategoriesByType(MediaType.audio);
      if (audioCategories.isNotEmpty && _selectedAudioCategoryId == null) {
        setState(() {
          _selectedAudioCategoryId = audioCategories.first.id;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryService = ref.watch(categoryServiceProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: UniversalPlatform.isWindows
            ? _buildWindowsAppBar()
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
                      color: Theme.of(context).colorScheme.surface,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '分类',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () => _showAddCategoryDialog(_currentTab == 0 ? MediaType.video : MediaType.audio, categoryService),
                                    child: Icon(
                                      Icons.add,
                                      size: 14,
                                      color: Theme.of(context).colorScheme.primary,
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
                        color: Theme.of(context).colorScheme.surface,
                        child: Center(
                          child: Icon(
                            _sidebarExpanded ? Icons.chevron_left : Icons.chevron_right,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface,
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

  PreferredSizeWidget _buildWindowsAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(40),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).appBarTheme.backgroundColor,
          border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onPanStart: (details) => windowManager.startDragging(),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Text(
                    'Elara Player',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Container(
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => setState(() => _currentTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _currentTab == 1 
                                    ? Theme.of(context).colorScheme.primary.withOpacity(0.7) 
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
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: _currentTab == 1 ? FontWeight.w600 : FontWeight.normal,
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
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _currentTab == 0 
                                    ? Theme.of(context).colorScheme.primary.withOpacity(0.7) 
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
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: _currentTab == 0 ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                onPanStart: (details) => windowManager.startDragging(),
                child: Center(
                  child: Container(
                    width: 200,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(
                          Icons.search,
                          size: 14,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '搜索...',
                              hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 12),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Icon(Icons.clear, size: 14, color: Colors.grey[400]),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () => windowManager.minimize(),
                  icon: const Icon(Icons.remove, size: 16),
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  tooltip: '最小化',
                ),
                IconButton(
                  onPressed: () async {
                    if (await windowManager.isMaximized()) {
                      await windowManager.unmaximize();
                    } else {
                      await windowManager.maximize();
                    }
                  },
                  icon: const Icon(Icons.square_outlined, size: 16),
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  tooltip: '最大化',
                ),
                IconButton(
                  onPressed: () => windowManager.close(),
                  icon: const Icon(Icons.close, size: 16),
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  tooltip: '关闭',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(CategoryService categoryService) {
    final currentType = _currentTab == 0 ? MediaType.video : MediaType.audio;
    final categories = categoryService.getCategoriesByType(currentType);
    final selectedCategoryId = _currentTab == 0 ? _selectedVideoCategoryId : _selectedAudioCategoryId;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 0),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = category.id == selectedCategoryId;
        final isDefault = category.id == 'default_video' || category.id == 'default_audio';

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
                }
              });
            },
            hoverColor: !isSelected ? const Color(0xFFF0E6F6) : null,
            child: ListTile(
              minVerticalPadding: 0,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary 
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (isDefault) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                  ],
                  if (!isDefault) ...[
                    const SizedBox(width: 4),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _showEditCategoryDialog(category, categoryService),
                        child: Icon(
                          Icons.edit,
                          size: 10,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              selected: isSelected,
              selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            ),
          ),
        );
      },
    );
  }

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
        pageBuilder: (context, animation, secondaryAnimation) => const MusicDetailPage(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
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
    controller.playMedia(item, autoPlay: true);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerPage(
          playlist: [item],
          startIndex: 0,
        ),
      ),
    );
  }

  void _navigateToMusicDetail(MediaItem item) {
    final controller = ref.read(playerControllerProvider);
    controller.playMedia(item, autoPlay: true);
  }

  void _showAddCategoryDialog(MediaType type, CategoryService categoryService) {
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
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
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
                Navigator.pop(context);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(Category category, CategoryService categoryService) {
    final controller = TextEditingController(text: category.name);
    final isDefault = category.id == 'default_video' || category.id == 'default_audio';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑分类'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '分类名称',
          ),
          enabled: !isDefault,
        ),
        actions: [
          if (!isDefault)
            TextButton(
              onPressed: () => _showDeleteConfirmDialog(category, categoryService),
              child: const Text('删除分类', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                categoryService.updateCategory(
                  id: category.id,
                  name: name,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(Category category, CategoryService categoryService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除分类"${category.name}"吗？该分类下的所有媒体文件将移动到默认分类。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              categoryService.deleteCategory(category.id);
              setState(() {
                if (category.type == MediaType.video) {
                  final videoCategories = categoryService.getCategoriesByType(MediaType.video);
                  if (videoCategories.isNotEmpty) {
                    _selectedVideoCategoryId = videoCategories.first.id;
                  } else {
                    _selectedVideoCategoryId = null;
                  }
                } else {
                  final audioCategories = categoryService.getCategoriesByType(MediaType.audio);
                  if (audioCategories.isNotEmpty) {
                    _selectedAudioCategoryId = audioCategories.first.id;
                  } else {
                    _selectedAudioCategoryId = null;
                  }
                }
              });
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }



  Widget _buildMusicPlayerControls() {
    final playerController = ref.watch(playerControllerProvider);
    final state = playerController.state;

    return GestureDetector(
      onTap: () {
        if (state.currentItem != null && state.currentItem!.type == MediaType.audio) {
          _openMusicDetailFromControls();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.3))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ProgressBarWithTime(
                position: state.position,
                duration: state.duration,
                buffered: state.buffered,
                onSeek: (position) => playerController.seek(position),
              ),
            ),
            // Controls
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
                            color: Theme.of(context).colorScheme.secondaryContainer,
                          ),
                          child: state.currentItem!.thumbnailUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    state.currentItem!.thumbnailUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildMusicPlaceholder(),
                                  ),
                                )
                              : _buildMusicPlaceholder(),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.currentItem!.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              state.currentItem!.artist ?? 'Unknown Artist',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Previous
                      IconButton(
                        onPressed: state.hasPrevious ? playerController.previous : null,
                        icon: Icon(
                          Icons.skip_previous,
                          size: 24,
                          color: state.hasPrevious 
                              ? Theme.of(context).colorScheme.onSurface 
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Play/pause
                      IconButton(
                        onPressed: state.currentItem != null ? playerController.togglePlayPause : null,
                        icon: Icon(
                          state.isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 32,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Next
                      IconButton(
                        onPressed: state.hasNext ? playerController.next : null,
                        icon: Icon(
                          Icons.skip_next,
                          size: 24,
                          color: state.hasNext 
                              ? Theme.of(context).colorScheme.onSurface 
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Shuffle
                      IconButton(
                        onPressed: playerController.toggleShuffle,
                        icon: Icon(
                          Icons.shuffle,
                          size: 18,
                          color: state.isShuffleEnabled 
                              ? Theme.of(context).colorScheme.primary 
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Volume control
                  Row(
                    children: [
                      IconButton(
                        onPressed: playerController.toggleMute,
                        icon: Icon(
                          state.isMuted ? Icons.volume_off : Icons.volume_up,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Container(
                        width: 100,
                        child: Slider(
                          value: state.volume,
                          onChanged: (value) => playerController.setVolume(value),
                          min: 0.0,
                          max: 1.0,
                          activeColor: Theme.of(context).colorScheme.primary,
                          inactiveColor: Theme.of(context).colorScheme.outline.withOpacity(0.3),
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
    return Container(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Icon(
        Icons.music_note,
        size: 24,
        color: Theme.of(context).colorScheme.onSecondaryContainer,
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

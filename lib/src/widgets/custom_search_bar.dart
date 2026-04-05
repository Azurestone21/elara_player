import 'package:flutter/material.dart';

/// 自定义搜索栏（可展开/收起）
class CustomSearchBar extends StatefulWidget {
  final Function(String) onChange;
  const CustomSearchBar({super.key, required this.onChange});

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  String _searchText = '';
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChange);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _searchText = _textController.text;
    });
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isExpanded && _searchText.isEmpty) {
      _collapse();
    }
  }

  void _expand() {
    if (_isExpanded) return;
    setState(() {
      _isExpanded = true;
      _textController.clear();
      _searchText = '';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNode.canRequestFocus) _focusNode.requestFocus();
    });
  }

  void _collapse() {
    if (!_isExpanded) return;
    _textController.clear();
    setState(() {
      _isExpanded = false;
      _searchText = '';
    });
    if (_focusNode.hasFocus) _focusNode.unfocus();
  }

  void _performSearch(Function(String) onChange) {
    if (_searchText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入搜索内容'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('搜索: $_searchText'),
          duration: const Duration(seconds: 2)),
    );
    onChange(_searchText);
  }

  void _clearText(Function(String) onChange) {
    if (_searchText.isNotEmpty) _textController.clear();
    onChange('');
  }

  @override
  Widget build(BuildContext context) {
    // MouseRegion（用于检测鼠标离开），内部使用 AnimatedContainer
    // 未展开时的宽度：26（图标按钮大小） + 左右边距，展开时宽度 280
    // 当 _isExpanded 变化时，AnimatedContainer 会自动执行宽度动画
    return MouseRegion(
      onExit: (_) {
        if (_searchText.isEmpty && _isExpanded) _collapse();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: _isExpanded ? 280 : 28,
        height: 28,
        alignment: Alignment.centerLeft, // 左对齐，保证左侧位置不动
        child: Container(
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[700]!
                  : Colors.grey[300]!,
            ),
          ),
          child: _isExpanded
              ? _buildExpandedContent(onChange: widget.onChange)
              : _buildCollapsedContent(),
        ),
      ),
    );
  }

  /// 未展开时：只显示搜索图标
  Widget _buildCollapsedContent() {
    return IconButton(
      icon: const Icon(Icons.search, size: 20),
      onPressed: () => _expand(),
      tooltip: '搜索',
      splashRadius: 18,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
    );
  }

  /// 展开时：显示输入框、清空按钮等
  Widget _buildExpandedContent({required Function(String) onChange}) {
    return Row(
      children: [
        const SizedBox(
          width: 24,
          child: Icon(Icons.search, size: 18, color: Colors.grey),
        ),
        Expanded(
          child: TextField(
            controller: _textController,
            focusNode: _focusNode,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '搜索...',
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
            onSubmitted: (_) => _performSearch(onChange),
          ),
        ),
        if (_searchText.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear, size: 16),
            onPressed: () => _clearText(onChange),
            tooltip: '清空',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            splashRadius: 18,
          ),
      ],
    );
  }
}

// windows/main_window.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../mini_player/mini_player_page.dart';
import 'widgets/window_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: appState.isMiniMode
          ? MiniPlayer(
              onRestore: () {
                ref.read(appStateProvider.notifier).exitMiniMode();
              },
            )
          : const WindowPage(),
    );
  }
}

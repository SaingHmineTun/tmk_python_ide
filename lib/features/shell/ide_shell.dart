import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../editor/editor_screen.dart';
import '../programs/programs_screen.dart';
import '../settings/settings_screen.dart';

class IdeShell extends ConsumerStatefulWidget {
  const IdeShell({super.key});

  @override
  ConsumerState<IdeShell> createState() => _IdeShellState();
}

class _IdeShellState extends ConsumerState<IdeShell>
    with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      ref.read(editorSessionProvider).restore();
      ref.read(runtimeControllerProvider).initialize();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      ref.read(editorSessionProvider).flush();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final runtime = ref.watch(runtimeControllerProvider);
    final wide = MediaQuery.sizeOf(context).width >= 800;
    final pages = [
      const EditorScreen(),
      ProgramsScreen(onOpen: () => setState(() => _index = 0)),
      const SettingsScreen(),
    ];
    return Stack(
      children: [
        Scaffold(
          body: wide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _index,
                      onDestinationSelected: (value) =>
                          setState(() => _index = value),
                      labelType: NavigationRailLabelType.all,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.code),
                          label: Text('Editor'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.folder_outlined),
                          label: Text('Files'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.settings_outlined),
                          label: Text('Settings'),
                        ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: IndexedStack(index: _index, children: pages),
                    ),
                  ],
                )
              : IndexedStack(index: _index, children: pages),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (value) =>
                      setState(() => _index = value),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.code),
                      label: 'Editor',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.folder_outlined),
                      label: 'Files',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      label: 'Settings',
                    ),
                  ],
                ),
        ),
        Positioned(left: 0, top: 0, child: runtime.runtime.hostView),
      ],
    );
  }
}

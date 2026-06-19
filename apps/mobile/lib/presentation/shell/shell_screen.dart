import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Minimal shell wrapper — handles bottom navigation via GoRouter location.
class ShellScreen extends ConsumerStatefulWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexForLocation(location);
    if (index != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedIndex = index);
      });
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: colorScheme.surface,
            indicatorColor: colorScheme.primaryContainer.withOpacity(0.7),
            labelTextStyle: WidgetStatePropertyAll(
              Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
        ),
        child: NavigationBar(
          height: 64,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) {
            setState(() => _selectedIndex = i);
            final routes = ['/', '/action', '/maintenance', '/profile'];
            context.go(routes[i]);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.spa_outlined),
              selectedIcon: Icon(Icons.spa),
              label: '首页',
            ),
            NavigationDestination(
              icon: Icon(Icons.bolt_outlined),
              selectedIcon: Icon(Icons.bolt),
              label: '行动',
            ),
            NavigationDestination(
              icon: Icon(Icons.shield_outlined),
              selectedIcon: Icon(Icons.shield),
              label: '维持',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }

  int _indexForLocation(String location) {
    if (location.startsWith('/action')) return 1;
    if (location.startsWith('/maintenance')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }
}

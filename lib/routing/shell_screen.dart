import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/l10n_extension.dart';

class ShellScreen extends StatefulWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int? _currentIndex;
  int _previousIndex = 0;

  int _getRouteIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/groups')) return 0;
    if (location.startsWith('/activity')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final newIndex = _getRouteIndex(context);
    
    if (_currentIndex == null) {
      _currentIndex = newIndex;
      _previousIndex = newIndex;
    } else if (newIndex != _currentIndex) {
      _previousIndex = _currentIndex!;
      _currentIndex = newIndex;
    }

    final isGoingRight = _currentIndex! >= _previousIndex;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final isPushedChild = (child.key as ValueKey<int>).value == _currentIndex;
          final direction = isGoingRight ? 1.0 : -1.0;
          
          final offsetAnimation = Tween<Offset>(
            begin: Offset(isPushedChild ? direction : -direction, 0.0),
            end: Offset.zero,
          ).animate(animation);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex!),
          child: widget.child,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: context.colors.border, width: 0.5),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex ?? 0,
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                context.go('/groups');
                break;
              case 1:
                context.go('/activity');
                break;
              case 2:
                context.go('/profile');
                break;
            }
          },
          backgroundColor: context.colors.surface,
          indicatorColor: context.colors.primary.withValues(alpha: 0.15),
          surfaceTintColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.groups_outlined, color: context.colors.textTertiary),
              selectedIcon: Icon(Icons.groups, color: context.colors.primary),
              label: l10n.groups,
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined, color: context.colors.textTertiary),
              selectedIcon: Icon(Icons.receipt_long, color: context.colors.primary),
              label: l10n.activity,
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, color: context.colors.textTertiary),
              selectedIcon: Icon(Icons.person, color: context.colors.primary),
              label: l10n.profile,
            ),
          ],
        ),
      ),
    );
  }
}

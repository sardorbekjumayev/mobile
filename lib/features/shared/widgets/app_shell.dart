import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../l10n/strings.dart';

/// One tab of the bottom bar.
class ShellTab {
  const ShellTab({required this.icon, required this.activeIcon, required this.label});

  final IconData icon;
  final IconData activeIcon;

  /// Resolved per build rather than stored: the label follows the user's
  /// language, which can change without the app restarting.
  final String Function(S s) label;
}

/// The frame both roles live in: an [IndexedStack] of branches plus the bottom
/// bar that switches them.
///
/// Detail screens — a test, a group, a register — are pushed above this shell
/// rather than into it, so the bar disappears exactly where a back arrow takes
/// over.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell, required this.tabs});

  final StatefulNavigationShell shell;
  final List<ShellTab> tabs;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final brand = context.brand;

    return Scaffold(
      body: SafeArea(bottom: false, child: shell),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _TabButton(
                      tab: tabs[i],
                      label: tabs[i].label(s),
                      selected: shell.currentIndex == i,
                      color: brand.primary,
                      // `initialLocation: true` on a re-tap pops the branch back
                      // to its root, which is what a second tap on the tab you
                      // are already in is asking for.
                      onTap: () => shell.goBranch(i, initialLocation: i == shell.currentIndex),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final ShellTab tab;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppShapes.pillRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? tab.activeIcon : tab.icon,
              size: 22,
              color: selected ? color : AppColors.faint,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? color : AppColors.faint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Student: home · tests · rating · profile.
const studentTabs = <ShellTab>[
  ShellTab(
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: _homeLabel,
  ),
  ShellTab(
    icon: Icons.fact_check_outlined,
    activeIcon: Icons.fact_check_rounded,
    label: _testsLabel,
  ),
  ShellTab(
    icon: Icons.emoji_events_outlined,
    activeIcon: Icons.emoji_events_rounded,
    label: _rankLabel,
  ),
  ShellTab(
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    label: _profileLabel,
  ),
];

/// Teacher: home · groups · tests · profile. The register is not a tab — it
/// belongs to one group on one date, and hangs off the group instead.
const teacherTabs = <ShellTab>[
  ShellTab(
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: _homeLabel,
  ),
  ShellTab(
    icon: Icons.groups_2_outlined,
    activeIcon: Icons.groups_2_rounded,
    label: _groupsLabel,
  ),
  ShellTab(
    icon: Icons.fact_check_outlined,
    activeIcon: Icons.fact_check_rounded,
    label: _testsLabel,
  ),
  ShellTab(
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    label: _profileLabel,
  ),
];

String _homeLabel(S s) => s.tabHome;

String _testsLabel(S s) => s.tabTests;

String _rankLabel(S s) => s.tabRank;

String _groupsLabel(S s) => s.tabGroups;

String _profileLabel(S s) => s.tabProfile;

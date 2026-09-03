import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/session/session_controller.dart';
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
    // The teacher app is violet throughout — the KPI tiles, the group icons,
    // the register button. The bar alone read the center's own brand colour, so
    // a teacher's selected tab glowed blue under a violet screen.
    final teacher = context.watch<SessionController>().isTeacher;
    final accent = teacher ? AppColors.violet : context.brand.primary;

    return Scaffold(
      // Deliberately *not* `extendBody`. A floating bar over the content looks
      // better in a screenshot and hides the last card of every list in the
      // app, because each screen would then need its own bottom padding to
      // compensate — forty places to get wrong. The bar keeps its own row; the
      // page background shows around it, which is what makes it read as
      // floating anyway.
      body: SafeArea(bottom: false, child: shell),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.all(Radius.circular(26)),
              border: Border.all(color: AppColors.line),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14122636),
                  blurRadius: 30,
                  offset: Offset(0, 14),
                  spreadRadius: -12,
                ),
              ],
            ),
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _TabButton(
                      tab: tabs[i],
                      label: tabs[i].label(s),
                      selected: shell.currentIndex == i,
                      color: accent,
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
    // The label stays visible on every tab, selected or not. Hiding the
    // inactive ones is the fashionable version of this bar and it costs a
    // first-time user the map of the app — on a product where half the users
    // are teenagers meeting it once, that is the wrong trade.
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 3),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: .10) : Colors.transparent,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // The icon lifts a little when its tab is chosen. Two pixels is
              // enough to read as a state change without becoming a bounce the
              // user waits for on every tap.
              AnimatedSlide(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                offset: selected ? const Offset(0, -.06) : Offset.zero,
                child: Icon(
                  selected ? tab.activeIcon : tab.icon,
                  size: 21,
                  color: selected ? color : AppColors.faint2,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontFamilyFallback: AppFonts.bodyFallback,
                  fontSize: 10,
                  height: 1.1,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? color : AppColors.faint2,
                ),
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/session/session_controller.dart';
import '../core/session/settings_controller.dart';
import '../features/auth/change_password_screen.dart';
import '../features/auth/locked_screen.dart';
import '../features/auth/password_screen.dart';
import '../features/auth/phone_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/auth/success_screen.dart';
import '../features/auth/welcome_screen.dart';
import '../features/profile/notifications_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/settings_screen.dart';
import '../features/profile/update_screen.dart';
import '../features/shared/widgets/app_shell.dart';
import '../features/student/group_detail_screen.dart';
import '../features/student/home_screen.dart';
import '../features/student/rank_screen.dart';
import '../features/student/test_cover_screen.dart';
import '../features/student/test_result_screen.dart';
import '../features/student/test_runner_screen.dart';
import '../features/student/tests_screen.dart';
import '../features/teacher/attendance_screen.dart';
import '../features/teacher/student_detail_screen.dart';
import '../features/teacher/teacher_group_detail_screen.dart';
import '../features/teacher/teacher_groups_screen.dart';
import '../features/teacher/teacher_home_screen.dart';
import '../features/teacher/teacher_test_detail_screen.dart';
import '../features/teacher/teacher_tests_screen.dart';

/// Where each role starts, and where a redirect sends anyone who wanders into
/// the other role's half of the app.
String homeFor(SessionController session) =>
    session.isTeacher ? '/teacher/home' : '/student/home';

/// The whole navigation graph.
///
/// Access is decided once, here, rather than by each screen checking the
/// session on build: a guard spread over forty screens is a guard with a hole
/// in it. The one rule is that [SessionController.status] — not the widget the
/// user last tapped — decides what may be on screen.
GoRouter createRouter({
  required SessionController session,
  required SettingsController settings,
}) {
  final rootKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/splash',
    refreshListenable: Listenable.merge([session, settings]),
    redirect: (context, state) {
      final path = state.matchedLocation;

      // 1 · Before `/auth/me` has answered there is nothing to decide — and
      //     `offline` means it has not answered *yet*, with tokens still on the
      //     device. Both wait on the splash, which grows a retry button in the
      //     second case rather than sending a signed-in user to a login form
      //     that would fail on the same dead connection.
      if (session.status == SessionStatus.unknown ||
          session.status == SessionStatus.offline) {
        return path == '/splash' ? null : '/splash';
      }

      // 2 · A build the API has stopped supporting goes nowhere else.
      if (settings.forceUpdate) return path == '/update' ? null : '/update';

      // 3 · Blocked user, suspended center: an explanation, not a login form
      //     that would fail identically.
      if (session.status == SessionStatus.locked) {
        return path == '/locked' ? null : '/locked';
      }

      // The splash is only ever a waiting room for step 1; once the status is
      // known it is never a destination, whichever way the answer went.
      final signingIn = path.startsWith('/login') || path == '/welcome';

      if (!session.isAuthenticated) {
        return signingIn ? null : '/welcome';
      }

      // 4 · `must_change_password` blocks every screen but the one that clears
      //     it. The center handed this password out on paper.
      if (session.status == SessionStatus.mustChangePassword) {
        return path == '/change-password' ? null : '/change-password';
      }

      // The success screen is the last step of signing in, so it stays
      // reachable for an authenticated user; the rest of `/login` does not.
      if (path == '/splash' || (signingIn && path != '/login/success')) {
        return homeFor(session);
      }

      // 5 · A student cannot open teacher screens and vice versa. The API would
      //     answer `403` anyway; this keeps a mis-tap from looking like a bug.
      final teacher = session.isTeacher;
      if (teacher && path.startsWith('/student')) return '/teacher/home';
      if (!teacher && path.startsWith('/teacher')) return '/student/home';

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/login/phone', builder: (context, state) => const PhoneScreen()),
      GoRoute(
        path: '/login/password',
        // The number the previous screen assembled, plus the role its lookup
        // resolved. A deep link that arrives with neither starts over rather
        // than guessing; one that arrives with a bare number still works, and
        // simply shows no role badge.
        builder: (context, state) => switch (state.extra) {
          final LoginTarget t => PasswordScreen(phone: t.phone, role: t.role),
          final String phone => PasswordScreen(phone: phone),
          _ => const PhoneScreen(),
        },
      ),
      GoRoute(path: '/login/success', builder: (context, state) => const SuccessScreen()),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => ChangePasswordScreen(
          forced: session.status == SessionStatus.mustChangePassword,
        ),
      ),
      GoRoute(path: '/locked', builder: (context, state) => const LockedScreen()),
      GoRoute(path: '/update', builder: (context, state) => const UpdateScreen()),

      // Both roles, above the shell so the bottom bar gives way to a back arrow.
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),

      _studentShell,
      _teacherShell,

      // Student details.
      GoRoute(
        path: '/student/group/:id',
        builder: (context, state) =>
            StudentGroupDetailScreen(groupId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/student/test/:id',
        builder: (context, state) => TestCoverScreen(testId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'run',
            builder: (context, state) => TestRunnerScreen(testId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'result',
            builder: (context, state) => TestResultScreen(testId: state.pathParameters['id']!),
          ),
        ],
      ),

      // Teacher details.
      GoRoute(
        path: '/teacher/group/:id',
        builder: (context, state) =>
            TeacherGroupDetailScreen(groupId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'attendance',
            builder: (context, state) =>
                AttendanceScreen(groupId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/teacher/student/:id',
        builder: (context, state) => StudentDetailScreen(studentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/teacher/test/:id',
        builder: (context, state) =>
            TeacherTestDetailScreen(testId: state.pathParameters['id']!),
      ),
    ],
  );
}

/// Home · tests · rating · profile, each branch keeping its own stack.
final _studentShell = StatefulShellRoute.indexedStack(
  builder: (context, state, shell) => AppShell(shell: shell, tabs: studentTabs),
  branches: [
    StatefulShellBranch(routes: [
      GoRoute(path: '/student/home', builder: (context, state) => const StudentHomeScreen()),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(path: '/student/tests', builder: (context, state) => const StudentTestsScreen()),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(path: '/student/rank', builder: (context, state) => const StudentRankScreen()),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(path: '/student/profile', builder: (context, state) => const ProfileScreen()),
    ]),
  ],
);

/// Home · groups · tests · profile.
final _teacherShell = StatefulShellRoute.indexedStack(
  builder: (context, state, shell) => AppShell(shell: shell, tabs: teacherTabs),
  branches: [
    StatefulShellBranch(routes: [
      GoRoute(path: '/teacher/home', builder: (context, state) => const TeacherHomeScreen()),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(path: '/teacher/groups', builder: (context, state) => const TeacherGroupsScreen()),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(path: '/teacher/tests', builder: (context, state) => const TeacherTestsScreen()),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(path: '/teacher/profile', builder: (context, state) => const ProfileScreen()),
    ]),
  ],
);

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/data/auth_provider.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/profile_setup_screen.dart';
import '../features/groups/presentation/home_screen.dart';
import '../features/groups/presentation/create_group_screen.dart';
import '../features/groups/presentation/group_detail_screen.dart';
import '../features/expenses/presentation/add_expense_screen.dart';
import '../features/expenses/presentation/add_payment_screen.dart';
import '../features/activity/presentation/activity_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/groups/presentation/join_group_screen.dart';
import '../features/profile/data/preferences_provider.dart';
import 'shell_screen.dart';
import '../features/splash/presentation/splash_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final hasProfileState = ref.watch(hasCompletedProfileProvider);

  return GoRouter(
    initialLocation: '/splash',

    // Auth redirect security layer
    redirect: (context, state) {
      final uri = state.uri.toString();
      final isGoingToSplash = uri == '/splash';

      // 1. Show Splash screen if auth or profile is currently loading
      if (authState.isLoading || hasProfileState.isLoading) {
        return isGoingToSplash ? null : '/splash';
      }

      final isAuth = authState.value != null;
      final hasProfile = hasProfileState.value ?? false;
      final isGoingToWelcome = uri == '/onboarding' || uri == '/sign-in';
      final isGoingToSetup = uri == '/profile-setup';

      // 2. Deep Link Interception (Must happen before default routing)
      // If we are fully authenticated and have a profile, check for a pending deep link.
      if (isAuth && hasProfile) {
        final prefs = ref.read(sharedPreferencesProvider);
        final pendingCode = prefs.getString('pending_invite_code');
        if (pendingCode != null && pendingCode.isNotEmpty) {
          // Clear it immediately to prevent redirect loops
          prefs.remove('pending_invite_code');
          return '/invite/$pendingCode';
        }
      }

      // 3. We're fully loaded. If we are currently on the splash screen, decide initial destination
      if (isGoingToSplash) {
        if (isAuth && hasProfile) return '/groups';
        if (isAuth && !hasProfile) return '/profile-setup';
        if (!isAuth) return '/onboarding';
      }

      // Logged in user without profile going to Welcome -> redirect to profile setup
      if (isAuth && !hasProfile && isGoingToWelcome) {
        return '/profile-setup';
      }

      // Logged in user with complete profile going to Welcome -> redirect to app
      if (isAuth && hasProfile && isGoingToWelcome) {
        return '/groups';
      }

      // Logged in user without profile trying to access other app areas -> redirect to profile setup
      if (isAuth && !hasProfile && !isGoingToSetup && !isGoingToWelcome) {
        return '/profile-setup';
      }

      // Guest trying to enter secure app forcibly kicked to Welcome
      if (!isAuth && !isGoingToWelcome && !isGoingToSetup) {
        return '/onboarding';
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/invite/:code',
        builder: (context, state) => JoinGroupScreen(
          inviteCode: state.pathParameters['code']!,
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/groups',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const CreateGroupScreen(),
              ),
              GoRoute(
                path: ':groupId',
                builder: (context, state) => GroupDetailScreen(
                  groupId: state.pathParameters['groupId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'add-expense',
                    builder: (context, state) => AddExpenseScreen(
                      groupId: state.pathParameters['groupId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'add-payment',
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      return AddPaymentScreen(
                        groupId: state.pathParameters['groupId']!,
                        initialFromUserId: extra?['fromUserId'] as String?,
                        initialToUserId: extra?['toUserId'] as String?,
                        prefillAmount: extra?['prefillAmount'] as double?,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/activity',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ActivityScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
    ],
  );
});

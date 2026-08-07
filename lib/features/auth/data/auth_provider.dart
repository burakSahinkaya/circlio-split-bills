import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/app_user.dart';
import 'firebase_auth_service.dart';
import '../../groups/data/group_provider.dart';
import '../../notifications/data/fcm_service.dart';
import '../../expenses/data/expenses_provider.dart';

// Firebase auth service singleton
final authServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

// Stream of Firebase auth state
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Whether the current user has completed profile setup
final hasCompletedProfileProvider = FutureProvider<bool>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) async {
      if (user == null) return false;
      final authService = ref.read(authServiceProvider);
      return await authService.hasCompletedProfile();
    },
    loading: () => false,
    error: (error, stack) => false,
  );
});

// Current app user (from Firestore profile)
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      final authService = ref.read(authServiceProvider);
      
      // Initialize push notifications when user is logged in
      try {
        FcmService().initPushNotifications();
      } catch (e) {
        print('FCM Init Error: $e');
      }

      return authService.getUserProfileStream().map((profile) {
        if (profile == null) return null;
        return AppUser.fromJson({...profile, 'id': user.uid});
      });
    },
    loading: () => Stream.value(null),
    error: (error, stack) => Stream.value(null),
  );
});

// Auth actions notifier for sign-in/sign-out operations
class AuthNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.signInWithGoogle();
      state = const AsyncValue.data(null);
      return result != null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    state = const AsyncValue.loading();
    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.signInWithApple();
      state = const AsyncValue.data(null);
      return result != null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      final authService = ref.read(authServiceProvider);
      // Clean up push notification binds before logging out
      try {
        await FcmService().removeTokenFromDatabase();
      } catch (e) {
        print('Error cleaning up FCM token: $e');
      }
      await authService.signOut();
      ref.invalidate(currentUserProvider);
      ref.invalidate(userGroupsProvider);
      ref.invalidate(pendingInvitesProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> createProfile({
    required String username,
    required String firstName,
    required String lastName,
    File? profilePhoto,
  }) async {
    state = const AsyncValue.loading();
    try {
      final authService = ref.read(authServiceProvider);
      await authService.createUserProfile(
        username: username,
        firstName: firstName,
        lastName: lastName,
        profilePhoto: profilePhoto,
      );
      // Invalidate the profile providers so they refresh
      ref.invalidate(hasCompletedProfileProvider);
      ref.invalidate(currentUserProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Deletes the user account.
  /// Returns `null` on success, or an error string (e.g., 'has-debt', 'requires-recent-login', or error message)
  Future<String?> deleteAccount() async {
    state = const AsyncValue.loading();
    try {
      final authService = ref.read(authServiceProvider);
      final uid = authService.currentUser?.uid;
      if (uid == null) return 'Not authenticated';

      // 1. Check for debts across all groups
      final groups = ref.read(userGroupsProvider).value ?? [];
      bool hasDebt = false;

      for (final group in groups) {
        final nets = ref.read(groupNetBalancesProvider(group.id));
        final myBalance = nets[uid] ?? 0.0;
        // If balance is not zero (user owes or is owed money)
        if (myBalance.abs() > 0.01) {
          hasDebt = true;
          break;
        }
      }

      if (hasDebt) {
        state = const AsyncValue.data(null); // Restore non-loading state
        return 'has-debt';
      }

      // 2. Execute deletion
      final groupIds = groups.map((g) => g.id).toList();
      await authService.deleteAccount(groupIds);

      // 3. Clear state
      ref.invalidate(currentUserProvider);
      ref.invalidate(userGroupsProvider);
      ref.invalidate(pendingInvitesProvider);
      state = const AsyncValue.data(null);
      return null; // Success
    } catch (e) {
      state = const AsyncValue.data(null);
      if (e.toString().contains('requires-recent-login')) {
        return 'requires-recent-login';
      }
      return e.toString();
    }
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AsyncValue<void>>(AuthNotifier.new);

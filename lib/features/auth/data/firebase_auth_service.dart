import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:crypto/crypto.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current Firebase user
  User? get currentUser => _auth.currentUser;

  // ─── Google Sign-In ───────────────────────────────────────────

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // v7 API: use singleton instance and authenticate()
      final googleUser = await GoogleSignIn.instance.authenticate();

      // Get auth tokens
      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Debug: Print user info
      print('Google sign-in successful: ${userCredential.user?.uid}');
      print('Email: ${userCredential.user?.email}');

      return userCredential;
    } catch (e) {
      print('Google sign-in error: $e');
      rethrow;
    }
  }

  // ─── Apple Sign-In ────────────────────────────────────────────

  Future<UserCredential?> signInWithApple() async {
    try {
      // Generate a nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Debug: Print credential info
      print('Apple credential received:');
      print(
        'Identity token: ${appleCredential.identityToken?.isNotEmpty == true ? "Present" : "Missing"}',
      );
      print(
        'Authorization code: ${appleCredential.authorizationCode?.isNotEmpty == true ? "Present" : "Missing"}',
      );
      print('Given name: ${appleCredential.givenName}');
      print('Family name: ${appleCredential.familyName}');
      print('Email: ${appleCredential.email}');

      // Check if we have the identity token
      if (appleCredential.identityToken == null ||
          appleCredential.identityToken!.isEmpty) {
        throw Exception('Apple Sign-In: No identity token received');
      }

      // Create OAuth credential using idToken, authorizationCode, and rawNonce
      final oauthCredential = OAuthProvider(
        'apple.com',
      ).credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode, // Firebase needs this to talk to Apple
        rawNonce: rawNonce,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // Debug: Print user info
      print('Apple sign-in successful: ${userCredential.user?.uid}');
      print('Email: ${userCredential.user?.email}');

      // Apple only provides name on first sign-in, save it
      if (appleCredential.givenName != null) {
        await userCredential.user?.updateDisplayName(
          '${appleCredential.givenName} ${appleCredential.familyName ?? ''}'
              .trim(),
        );
      }

      return userCredential;
    } catch (e, stackTrace) {
      print('\n\n===========================================');
      print('🍎 APPLE SIGN-IN ERROR DETAILS 🍎');
      print('Exception Type: ${e.runtimeType}');
      print('Exception String: $e');
      print('Stack Trace: $stackTrace');
      print('===========================================\n\n');

      // Provide more specific error handling
      if (e.toString().contains('invalid-credential')) {
        throw Exception(
          'Apple Sign-In is not properly configured. Please ensure Apple Sign-In is enabled in your Firebase project and the bundle ID matches. (Original Error: $e)',
        );
      } else if (e.toString().contains('identity token')) {
        throw Exception(
          'Apple Sign-In failed: Unable to get identity token. Please try again. (Original Error: $e)',
        );
      } else {
        rethrow;
      }
    }
  }

  // ─── User Profile ─────────────────────────────────────────────

  /// Check if user has completed profile setup (has a username doc in Firestore)
  Future<bool> hasCompletedProfile() async {
    final user = currentUser;
    if (user == null) {
      print('hasCompletedProfile: No current user');
      return false;
    }

    print('hasCompletedProfile: Checking for user ${user.uid}');

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final exists = doc.exists;
    final hasUsername = doc.data()?['username'] != null;

    print(
      'hasCompletedProfile: Document exists: $exists, hasUsername: $hasUsername',
    );

    return exists && hasUsername;
  }

  /// Check if a username is available
  Future<bool> isUsernameAvailable(String username) async {
    if (username.length < 3) return false;
    final doc = await _firestore
        .collection('usernames')
        .doc(username.toLowerCase())
        .get();
    return !doc.exists;
  }

  /// Create user profile in Firestore
  Future<void> createUserProfile({
    required String username,
    required String firstName,
    required String lastName,
    File? profilePhoto,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Not authenticated');

    String? photoUrl;

    // Upload profile photo if provided
    if (profilePhoto != null) {
      final ref = _storage
          .ref()
          .child('profile_photos')
          .child('${user.uid}.jpg');
      await ref.putFile(profilePhoto);
      photoUrl = await ref.getDownloadURL();
    }

    final batch = _firestore.batch();

    // Create user document
    batch.set(_firestore.collection('users').doc(user.uid), {
      'username': username.toLowerCase(),
      'firstName': firstName,
      'lastName': lastName,
      'displayName': '$firstName $lastName'.trim(),
      'email': user.email,
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Reserve username (for uniqueness checking)
    batch.set(_firestore.collection('usernames').doc(username.toLowerCase()), {
      'uid': user.uid,
    });

    await batch.commit();
  }

  /// Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }

  /// Get real-time user profile stream from Firestore
  Stream<Map<String, dynamic>?> getUserProfileStream() {
    final user = currentUser;
    if (user == null) return Stream.value(null);

    return _firestore.collection('users').doc(user.uid).snapshots().map((doc) => doc.data());
  }

  // ─── Sign Out ─────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {
      // May fail if the user didn't sign in with Google – that's fine.
    }
    await _auth.signOut();
  }

  // ─── Helpers ──────────────────────────────────────────────────

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ─── Delete Account ─────────────────────────────────────────────

  Future<void> deleteAccount(List<String> groupIdsToLeave) async {
    final user = currentUser;
    if (user == null) throw Exception('Not authenticated');

    final batch = _firestore.batch();
    final userRef = _firestore.collection('users').doc(user.uid);

    // Get current username to release it
    final userDoc = await userRef.get();
    if (userDoc.exists) {
      final username = userDoc.data()?['username'];
      if (username != null) {
        batch.delete(_firestore.collection('usernames').doc(username));
      }
    }

    // 1. Soft delete user document
    batch.update(userRef, {
      'displayName': 'Deleted Account',
      'firstName': 'Deleted',
      'lastName': 'Account',
      'username': FieldValue.delete(),
      'email': FieldValue.delete(),
      'photoUrl': FieldValue.delete(),
      'fcmTokens': FieldValue.delete(),
      'isDeleted': true,
    });

    // 2. Remove user from all groups
    for (final groupId in groupIdsToLeave) {
      final groupRef = _firestore.collection('groups').doc(groupId);
      batch.update(groupRef, {
        'memberIds': FieldValue.arrayRemove([user.uid]),
        'leftMemberIds': FieldValue.arrayUnion([user.uid]),
      });
    }

    // 3. Commit Firestore changes
    await batch.commit();

    // 4. Delete Auth Record
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('requires-recent-login');
      }
      rethrow;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/l10n_extension.dart';

import '../data/auth_provider.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AsyncLoading;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: context.colors.heroGradient),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Spacer(flex: 2),

                // Logo icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: context.colors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.primary.withValues(alpha: 0.4),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 28),

                // App name
                ShaderMask(
                  shaderCallback: (bounds) =>
                      context.colors.primaryGradient.createShader(bounds),
                  child: Text(
                    context.l10n.splitCircle,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1.5,
                    ),
                  ),
                ),

                SizedBox(height: 12),

                Text(
                  context.l10n.splitExpensesTagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: context.colors.textSecondary,
                    height: 1.5,
                  ),
                ),

                Spacer(flex: 3),

                // Sign in with Google
                _SignInButton(
                  label: context.l10n.continueWithGoogle,
                  icon: _GoogleIcon(),
                  backgroundColor: Colors.white,
                  textColor: Color(0xFF1F1F1F),
                  isLoading: isLoading,
                  onPressed: isLoading
                      ? null
                      : () async {
                          try {
                            final success = await ref
                                .read(authNotifierProvider.notifier)
                                .signInWithGoogle();
                            if (success && context.mounted) {
                              _navigateAfterAuth(context, ref);
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.l10n.googleSignInFailed,
                                  ),
                                  backgroundColor: context.colors.danger,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Sign-in error: ${e.toString()}',
                                  ),
                                  backgroundColor: context.colors.danger,
                                ),
                              );
                            }
                          }
                        },
                ),

                SizedBox(height: 14),

                // Sign in with Apple - only show on iOS
                if (defaultTargetPlatform == TargetPlatform.iOS)
                  _SignInButton(
                    label: context.l10n.continueWithApple,
                    icon: Icon(
                      Icons.apple_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    backgroundColor: Colors.black,
                    textColor: Colors.white,
                    borderColor: context.colors.border,
                    isLoading: isLoading,
                    onPressed: isLoading
                        ? null
                        : () async {
                            try {
                              final success = await ref
                                  .read(authNotifierProvider.notifier)
                                  .signInWithApple();
                              if (success && context.mounted) {
                                _navigateAfterAuth(context, ref);
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.l10n.appleSignInFailed,
                                    ),
                                    backgroundColor: context.colors.danger,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Sign-in error: ${e.toString()}',
                                    ),
                                    backgroundColor: context.colors.danger,
                                  ),
                                );
                              }
                            }
                          },
                  ),

                Spacer(),

                // Terms
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    context.l10n.termsAgree,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.textTertiary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateAfterAuth(BuildContext context, WidgetRef ref) async {
    try {
      final authService = ref.read(authServiceProvider);
      final hasProfile = await authService.hasCompletedProfile();
      if (!context.mounted) return;

      // Add a small delay to ensure auth state is propagated
      await Future.delayed(Duration(milliseconds: 100));

      if (!context.mounted) return;

      if (hasProfile) {
        context.go('/groups');
      } else {
        context.go('/profile-setup');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation error: ${e.toString()}'),
            backgroundColor: context.colors.danger,
          ),
        );
      }
    }
  }
}

class _SignInButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _SignInButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: borderColor != null
                  ? Border.all(color: borderColor!)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Image.asset('assets/images/google_logo.png', fit: BoxFit.contain),
    );
  }
}

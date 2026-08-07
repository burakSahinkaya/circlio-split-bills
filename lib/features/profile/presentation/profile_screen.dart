import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../auth/data/auth_provider.dart';
import '../data/preferences_provider.dart';
import '../../../core/utils/l10n_extension.dart';

Map<String, String> _currencies = {
  'USD': '\$',
  'EUR': '€',
  'GBP': '£',
  'AUD': 'A\$',
  'CAD': 'C\$',
  'JPY': '¥',
  'TRY': '₺',
  'INR': '₹',
  'CNY': '¥',
};

const Map<String, String> _languages = {
  'en': 'English',
  'tr': 'Türkçe',
  'fr': 'Français',
  'es': 'Español',
  'ru': 'Русский',
  'it': 'Italiano',
};

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;
    final userName = user?.name ?? 'User';
    final userEmail = user?.email ?? '';
    final preferences = ref.watch(preferencesProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.colors.heroGradient.colors.first,
                      context.colors.background,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 20),
                      AvatarCircle(
                        name: userName,
                        imageUrl: user?.avatarUrl,
                        size: 80,
                      ),
                      SizedBox(height: 16),
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      if (user?.username != null) ...[
                        SizedBox(height: 2),
                        Text(
                          '@${user!.username}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: context.colors.primary,
                          ),
                        ),
                      ],
                      SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Settings section
                  _SectionTitle(l10n.preferences),
                  _SettingsTile(
                    icon: Icons.attach_money_rounded,
                    title: l10n.defaultCurrency,
                    subtitle:
                        '${preferences.currency} (${_currencies[preferences.currency] ?? ""})',
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (ctx) => _CurrencySelector(
                          currentCurrency: preferences.currency,
                          onSelect: (c) {
                            prefsNotifier.updateCurrency(c);
                            Navigator.pop(ctx);
                          },
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: l10n.notifications,
                    subtitle: preferences.notificationsEnabled
                        ? l10n.enabled
                        : l10n.disabled,
                    onTap: () => prefsNotifier.toggleNotifications(
                      !preferences.notificationsEnabled,
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.dark_mode_rounded,
                    title: l10n.appearance,
                    subtitle: preferences.themeMode == ThemeMode.light
                        ? l10n.lightMode
                        : preferences.themeMode == ThemeMode.dark
                        ? l10n.darkMode
                        : l10n.systemDefault,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (ctx) => _AppearanceSelector(
                          currentMode: preferences.themeMode,
                          onSelect: (m) {
                            prefsNotifier.updateThemeMode(m);
                            Navigator.pop(ctx);
                          },
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.language_rounded,
                    title: l10n.language,
                    subtitle: preferences.languageCode == null 
                        ? l10n.systemDefault 
                        : _languages[preferences.languageCode] ?? 'English',
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (ctx) => _LanguageSelector(
                          currentLanguage: preferences.languageCode,
                          onSelect: (lang) {
                            prefsNotifier.updateLanguage(lang);
                            Navigator.pop(ctx);
                          },
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 8),
                  _SectionTitle(l10n.about),
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: l10n.aboutApp,
                    subtitle: 'Version 1.0.0',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: l10n.privacyPolicy,
                    onTap: () async {
                      final url = Uri.parse('https://bishamongames.com/circlio/privacy/');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.description_outlined,
                    title: l10n.termsOfService,
                    onTap: () async {
                      final url = Uri.parse('https://bishamongames.com/circlio/privacy/');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),

                  SizedBox(height: 8),
                  _SettingsTile(
                    icon: Icons.logout_rounded,
                    title: l10n.logOut,
                    iconColor: context.colors.danger,
                    titleColor: context.colors.danger,
                    onTap: () {
                      ref.read(authNotifierProvider.notifier).signOut();
                    },
                  ),

                  SizedBox(height: 8),
                  _SettingsTile(
                    icon: Icons.person_remove_rounded,
                    title: l10n.deleteAccount,
                    iconColor: context.colors.danger,
                    titleColor: context.colors.danger,
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(l10n.deleteAccount),
                          content: Text(
                            l10n.deleteAccountConfirm,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(l10n.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                foregroundColor: context.colors.danger,
                              ),
                              child: Text(l10n.delete),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        final error = await ref.read(authNotifierProvider.notifier).deleteAccount();
                        if (error == 'has-debt') {
                          if (!context.mounted) return;
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(l10n.outstandingBalances),
                              content: Text(l10n.deleteAccountWarning),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(l10n.ok),
                                ),
                              ],
                            ),
                          );
                        } else if (error == 'requires-recent-login') {
                          if (!context.mounted) return;
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(l10n.accountSecurity),
                              content: Text(l10n.deleteAccountSecurity),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(l10n.ok),
                                ),
                              ],
                            ),
                          );
                        } else if (error != null) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $error')),
                          );
                        }
                      }
                    },
                  ),

                  SizedBox(height: 40),

                  // Footer
                  Center(
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => context
                              .colors
                              .primaryGradient
                              .createShader(bounds),
                          child: Text(
                            l10n.splitCircle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          l10n.madeWithLove,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.colors.textTertiary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (iconColor ?? context.colors.primary).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor ?? context.colors.primary,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: titleColor ?? context.colors.textPrimary,
              ),
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: context.colors.textTertiary,
              ),
            ),
          SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            color: context.colors.textTertiary,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _CurrencySelector extends StatelessWidget {
  final String currentCurrency;
  final ValueChanged<String> onSelect;

  const _CurrencySelector({
    required this.currentCurrency,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            l10n.selectCurrency,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _currencies.length,
            itemBuilder: (context, index) {
              final curr = _currencies.keys.elementAt(index);
              final sym = _currencies[curr]!;
              return ListTile(
                title: Text(
                  '$curr ($sym)',
                  style: TextStyle(color: context.colors.textPrimary),
                ),
                trailing: curr == currentCurrency
                    ? Icon(Icons.check, color: context.colors.primary)
                    : null,
                onTap: () => onSelect(curr),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AppearanceSelector extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onSelect;

  const _AppearanceSelector({
    required this.currentMode,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              l10n.appearance,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ListTile(
            title: Text(
              l10n.systemDefault,
              style: TextStyle(color: context.colors.textPrimary),
            ),
            trailing: currentMode == ThemeMode.system
                ? Icon(Icons.check, color: context.colors.primary)
                : null,
            onTap: () => onSelect(ThemeMode.system),
          ),
          ListTile(
            title: Text(
              l10n.lightMode,
              style: TextStyle(color: context.colors.textPrimary),
            ),
            trailing: currentMode == ThemeMode.light
                ? Icon(Icons.check, color: context.colors.primary)
                : null,
            onTap: () => onSelect(ThemeMode.light),
          ),
          ListTile(
            title: Text(
              l10n.darkMode,
              style: TextStyle(color: context.colors.textPrimary),
            ),
            trailing: currentMode == ThemeMode.dark
                ? Icon(Icons.check, color: context.colors.primary)
                : null,
            onTap: () => onSelect(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  final String? currentLanguage;
  final ValueChanged<String?> onSelect;

  const _LanguageSelector({
    required this.currentLanguage,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Select Language',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              ListTile(
                title: Text(
                  'System Default',
                  style: TextStyle(color: context.colors.textPrimary),
                ),
                trailing: currentLanguage == null
                    ? Icon(Icons.check, color: context.colors.primary)
                    : null,
                onTap: () => onSelect(null),
              ),
              ..._languages.entries.map((entry) {
                return ListTile(
                  title: Text(
                    entry.value,
                    style: TextStyle(color: context.colors.textPrimary),
                  ),
                  trailing: currentLanguage == entry.key
                      ? Icon(Icons.check, color: context.colors.primary)
                      : null,
                  onTap: () => onSelect(entry.key),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

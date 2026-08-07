import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';
import 'core/theme/app_theme.dart';
import 'features/profile/data/preferences_provider.dart';
import 'package:split_circle/l10n/app_localizations.dart';
import 'routing/app_router.dart';

class SplitCircleApp extends ConsumerStatefulWidget {
  const SplitCircleApp({super.key});

  @override
  ConsumerState<SplitCircleApp> createState() => _SplitCircleAppState();
}

class _SplitCircleAppState extends ConsumerState<SplitCircleApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    // Handle link that launched the app (cold start)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingLink(initialUri);
      }
    } catch (e) {
      print('Error getting initial link: $e');
    }

    // Handle links while app is running (warm start)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _handleIncomingLink(uri),
      onError: (e) => print('Deep link stream error: $e'),
    );
  }

  void _handleIncomingLink(Uri uri) {
    // Expected URL: https://splitcircle-7e06e.web.app/invite/CODE
    final path = uri.path;

    if (path.startsWith('/invite/')) {
      final code = path.replaceFirst('/invite/', '');
      final prefs = ref.read(sharedPreferencesProvider);
      
      // Store the invite code so the router can pick it up once the app is fully authenticated
      prefs.setString('pending_invite_code', code);
      
      // Trigger go_router to re-evaluate its redirect logic immediately
      ref.read(goRouterProvider).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final preferences = ref.watch(preferencesProvider);

    return MaterialApp.router(
      title: 'SplitCircle',
      debugShowCheckedModeBanner: false,
      locale: preferences.languageCode != null ? Locale(preferences.languageCode!) : null,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: preferences.themeMode,
      routerConfig: router,
    );
  }
}

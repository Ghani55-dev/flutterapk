import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/password_reset_screens.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/core/presentation/splash_screen.dart';
import '../features/core/presentation/startup_error_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/startup/presentation/location_permission_screen.dart';
import '../features/startup/presentation/notification_permission_screen.dart';
import '../features/guest/presentation/guest_home_screen.dart';
import '../features/article/presentation/guest_article_preview_screen.dart';
import '../features/article/presentation/article_detail_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/reels/presentation/reels_screen.dart';
import '../features/auth/auth_controller.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/profile/presentation/profile_preferences_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/bookmarks/presentation/bookmarks_screen.dart';
import '../features/cms/presentation/about_screen.dart';
import '../features/cms/presentation/privacy_screen.dart';
import '../features/cms/presentation/terms_screen.dart';
import '../features/cms/presentation/help_screen.dart';
import '../features/epaper/presentation/epaper_list_screen.dart';
import '../features/epaper/presentation/epaper_landing_screen.dart';
import '../features/auth/presentation/protected_route.dart';
import '../features/location/presentation/location_picker_screen.dart';
import '../features/notifications/presentation/notification_inbox_screen.dart';
import '../features/notifications/presentation/notification_detail_screen.dart';
import '../features/notifications/data/notification_models.dart';
import '../features/ugc/presentation/community_home_screen.dart';
import '../features/ugc/presentation/ugc_otp_screen.dart';
import '../features/ugc/presentation/ugc_submit_screen.dart';
import '../features/ugc/presentation/ugc_media_upload_screen.dart';
import '../features/ugc/presentation/ugc_submission_success_screen.dart';
import '../features/ugc/presentation/ugc_feed_screen.dart';
import '../features/ugc/data/ugc_models.dart';

// Admin imports
import '../features/admin/auth/admin_login_screen.dart';
import '../features/admin/dashboard/admin_dashboard_screen.dart';
import '../features/admin/articles/admin_articles_screen.dart';
import '../features/admin/ugc/admin_ugc_screen.dart';
import '../features/admin/users/admin_users_screen.dart';
import '../features/admin/analytics/admin_analytics_screen.dart';
import '../features/admin/notifications/admin_notifications_screen.dart';
import '../features/admin/polls/admin_polls_screen.dart';
import '../features/admin/epapers/admin_epapers_screen.dart';
import '../features/admin/search_logs/admin_search_logs_screen.dart';
import '../features/admin/cms/admin_cms_screen.dart';
import '../features/admin/quotes/admin_quotes_screen.dart';
import '../features/admin/system/admin_system_screen.dart';
import '../providers/admin_providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  String? redirectLogic(GoRouterState state) {
    final location = state.location;

    // Check if accessing admin route
    if (location.startsWith('/admin')) {
      final adminAuth = ref.read(adminAuthNotifierProvider);
      
      if (location == '/admin/login') {
        if (adminAuth.status == AdminAuthStatus.authenticated) {
          return '/admin/dashboard';
        }
        return null;
      }
      
      if (adminAuth.status == AdminAuthStatus.unauthenticated) {
        return '/admin/login';
      }
      return null;
    }

    // Standard user redirect logic
    final auth = ref.read(authNotifierProvider);
    final adminAuth = ref.read(adminAuthNotifierProvider);
    
    // If admin is logged in via admin auth, prevent access to regular user routes
    // and redirect to admin dashboard
    if (adminAuth.status == AdminAuthStatus.authenticated) {
      final isAdminRoute = location.startsWith('/admin');
      final isPublicRoute = location == '/splash' || 
                          location == '/about' || 
                          location == '/privacy' || 
                          location == '/terms' || 
                          location == '/help' ||
                          location.startsWith('/guest-') ||
                          location.startsWith('/article/');
      
      if (!isAdminRoute && !isPublicRoute) {
        // Redirect to admin dashboard
        return '/admin/dashboard';
      }
    }
    
    final isAuthenticatedHome = location == '/' || location == '/polls';
    final isProtectedLocation = isAuthenticatedHome ||
        location == '/settings' ||
        location == '/bookmarks' ||
        location.startsWith('/profile') ||
        location.startsWith('/notifications') ||
        location.startsWith('/community');
    final isGuestStartup = location == '/guest-home' ||
        location == '/onboarding' ||
        location == '/location-permission' ||
        location == '/notification-permission' ||
        location.startsWith('/guest-article/');
    final isAuthScreen = location == '/login' || location == '/register';

    if (auth.status == AuthStatus.unknown) {
      return isProtectedLocation && location != '/splash' ? '/splash' : null;
    }
    if (auth.status == AuthStatus.unauthenticated && isAuthenticatedHome) {
      return '/guest-home';
    }
    if (auth.status == AuthStatus.authenticated && (isAuthScreen || isGuestStartup)) {
      return '/';
    }
    return null;
  }

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authNotifierProvider.notifier).changes,
      ref.watch(adminAuthNotifierProvider.notifier).changes,
    ),
    redirect: (context, state) => redirectLogic(state),
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      GoRoute(path: '/location-permission', builder: (c, s) => const LocationPermissionScreen()),
      GoRoute(path: '/notification-permission', builder: (c, s) => const NotificationPermissionScreen()),
      GoRoute(path: '/guest-home', builder: (c, s) => const GuestHomeScreen()),
      GoRoute(path: '/guest-article/:slug', builder: (c, s) => GuestArticlePreviewScreen(slug: s.params['slug'] ?? '')),
      GoRoute(path: '/article/:slug', builder: (c, s) => ArticleDetailScreen(slug: s.params['slug'] ?? '')),
      GoRoute(
        path: '/startup-error',
        builder: (c, s) => StartupErrorScreen(message: s.extra?.toString()),
      ),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (c, s) => const ForgotPasswordRequestScreen()),
      GoRoute(path: '/forgot-password/verify', builder: (c, s) {
        final extra = s.extra;
        if (extra is Map) {
          return ForgotPasswordVerificationScreen(
            email: extra['email']?.toString(),
            token: extra['token']?.toString(),
          );
        }
        return ForgotPasswordVerificationScreen(email: s.extra?.toString());
      }),
      GoRoute(path: '/forgot-password/confirm', builder: (c, s) {
        final extra = s.extra;
        if (extra is Map) {
          return PasswordResetConfirmationScreen(
            email: extra['email']?.toString(),
            token: extra['token']?.toString(),
          );
        }
        return const PasswordResetConfirmationScreen();
      }),
      GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
      GoRoute(path: '/polls', builder: (c, s) => const HomeScreen(initialIndex: 3)),
      GoRoute(path: '/search', builder: (c, s) => const SearchScreen()),
      GoRoute(path: '/reels', builder: (c, s) => const ReelsScreen()),
      GoRoute(path: '/profile', builder: (c, s) => ProtectedRoute(child: const ProfileScreen())),
      GoRoute(path: '/profile/edit', builder: (c, s) => ProtectedRoute(child: const EditProfileScreen())),
      GoRoute(path: '/profile/preferences', builder: (c, s) => ProtectedRoute(child: const ProfilePreferencesScreen())),
      GoRoute(path: '/settings', builder: (c, s) => ProtectedRoute(child: const SettingsScreen())),
      GoRoute(path: '/bookmarks', builder: (c, s) => ProtectedRoute(child: const BookmarksScreen())),
      GoRoute(path: '/about', builder: (c, s) => const AboutScreen()),
      GoRoute(path: '/privacy', builder: (c, s) => const PrivacyScreen()),
      GoRoute(path: '/terms', builder: (c, s) => const TermsScreen()),
      GoRoute(path: '/help', builder: (c, s) => const HelpScreen()),
      GoRoute(path: '/epapers', builder: (c, s) => const EpaperListScreen()),
      GoRoute(path: '/epapers/:id', builder: (c, s) {
        if (kDebugMode) debugPrint('[EPAPER ROUTER] /epapers/:id -> LANDING id=${s.params['id']}');
        return EpaperLandingScreen(id: s.params['id']);
      }),
      GoRoute(path: '/location-picker', builder: (c, s) => const LocationPickerScreen()),
      GoRoute(path: '/notifications', builder: (c, s) => ProtectedRoute(child: const NotificationInboxScreen())),
      GoRoute(path: '/notifications/:id', builder: (c, s) {
        final extra = s.extra;
        return ProtectedRoute(
          child: NotificationDetailScreen(
            id: s.params['id'] ?? '',
            initialItem: extra is NotificationInboxItem ? extra : null,
          ),
        );
      }),
      GoRoute(path: '/community', builder: (c, s) => ProtectedRoute(child: const CommunityHomeScreen())),
      GoRoute(path: '/community/otp', builder: (c, s) => ProtectedRoute(child: const UGCOtpScreen())),
      GoRoute(path: '/community/submit', builder: (c, s) => ProtectedRoute(child: const UGCSubmitScreen())),
      GoRoute(path: '/community/media', builder: (c, s) {
        final extra = s.extra;
        return ProtectedRoute(
          child: UGCMediaUploadScreen(draft: extra is Map ? Map<String, dynamic>.from(extra) : const <String, dynamic>{}),
        );
      }),
      GoRoute(path: '/community/success', builder: (c, s) {
        final extra = s.extra;
        return ProtectedRoute(
          child: UGCSubmissionSuccessScreen(result: extra is UGCSubmissionResult ? extra : null),
        );
      }),
      GoRoute(path: '/community/feed', builder: (c, s) => ProtectedRoute(child: const UGCFeedScreen())),

      // Admin Panel Routes
      GoRoute(path: '/admin', redirect: (context, state) => '/admin/dashboard'),
      GoRoute(path: '/admin/login', builder: (c, s) => const AdminLoginScreen()),
      GoRoute(path: '/admin/dashboard', builder: (c, s) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/articles', builder: (c, s) => const AdminArticlesScreen()),
      GoRoute(path: '/admin/ugc', builder: (c, s) => const AdminUgcScreen()),
      GoRoute(path: '/admin/users', builder: (c, s) => const AdminUsersScreen()),
      GoRoute(path: '/admin/analytics', builder: (c, s) => const AdminAnalyticsScreen()),
      GoRoute(path: '/admin/notifications', builder: (c, s) => const AdminNotificationsScreen()),
      GoRoute(path: '/admin/polls', builder: (c, s) => const AdminPollsScreen()),
      GoRoute(path: '/admin/epapers', builder: (c, s) => const AdminEpapersScreen()),
      GoRoute(path: '/admin/search-logs', builder: (c, s) => const AdminSearchLogsScreen()),
      GoRoute(path: '/admin/cms', builder: (c, s) => const AdminCmsScreen()),
      GoRoute(path: '/admin/quotes', builder: (c, s) => const AdminQuotesScreen()),
      GoRoute(path: '/admin/system', builder: (c, s) => const AdminSystemScreen()),
    ],
  );
});

// Helper to adapt multiple streams/notifiers to GoRouter's refreshListenable
class GoRouterRefreshStream extends ChangeNotifier {
  late final List<StreamSubscription> _subscriptions;

  GoRouterRefreshStream(Stream<dynamic> stream1, Stream<dynamic> stream2) {
    _subscriptions = [
      stream1.listen((_) => notifyListeners()),
      stream2.listen((_) => notifyListeners()),
    ];
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}

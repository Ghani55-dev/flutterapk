import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../providers/admin_providers.dart';
import '../../../providers/core_providers.dart';
import '../../auth/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  String _statusText = 'Waking the newsroom';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
    _logoScale = Tween<double>(begin: 0.94, end: 1.04).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _logoOpacity = Tween<double>(begin: 0.82, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() => _statusText = 'Checking service health');
    final health = await ref.read(healthRepositoryProvider).checkHealth();
    if (!mounted) return;

    if (!health.isHealthy) {
      context.go('/startup-error', extra: health.message);
      return;
    }

    setState(() => _statusText = 'Restoring your session');
    await _restoreTokenIfPresent();
    await ref.read(authNotifierProvider.notifier).restoreSession();
    if (!mounted) return;

    final auth = ref.read(authNotifierProvider);
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    if (auth.status == AuthStatus.authenticated) {
      // If this is an admin user, also restore the admin auth state so
      // admin panel routes stay accessible.
      final user = auth.user;
      if (user != null && user.isAdmin) {
        final tokenManager = ref.read(tokenManagerProvider);
        final access = await tokenManager.getAccessToken();
        final refresh = await tokenManager.getRefreshToken();
        if (access != null && refresh != null) {
          final adminAuth = ref.read(adminAuthNotifierProvider);
          if (adminAuth.status != AdminAuthStatus.authenticated) {
            await ref.read(adminAuthNotifierProvider.notifier).loginWithTokens(
              access: access,
              refresh: refresh,
              user: {
                'id': user.rawId,
                'email': user.email,
                'full_name': user.name ?? '',
                'is_admin': true,
              },
            );
          }
        }
        if (mounted) context.go('/admin/dashboard');
      } else {
        context.go('/');
      }
      return;
    }

    final hasSeenOnboarding = await ref.read(startupPreferencesProvider).hasSeenOnboarding();
    if (!mounted) return;

    context.go(hasSeenOnboarding ? '/guest-home' : '/onboarding');
  }

  Future<void> _restoreTokenIfPresent() async {
    final tokenManager = ref.read(tokenManagerProvider);
    final refresh = await tokenManager.getRefreshToken();
    if (refresh != null && refresh.isNotEmpty) {
      await tokenManager.refreshIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10141B),
      body: Stack(
        children: [
          Positioned.fill(child: _SunriseGlow(animation: _controller)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              child: Column(
                children: [
                  const Spacer(),
                  FadeTransition(
                    opacity: _logoOpacity,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: const _VaradhiLogo(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    _statusText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withAlpha(220),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 18),
                  const SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(strokeWidth: 2.8, color: Color(0xFFFFC857)),
                  ),
                  const Spacer(),
                  const _NewsTicker(),
                  const SizedBox(height: 18),
                  Text(
                    '${AppConfig.appName} v${AppConfig.appVersion}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white.withAlpha(110),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VaradhiLogo extends StatelessWidget {
  const _VaradhiLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFD166), Color(0xFFFF6B35), Color(0xFFB51724)],
            ),
            boxShadow: [
              BoxShadow(color: const Color(0xFFFFA726).withAlpha(80), blurRadius: 38, spreadRadius: 4),
              BoxShadow(color: Colors.black.withAlpha(70), blurRadius: 18, offset: const Offset(0, 12)),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 24,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(42),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Text(
                'V',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          AppConfig.appName,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Local news. Live and first.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _SunriseGlow extends StatelessWidget {
  final Animation<double> animation;

  const _SunriseGlow({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final lift = 34 * animation.value;
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF151A24), Color(0xFF21151A), Color(0xFF10141B)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: -90,
                right: -90,
                bottom: 210 + lift,
                child: Container(
                  height: 230,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFD166).withAlpha(120),
                        const Color(0xFFFF7A1A).withAlpha(54),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 36,
                right: 36,
                bottom: 265 + lift,
                child: Container(
                  height: 1.3,
                  color: const Color(0xFFFFD166).withAlpha(150),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NewsTicker extends StatefulWidget {
  const _NewsTicker();

  @override
  State<_NewsTicker> createState() => _NewsTickerState();
}

class _NewsTickerState extends State<_NewsTicker> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const ticker = 'BREAKING  |  Hyperlocal updates  |  Live news  |  Community reports  |  E-paper';

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(18),
          border: Border.all(color: Colors.white.withAlpha(30)),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final progress = _controller.value;
            return FractionalTranslation(
              translation: Offset(1 - (progress * 2.4), 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  ticker,
                  maxLines: 1,
                  softWrap: false,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

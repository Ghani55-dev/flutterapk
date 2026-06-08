import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/auth_repository.dart';
import 'data/models.dart';
import '../../providers/core_providers.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  const AuthState._({required this.status, this.user});
  const AuthState.unknown() : this._(status: AuthStatus.unknown);
  const AuthState.authenticated(UserModel user) : this._(status: AuthStatus.authenticated, user: user);
  const AuthState.unauthenticated() : this._(status: AuthStatus.unauthenticated);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository repository;
  final StreamController<void> _controller = StreamController.broadcast();
  Stream<void> get changes => _controller.stream;

  AuthNotifier(this.repository) : super(const AuthState.unknown());

  Future<void> restoreSession() async {
    final user = await repository.me();
    if (user != null) {
      state = AuthState.authenticated(user);
    } else {
      state = const AuthState.unauthenticated();
    }
    _controller.add(null);
  }

  Future<bool> login({required String email, required String password, String? deviceId, String? fcmToken}) async {
    final ok = await repository.login(email: email, password: password, deviceId: deviceId, fcmToken: fcmToken);
    if (!ok) return false;
    
    final user = await repository.me();
    if (user != null) {
      state = AuthState.authenticated(user);
    }
    _controller.add(null);
    return true;
  }

  Future<bool> register({
    required String email,
    required String password,
    required String passwordConfirm,
    required String name,
    String preferredLanguage = 'en',
    String? deviceId,
    String? fcmToken,
  }) async {
    final ok = await repository.register(
      email: email,
      password: password,
      passwordConfirm: passwordConfirm,
      name: name,
      preferredLanguage: preferredLanguage,
      deviceId: deviceId,
      fcmToken: fcmToken,
    );
    if (!ok) return false;
    final user = await repository.me();
    if (user != null) {
      state = AuthState.authenticated(user);
    }
    _controller.add(null);
    return true;
  }

  Future<void> logout() async {
    await repository.logout();
    state = const AuthState.unauthenticated();
    _controller.add(null);
  }

  Future<void> clearLocalSession() async {
    await repository.clearLocalSession();
    state = const AuthState.unauthenticated();
    _controller.add(null);
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return AuthNotifier(repo);
});

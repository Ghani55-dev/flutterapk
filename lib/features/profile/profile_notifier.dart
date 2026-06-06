import 'package:state_notifier/state_notifier.dart';
import 'models/profile_model.dart';
import 'data/profile_repository.dart';

class ProfileState {
  final bool loading;
  final bool saving;
  final ProfileModel? profile;
  final String? error;

  ProfileState({this.loading = false, this.saving = false, this.profile, this.error});

  ProfileState copyWith({bool? loading, bool? saving, ProfileModel? profile, String? error}) =>
      ProfileState(loading: loading ?? this.loading, saving: saving ?? this.saving, profile: profile ?? this.profile, error: error);
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository repository;
  ProfileNotifier({required this.repository}) : super(ProfileState());

  Future<void> loadProfile() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final p = await repository.getProfile();
      state = state.copyWith(loading: false, profile: p);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> updateProfile(Map<String, dynamic> body) async {
    state = state.copyWith(saving: true, error: null);
    try {
      final p = await repository.updateProfile(body);
      state = state.copyWith(saving: false, profile: p);
    } catch (e) {
      state = state.copyWith(saving: false, error: e.toString());
    }
  }

  Future<bool> updateProfileAndLocation(Map<String, dynamic> profileBody, Map<String, dynamic>? locationBody) async {
    state = state.copyWith(saving: true, error: null);
    try {
      final p = await repository.updateProfile(profileBody);
      if (locationBody != null) {
        await repository.updateLocation(locationBody);
      }
      state = state.copyWith(saving: false, profile: p);
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, error: e.toString());
      return false;
    }
  }
}

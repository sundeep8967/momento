import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FriendSettingsState {
  final String? pinnedBffUid;

  FriendSettingsState({this.pinnedBffUid});

  FriendSettingsState copyWith({
    String? pinnedBffUid,
    bool clearPinnedBff = false,
  }) {
    return FriendSettingsState(
      pinnedBffUid: clearPinnedBff ? null : (pinnedBffUid ?? this.pinnedBffUid),
    );
  }
}

class FriendSettingsNotifier extends StateNotifier<FriendSettingsState> {
  FriendSettingsNotifier() : super(FriendSettingsState()) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final pinned = prefs.getString('pinned_bff_uid');

    state = FriendSettingsState(
      pinnedBffUid: pinned,
    );
  }

  Future<void> setPinnedBff(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pinned_bff_uid', uid);
    state = state.copyWith(pinnedBffUid: uid);
  }

  Future<void> unpinBff() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pinned_bff_uid');
    state = state.copyWith(clearPinnedBff: true);
  }
}

final friendSettingsProvider = StateNotifierProvider<FriendSettingsNotifier, FriendSettingsState>((ref) {
  return FriendSettingsNotifier();
});

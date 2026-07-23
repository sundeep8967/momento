import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final smokingModeProvider = StateNotifierProvider<SmokingModeNotifier, bool>((ref) {
  return SmokingModeNotifier();
});

class SmokingModeNotifier extends StateNotifier<bool> {
  SmokingModeNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('smokingMode') ?? false;
  }

  Future<void> toggle(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('smokingMode', state);
  }
}

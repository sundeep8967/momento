import 'package:dicebear_core/dicebear_core.dart';
import 'package:dicebear_styles/avataaars.dart';
import 'package:momento/avatar_kit/momento_avatar.dart';

void main() {
  final seeds = ['sundeepppp', 'yo', 'sundeep'];
  for (final seed in seeds) {
    try {
      final avatar = MomentoAvatar.fromSeed(seed);
      Avatar(Style.parse(avataaars), avatar.toMap());
      print('SUCCESS $seed');
    } catch(e) {
      print('ERROR $seed: $e');
    }
  }
}

import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Momento Avatar Data Model
/// Mapped directly to DiceBear Avataaars schema properties.
class MomentoAvatar {
  final String seed;
  final String skinColor;
  final String top;
  final String hairColor;
  final String hatColor;
  final String accessories;
  final String accessoriesColor;
  final String facialHair;
  final String facialHairColor;
  final String clothes;
  final String clothesColor;
  final String clothesGraphic;
  final String eyes;
  final String eyebrows;
  final String mouth;
  
  // App-specific setting for glow background
  final int bgScene;

  const MomentoAvatar({
    required this.seed,
    this.skinColor = 'ffdbb4',
    this.top = 'shortHair',
    this.hairColor = '2c1b18',
    this.hatColor = '2c1b18',
    this.accessories = 'none',
    this.accessoriesColor = '262e33',
    this.facialHair = 'none',
    this.facialHairColor = '2c1b18',
    this.clothes = 'blazerAndShirt',
    this.clothesColor = 'ffffff',
    this.clothesGraphic = 'none',
    this.eyes = 'default',
    this.eyebrows = 'default',
    this.mouth = 'default',
    this.bgScene = 0,
  });

  /// Convert to DiceBear Options Map
  Map<String, Object> toMap() {
    return {
      'seed': seed,
      if (skinColor != 'none') 'skinColor': [skinColor],
      if (top != 'none') 'topVariant': [top],
      if (hairColor != 'none') 'hairColor': [hairColor],
      if (hatColor != 'none') 'hatColor': [hatColor],
      if (accessories != 'none') 'accessoriesVariant': [accessories],
      if (accessoriesColor != 'none') 'accessoriesColor': [accessoriesColor],
      if (facialHair != 'none') 'facialHairVariant': [facialHair],
      if (facialHairColor != 'none') 'facialHairColor': [facialHairColor],
      if (clothes != 'none') 'clothesVariant': [clothes],
      if (clothesColor != 'none') 'clothesColor': [clothesColor],
      if (clothesGraphic != 'none') 'clothesGraphicVariant': [clothesGraphic],
      if (eyes != 'none') 'eyesVariant': [eyes],
      if (eyebrows != 'none') 'eyebrowsVariant': [eyebrows],
      if (mouth != 'none') 'mouthVariant': [mouth],
    };
  }

  /// Create a MomentoAvatar completely from a seed using pseudo-random selection
  factory MomentoAvatar.fromSeed(String seed) {
    final bytes = utf8.encode(seed);
    final hash = sha256.convert(bytes).bytes;

    int nextIndex(int i, List<String> options) {
      return hash[i % hash.length] % options.length;
    }

    return MomentoAvatar(
      seed: seed,
      skinColor: skinColors[nextIndex(0, skinColors)],
      top: tops[nextIndex(1, tops)],
      hairColor: hairColors[nextIndex(2, hairColors)],
      hatColor: clothesColors[nextIndex(3, clothesColors)],
      accessories: accessoriesList[nextIndex(4, accessoriesList)],
      accessoriesColor: clothesColors[nextIndex(5, clothesColors)],
      facialHair: facialHairs[nextIndex(6, facialHairs)],
      facialHairColor: hairColors[nextIndex(7, hairColors)],
      clothes: clothings[nextIndex(8, clothings)],
      clothesColor: clothesColors[nextIndex(9, clothesColors)],
      clothesGraphic: clothesGraphics[nextIndex(10, clothesGraphics)],
      eyes: eyesList[nextIndex(11, eyesList)],
      eyebrows: eyebrowsList[nextIndex(12, eyebrowsList)],
      mouth: mouths[nextIndex(13, mouths)],
      bgScene: hash[14 % hash.length] % 8,
    );
  }

  // Define valid properties from the schema
  static const skinColors = ['614335', 'd08b5b', 'ae5d29', 'edb98a', 'ffdbb4', 'fd9841', 'f8d25c'];
  static const hairColors = ['a55728', '2c1b18', 'b58143', 'd6b370', '724133', '4a312c', 'f59797', 'ecdcbf', 'c93305', 'e8e1e1'];
  static const clothesColors = ['262e33', '65c9ff', '5199e4', '25557c', 'e6e6e6', '929598', '3c4f5c', 'b1e2ff', 'a7ffc4', 'ffafb9', 'ffffb1', 'ff488e', 'ff5c5c', 'ffffff'];
  
  static const tops = ['noHair', 'eyepatch', 'hat', 'hijab', 'turban', 'winterHat1', 'winterHat2', 'winterHat3', 'winterHat4', 'longHair', 'bob', 'bun', 'curly', 'curvy', 'dreads', 'frida', 'fro', 'froBand', 'notTooLong', 'shavedSides', 'miaWallace', 'straight01', 'straight02', 'straightStrand', 'shortHair', 'dreads01', 'dreads02', 'frizzle', 'shaggy', 'shaggyMullet', 'shortCurly', 'shortFlat', 'shortRound', 'shortWaved', 'sides', 'theCaesar', 'theCaesarAndSidePart'];
  static const accessoriesList = ['none', 'kurt', 'prescription01', 'prescription02', 'round', 'sunglasses', 'wayfarers'];
  static const facialHairs = ['none', 'beardMedium', 'beardLight', 'beardMajestic', 'moustacheFancy', 'moustacheMagnum'];
  static const clothings = ['blazerAndShirt', 'blazerAndSweater', 'collarAndSweater', 'graphicShirt', 'hoodie', 'overall', 'shirtCrewNeck', 'shirtScoopNeck', 'shirtVNeck'];
  static const clothesGraphics = ['none', 'bat', 'bear', 'cumbia', 'deer', 'diamond', 'hola', 'pizza', 'resist', 'skull', 'skullOutline'];
  static const eyesList = ['close', 'cry', 'default', 'dizzy', 'eyeRoll', 'happy', 'hearts', 'side', 'squint', 'surprised', 'wink', 'winkWacky'];
  static const eyebrowsList = ['angry', 'angryNatural', 'default', 'defaultNatural', 'flatNatural', 'raisedExcited', 'raisedExcitedNatural', 'sadConcerned', 'sadConcernedNatural', 'unibrowNatural', 'upDown', 'upDownNatural'];
  static const mouths = ['concerned', 'default', 'disbelief', 'eating', 'grimace', 'sad', 'screamOpen', 'serious', 'smile', 'smirk', 'twinkle', 'vomit'];

  // Keep compatibility for bg Gradients
  static const List<List<int>> bgGradients = [
    [0xFFFFD6E7, 0xFFE8729A], // Pink
    [0xFFFFB5C8, 0xFFE5366A], // Strong Pink
    [0xFFFBC8D4, 0xFFEFB8CF], // Soft Pink
    [0xFFD8B4FE, 0xFFA855F7], // Purple
    [0xFFC4B5FD, 0xFF8B5CF6], // Indigo
    [0xFFA5F3FC, 0xFF06B6D4], // Cyan
    [0xFFBBF7D0, 0xFF22C55E], // Green
    [0xFFFDE047, 0xFFEAB308], // Yellow
  ];

  MomentoAvatar copyWith({
    String? skinColor,
    String? top,
    String? hairColor,
    String? hatColor,
    String? accessories,
    String? accessoriesColor,
    String? facialHair,
    String? facialHairColor,
    String? clothes,
    String? clothesColor,
    String? clothesGraphic,
    String? eyes,
    String? eyebrows,
    String? mouth,
    int? bgScene,
  }) {
    return MomentoAvatar(
      seed: seed,
      skinColor: skinColor ?? this.skinColor,
      top: top ?? this.top,
      hairColor: hairColor ?? this.hairColor,
      hatColor: hatColor ?? this.hatColor,
      accessories: accessories ?? this.accessories,
      accessoriesColor: accessoriesColor ?? this.accessoriesColor,
      facialHair: facialHair ?? this.facialHair,
      facialHairColor: facialHairColor ?? this.facialHairColor,
      clothes: clothes ?? this.clothes,
      clothesColor: clothesColor ?? this.clothesColor,
      clothesGraphic: clothesGraphic ?? this.clothesGraphic,
      eyes: eyes ?? this.eyes,
      eyebrows: eyebrows ?? this.eyebrows,
      mouth: mouth ?? this.mouth,
      bgScene: bgScene ?? this.bgScene,
    );
  }
}

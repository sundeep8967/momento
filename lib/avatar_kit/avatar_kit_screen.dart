import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/colors.dart';
import '../data/friends_repository.dart';
import 'momento_avatar.dart';
import 'avatar_widget.dart';
import 'dart:convert';

class AvatarKitScreen extends StatefulWidget {
  const AvatarKitScreen({super.key});

  @override
  State<AvatarKitScreen> createState() => _AvatarKitScreenState();
}

class _AvatarKitScreenState extends State<AvatarKitScreen>
    with TickerProviderStateMixin {
  late MomentoAvatar _avatar;
  int _categoryIndex = 0;
  bool _isSaving = false;
  late AnimationController _previewAnim;

  final _categories = const [
    {'icon': '🎨', 'name': 'Skin'},
    {'icon': '💇', 'name': 'Hair'},
    {'icon': '🧢', 'name': 'Headwear'},
    {'icon': '👁️', 'name': 'Eyes'},
    {'icon': '👄', 'name': 'Mouth'},
    {'icon': '🕶️', 'name': 'Accessories'},
    {'icon': '🧔', 'name': 'Facial Hair'},
    {'icon': '👕', 'name': 'Outfit'},
    {'icon': '🌌', 'name': 'Background'},
  ];

  @override
  void initState() {
    super.initState();
    _avatar = MomentoAvatar.fromSeed(FirebaseAuth.instance.currentUser?.uid ?? 'guest');
    _loadExistingAvatar();
    
    _previewAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  Future<void> _loadExistingAvatar() async {
    final user = await FriendsRepository.instance.getUserProfile(FirebaseAuth.instance.currentUser?.uid ?? '');
    if (user != null && user.avatar != null) {
      setState(() {
        _avatar = user.avatar!;
      });
    }
  }

  @override
  void dispose() {
    _previewAnim.dispose();
    super.dispose();
  }

  void _updateAvatar(MomentoAvatar updated) {
    setState(() => _avatar = updated);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final json = jsonEncode({
        'seed': _avatar.seed,
        'skinColor': _avatar.skinColor,
        'top': _avatar.top,
        'hairColor': _avatar.hairColor,
        'hatColor': _avatar.hatColor,
        'accessories': _avatar.accessories,
        'accessoriesColor': _avatar.accessoriesColor,
        'facialHair': _avatar.facialHair,
        'facialHairColor': _avatar.facialHairColor,
        'clothes': _avatar.clothes,
        'clothesColor': _avatar.clothesColor,
        'clothesGraphic': _avatar.clothesGraphic,
        'eyes': _avatar.eyes,
        'eyebrows': _avatar.eyebrows,
        'mouth': _avatar.mouth,
        'bgScene': _avatar.bgScene,
      });
      await FriendsRepository.instance.updateProfilePicture('avatar:$json');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.white),
                SizedBox(width: 8),
                Text('Avatar saved! 🎉'),
              ],
            ),
            backgroundColor: SetlogColors.momentoPink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColors = MomentoAvatar.bgGradients[_avatar.bgScene];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildPreviewStage(bgColors),
            _buildCategoryTabs(),
            Expanded(child: _buildOptionsPanel()),
            _buildSaveBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(CupertinoIcons.xmark, color: Colors.black87, size: 18),
              ),
            ),
            const Expanded(
              child: Text(
                'Avatar Studio',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _updateAvatar(MomentoAvatar.fromSeed('random${DateTime.now().millisecondsSinceEpoch}')),
                  child: _presetChip('🎲', 'Random'),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _presetChip(String emoji, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('$emoji $label', style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500)),
      );

  Widget _buildPreviewStage(List<int> bgColors) {
    return AnimatedBuilder(
      animation: _previewAnim,
      builder: (context, child) {
        final bob = _previewAnim.value * 4.0;
        return Transform.translate(
          offset: Offset(0, -bob),
          child: child,
        );
      },
      child: Container(
        height: 240,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [Color(bgColors[0]), Color(bgColors[1])],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(bgColors[0]).withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ...List.generate(6, (i) {
              return Positioned(
                left: 120 + 90 * (0.5 + 0.5 * (i % 3 == 0 ? 1 : -1)),
                top: 120 + 70 * (0.5 + 0.5 * (i % 2 == 0 ? 1 : -1)),
                child: Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              );
            }),
            RepaintBoundary(
              child: AvatarWidget(
                avatar: _avatar,
                size: 200,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() => Container(
        height: 52,
        margin: const EdgeInsets.symmetric(vertical: 12),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _categories.length,
          itemBuilder: (context, i) {
            final selected = _categoryIndex == i;
            return GestureDetector(
              onTap: () => setState(() => _categoryIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? SetlogColors.momentoPink : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: selected ? SetlogColors.momentoPink : Colors.black12,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_categories[i]['icon']!, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 5),
                    Text(
                      _categories[i]['name']!,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

  Widget _buildOptionsPanel() => Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: _buildCategoryContent(),
          ),
        ),
      );

  Widget _buildCategoryContent() {
    switch (_categoryIndex) {
      case 0: return _buildColorGrid(
        title: 'Skin Tone',
        colorsHex: MomentoAvatar.skinColors,
        selectedHex: _avatar.skinColor,
        onTap: (hex) => _updateAvatar(_avatar.copyWith(skinColor: hex)),
      );
      case 1: return _buildHairPanel();
      case 2: return _buildHeadwearPanel();
      case 3: return _buildEyePanel();
      case 4: return _buildStringGrid(
        items: MomentoAvatar.mouths,
        selected: _avatar.mouth,
        onTap: (val) => _updateAvatar(_avatar.copyWith(mouth: val)),
      );
      case 5: return _buildAccessoriesPanel();
      case 6: return _buildStringGrid(
        items: MomentoAvatar.facialHairs,
        selected: _avatar.facialHair,
        onTap: (val) => _updateAvatar(_avatar.copyWith(facialHair: val)),
      );
      case 7: return _buildOutfitPanel();
      case 8: return _buildBgPanel();
      default: return const SizedBox();
    }
  }

  Widget _buildColorGrid({
    required String title,
    required List<String> colorsHex,
    required String selectedHex,
    required void Function(String) onTap,
  }) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: colorsHex.map((hex) {
                final isSelected = selectedHex == hex;
                return GestureDetector(
                  onTap: () => onTap(hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color(int.parse('0xFF$hex')),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? SetlogColors.momentoPink : Colors.black12,
                        width: isSelected ? 3.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: SetlogColors.momentoPink.withValues(alpha: 0.5), blurRadius: 10)]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(CupertinoIcons.checkmark, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );

  Widget _buildHairPanel() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hair Style', style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            _buildStringGrid(
              items: MomentoAvatar.tops.where((t) => !t.toLowerCase().contains('hat') && t != 'turban' && t != 'hijab').toList(),
              selected: _avatar.top,
              onTap: (val) => _updateAvatar(_avatar.copyWith(top: val)),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            _buildColorGrid(
              title: 'Hair Color',
              colorsHex: MomentoAvatar.hairColors,
              selectedHex: _avatar.hairColor,
              onTap: (val) => _updateAvatar(_avatar.copyWith(hairColor: val)),
            ),
          ],
        ),
      );

  Widget _buildHeadwearPanel() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Headwear Style', style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            _buildStringGrid(
              items: ['none', ...MomentoAvatar.tops.where((t) => t.toLowerCase().contains('hat') || t == 'turban' || t == 'hijab')],
              selected: _avatar.top,
              onTap: (val) => _updateAvatar(_avatar.copyWith(top: val)),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            if (_avatar.top.toLowerCase().contains('hat') || _avatar.top == 'turban' || _avatar.top == 'hijab')
              _buildColorGrid(
                title: 'Headwear Color',
                colorsHex: MomentoAvatar.clothesColors, // Hats usually use same colors as clothes
                selectedHex: _avatar.hatColor,
                onTap: (val) => _updateAvatar(_avatar.copyWith(hatColor: val)),
              ),
          ],
        ),
      );

  Widget _buildEyePanel() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Eye Shape', style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            _buildStringGrid(
              items: MomentoAvatar.eyesList,
              selected: _avatar.eyes,
              onTap: (val) => _updateAvatar(_avatar.copyWith(eyes: val)),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            const Text('Eyebrows', style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            _buildStringGrid(
              items: MomentoAvatar.eyebrowsList,
              selected: _avatar.eyebrows,
              onTap: (val) => _updateAvatar(_avatar.copyWith(eyebrows: val)),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      );

  Widget _buildAccessoriesPanel() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Glasses & Accessories', style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            _buildStringGrid(
              items: MomentoAvatar.accessoriesList,
              selected: _avatar.accessories,
              onTap: (val) => _updateAvatar(_avatar.copyWith(accessories: val)),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            if (_avatar.accessories != 'none')
              _buildColorGrid(
                title: 'Frame / Accessory Color',
                colorsHex: MomentoAvatar.clothesColors,
                selectedHex: _avatar.accessoriesColor,
                onTap: (val) => _updateAvatar(_avatar.copyWith(accessoriesColor: val)),
              ),
          ],
        ),
      );

  Widget _buildOutfitPanel() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Clothing Style', style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            _buildStringGrid(
              items: MomentoAvatar.clothings,
              selected: _avatar.clothes,
              onTap: (val) => _updateAvatar(_avatar.copyWith(clothes: val)),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            _buildColorGrid(
              title: 'Clothing Color',
              colorsHex: MomentoAvatar.clothesColors,
              selectedHex: _avatar.clothesColor,
              onTap: (val) => _updateAvatar(_avatar.copyWith(clothesColor: val)),
            ),
            if (_avatar.clothes == 'graphicShirt') ...[
              const SizedBox(height: 24),
              const Text('Shirt Graphic', style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 12),
              _buildStringGrid(
                items: MomentoAvatar.clothesGraphics,
                selected: _avatar.clothesGraphic,
                onTap: (val) => _updateAvatar(_avatar.copyWith(clothesGraphic: val)),
                padding: EdgeInsets.zero,
              ),
            ]
          ],
        ),
      );

  Widget _buildBgPanel() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Background Scene', style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 14),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.4,
                ),
                itemCount: MomentoAvatar.bgGradients.length,
                itemBuilder: (context, i) {
                  final isSelected = _avatar.bgScene == i;
                  final colors = MomentoAvatar.bgGradients[i];
                  return GestureDetector(
                    onTap: () => _updateAvatar(_avatar.copyWith(bgScene: i)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(colors[0]), Color(colors[1])],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? Colors.black87 : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: Color(colors[0]).withValues(alpha: 0.5), blurRadius: 12)]
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );

  Widget _buildStringGrid({
    required List<String> items,
    required String selected,
    required void Function(String) onTap,
    EdgeInsets? padding,
  }) =>
      Padding(
        padding: padding ?? const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            final isSelected = selected == item;
            return GestureDetector(
              onTap: () => onTap(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? SetlogColors.momentoPink : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? SetlogColors.momentoPink : Colors.black12,
                  ),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _buildSaveBar() => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: SetlogColors.momentoPink,
              foregroundColor: Colors.white,
              disabledBackgroundColor: SetlogColors.momentoPink.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isSaving
                ? const CupertinoActivityIndicator(color: Colors.white)
                : const Text(
                    'Save My Avatar  ✨',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      );
}

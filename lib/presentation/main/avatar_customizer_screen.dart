import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/colors.dart';
import '../../data/friends_repository.dart';

class AvatarCustomizerScreen extends StatefulWidget {
  const AvatarCustomizerScreen({super.key});

  @override
  State<AvatarCustomizerScreen> createState() => _AvatarCustomizerScreenState();
}

class _AvatarCustomizerScreenState extends State<AvatarCustomizerScreen> {
  int _selectedCategoryIndex = 0;
  bool _isSaving = false;

  // Customization Selections
  String _selectedSkinTone = 'f8d5c2'; // Hex tone
  String _selectedStyle = 'adventurer'; // adventurer, micah, bottts-neutral, big-smile, lorelei
  String _selectedHair = 'short';
  String _selectedBackgroundVibe = 'Money Bills';

  final List<Map<String, String>> _categories = [
    {'name': 'Style', 'icon': '🎭'},
    {'name': 'Skin', 'icon': '🎨'},
    {'name': 'Background', 'icon': '🌌'},
    {'name': 'Theme', 'icon': '✨'},
  ];

  final List<Map<String, String>> _avatarStyles = [
    {'id': 'adventurer', 'name': '3D Adventurer'},
    {'id': 'micah', 'name': '3D Micah'},
    {'id': 'bottts-neutral', 'name': '3D Mech Avatar'},
    {'id': 'big-smile', 'name': '3D Emoji Bitmoji'},
    {'id': 'lorelei', 'name': '3D Lorelei'},
  ];

  final List<Map<String, String>> _skinTones = [
    {'hex': 'f8d5c2', 'name': 'Fair'},
    {'hex': 'e0ac69', 'name': 'Warm'},
    {'hex': 'c68642', 'name': 'Olive'},
    {'hex': '8d5524', 'name': 'Deep'},
    {'hex': 'ffdbac', 'name': 'Sunset'},
  ];

  final List<Map<String, dynamic>> _backgroundVibes = [
    {
      'name': 'Money Bills',
      'colors': [Color(0xFF85BB65), Color(0xFF2E7D32)],
      'emoji': '💵',
    },
    {
      'name': 'Cyber Neon',
      'colors': [Color(0xFF00F2FE), Color(0xFF4FACFE)],
      'emoji': '⚡',
    },
    {
      'name': 'Studio Pink',
      'colors': [SetlogColors.momentoPink, Color(0xFFE5366A)],
      'emoji': '💖',
    },
    {
      'name': 'Sunset Palm',
      'colors': [Color(0xFFFF512F), Color(0xFFDD2476)],
      'emoji': '🌅',
    },
  ];

  String _buildAvatarUrl() {
    return 'https://api.dicebear.com/7.x/$_selectedStyle/png?seed=$_selectedSkinTone&$_selectedHair&backgroundColor=$_selectedSkinTone';
  }

  Future<void> _saveAvatar() async {
    setState(() => _isSaving = true);
    final avatarUrl = _buildAvatarUrl();
    try {
      await FriendsRepository.instance.updateProfilePicture(avatarUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('3D Avatar updated successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save avatar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentVibe = _backgroundVibes.firstWhere(
      (v) => v['name'] == _selectedBackgroundVibe,
      orElse: () => _backgroundVibes[2],
    );

    return Scaffold(
      backgroundColor: const Color(0xFF140B12),
      appBar: CupertinoNavigationBar(
        middle: const Text(
          '3D Avatar Studio',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A0A10).withOpacity(0.9),
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(CupertinoIcons.xmark, color: Colors.white),
        ),
        trailing: _isSaving
            ? const CupertinoActivityIndicator(color: SetlogColors.momentoPink)
            : GestureDetector(
                onTap: _saveAvatar,
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: SetlogColors.momentoPink,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 3D Preview Stage
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: (currentVibe['colors'] as List<Color>),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (currentVibe['colors'] as List<Color>)[0].withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background Emoji pattern
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Text(
                        currentVibe['emoji'] as String,
                        style: TextStyle(fontSize: 48, color: Colors.white.withOpacity(0.3)),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: Text(
                        currentVibe['emoji'] as String,
                        style: TextStyle(fontSize: 36, color: Colors.white.withOpacity(0.3)),
                      ),
                    ),
                    // 3D Avatar Image Render
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        key: ValueKey(_buildAvatarUrl()),
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.15),
                          border: Border.all(color: Colors.white.withOpacity(0.4), width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5)),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.network(
                            _buildAvatarUrl(),
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(child: CupertinoActivityIndicator(color: Colors.white));
                            },
                          ),
                        ),
                      ).animate().scale(duration: 250.ms, curve: Curves.easeOutBack),
                    ),
                  ],
                ),
              ),
            ),

            // Customization Options Panel
            Expanded(
              flex: 4,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1E121C),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    // Category Selector
                    Container(
                      height: 50,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = _selectedCategoryIndex == index;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCategoryIndex = index),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? SetlogColors.momentoPink
                                    : Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Text(category['icon']!, style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 6),
                                  Text(
                                    category['name']!,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.white70,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Options Grid/List
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildCategoryContent(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryContent() {
    switch (_selectedCategoryIndex) {
      case 0: // Style
        return ListView.builder(
          itemCount: _avatarStyles.length,
          itemBuilder: (context, index) {
            final style = _avatarStyles[index];
            final isSelected = _selectedStyle == style['id'];
            return ListTile(
              onTap: () => setState(() => _selectedStyle = style['id']!),
              leading: Icon(
                isSelected ? CupertinoIcons.checkmark_alt_circle_fill : CupertinoIcons.circle,
                color: isSelected ? SetlogColors.momentoPink : Colors.white38,
              ),
              title: Text(
                style['name']!,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            );
          },
        );
      case 1: // Skin
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _skinTones.length,
          itemBuilder: (context, index) {
            final tone = _skinTones[index];
            final isSelected = _selectedSkinTone == tone['hex'];
            final colorInt = int.parse('FF${tone['hex']}', radix: 16);
            return GestureDetector(
              onTap: () => setState(() => _selectedSkinTone = tone['hex']!),
              child: Container(
                decoration: BoxDecoration(
                  color: Color(colorInt),
                  shape: BoxShape.circle,
                  border: isSelected ? Border.all(color: SetlogColors.momentoPink, width: 4) : null,
                ),
              ),
            );
          },
        );
      case 2: // Background Vibe
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemCount: _backgroundVibes.length,
          itemBuilder: (context, index) {
            final vibe = _backgroundVibes[index];
            final isSelected = _selectedBackgroundVibe == vibe['name'];
            return GestureDetector(
              onTap: () => setState(() => _selectedBackgroundVibe = vibe['name'] as String),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: vibe['colors'] as List<Color>),
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                ),
                child: Center(
                  child: Text(
                    '${vibe['emoji']} ${vibe['name']}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          },
        );
      default:
        return const Center(
          child: Text('Customization preset ready!', style: TextStyle(color: Colors.white54)),
        );
    }
  }
}

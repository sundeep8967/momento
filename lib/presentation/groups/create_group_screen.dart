import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momento/data/friends_repository.dart';
import 'package:momento/theme/colors.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  bool _isLoading = true;
  bool _isCreating = false;
  
  List<UserProfile> _friends = [];
  final Set<String> _selectedFriendUids = {};
  
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final friends = await FriendsRepository.instance.getMutualFriends();
      if (mounted) {
        setState(() {
          _friends = friends;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedFriendUids.isEmpty) return;

    setState(() => _isCreating = true);
    try {
      await FriendsRepository.instance.createGroup(name, _selectedFriendUids.toList());
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group "$name" created!'), backgroundColor: SetlogColors.authTerminalAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SetlogColors.collectionsHomeBackground,
      appBar: AppBar(
        backgroundColor: SetlogColors.collectionsHomeBackground,
        title: const Text('New Group', style: TextStyle(color: SetlogColors.collectionsHomeTextPrimary, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: SetlogColors.collectionsHomeTextPrimary),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: SetlogColors.brownPrimary))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Group Name',
                      filled: true,
                      fillColor: SetlogColors.brownPrimary.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.group, color: SetlogColors.brownPrimary),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Select Members', style: TextStyle(color: SetlogColors.collectionsHomeTextSecondary, fontWeight: FontWeight.bold)),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: SetlogColors.authSurface,
                    child: ListView.separated(
                      itemCount: _friends.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, indent: 76, color: SetlogColors.authStrokeSoft),
                      itemBuilder: (context, index) {
                        final friend = _friends[index];
                        final isSelected = _selectedFriendUids.contains(friend.uid);
                        
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: SetlogColors.brownPrimary.withOpacity(0.1),
                            child: Text(
                              friend.username.isNotEmpty ? friend.username[0].toUpperCase() : '?',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: SetlogColors.brownPrimary),
                            ),
                          ),
                          title: Text(friend.username, style: const TextStyle(fontWeight: FontWeight.w500, color: SetlogColors.collectionsHomeTextPrimary)),
                          trailing: Icon(
                            isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                            color: isSelected ? SetlogColors.brownPrimary : CupertinoColors.systemGrey4,
                            size: 28,
                          ),
                          onTap: () {
                            setState(() {
                              if (isSelected) _selectedFriendUids.remove(friend.uid);
                              else _selectedFriendUids.add(friend.uid);
                            });
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _nameController.text.trim().isNotEmpty && _selectedFriendUids.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CupertinoButton.filled(
                  onPressed: _isCreating ? null : _createGroup,
                  borderRadius: BorderRadius.circular(14),
                  child: _isCreating 
                    ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                    : const Text('Create Group', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            )
          : null,
    );
  }
}

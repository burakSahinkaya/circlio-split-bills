import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../auth/domain/app_user.dart';
import '../data/group_provider.dart';
import '../../../core/utils/l10n_extension.dart';
import 'package:share_plus/share_plus.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();

  String _selectedType = 'trip';
  String _selectedCurrency = 'USD'; // Default to USD
  final List<AppUser> _invitedMembers = [];

  File? _selectedPhoto;
  bool _isCreating = false;

  // Search state
  Timer? _debounceTimer;
  bool _isSearching = false;
  List<AppUser> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.chooseGroupPhoto,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(
                Icons.camera_alt_rounded,
                color: context.colors.primary,
              ),
              title: Text(
                context.l10n.takePhoto,
                style: TextStyle(color: context.colors.textPrimary),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(
                Icons.photo_library_rounded,
                color: context.colors.accent,
              ),
              title: Text(
                context.l10n.chooseFromLibrary,
                style: TextStyle(color: context.colors.textPrimary),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (_selectedPhoto != null)
              ListTile(
                leading: Icon(
                  Icons.delete_rounded,
                  color: context.colors.danger,
                ),
                title: Text(
                  context.l10n.removePhoto,
                  style: TextStyle(color: context.colors.danger),
                ),
                onTap: () {
                  setState(() => _selectedPhoto = null);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() => _selectedPhoto = File(pickedFile.path));
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounceTimer = Timer(Duration(milliseconds: 500), () async {
      try {
        final service = ref.read(groupServiceProvider);
        final results = await service.searchUsersByNickname(query);
        if (mounted && _searchController.text == query) {
          setState(() {
            // filter out users already invited
            final invitedIds = _invitedMembers.map((e) => e.id).toSet();
            _searchResults = results
                .where((u) => !invitedIds.contains(u.id))
                .toList();
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  void _addMember(AppUser user) {
    setState(() {
      _invitedMembers.add(user);
      _searchController.clear();
      _searchResults = [];
    });
  }

  void _removeMember(int index) {
    setState(() => _invitedMembers.removeAt(index));
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isCreating = true);
    try {
      final service = ref.read(groupServiceProvider);
      final group = await service.createGroup(
        name: name,
        type: _selectedType,
        currency: _selectedCurrency,
        groupPhoto: _selectedPhoto,
        invitedUserIds: _invitedMembers.map((e) => e.id).toList(),
      );
      if (mounted) {
        // Show share invite link dialog
        await _showShareInviteDialog(group.id, name);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: context.colors.danger,
          ),
        );
      }
    }
  }

  Future<void> _showShareInviteDialog(String groupId, String groupName) async {
    await showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.success.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 36,
                color: context.colors.success,
              ),
            ),
            SizedBox(height: 16),
            Text(
              context.l10n.groupCreated,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              context.l10n.shareInviteLinkDesc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: context.colors.textSecondary,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    final service = ref.read(groupServiceProvider);
                    final link = await service.generateInviteLink(groupId);
                    await SharePlus.instance.share(
                      ShareParams(
                        text: 'Join "$groupName" on Circlio!\n$link',
                      ),
                    );
                  } catch (e) {
                    // Silently fail — the group is already created
                    print('Failed to share invite link: $e');
                  }
                  if (mounted) context.go('/groups');
                },
                icon: Icon(Icons.share_rounded, size: 20),
                label: Text(context.l10n.shareInviteLink),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.background,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (mounted) context.go('/groups');
              },
              child: Text(
                context.l10n.skipForNow,
                style: TextStyle(
                  color: context.colors.textTertiary,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    // If dismissed without action, still go to groups
    if (mounted) context.go('/groups');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.createGroup),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo picker
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.colors.surfaceLight,
                        border: Border.all(color: context.colors.border),
                        image: _selectedPhoto != null
                            ? DecorationImage(
                                image: FileImage(_selectedPhoto!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _selectedPhoto == null
                          ? Icon(
                              Icons.groups_rounded,
                              size: 40,
                              color: context.colors.textTertiary,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.colors.primary,
                          border: Border.all(
                            color: context.colors.background,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32),

            // Group name
            Text(
              context.l10n.groupName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.colors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: context.l10n.nameHint,
                prefixIcon: Icon(
                  Icons.edit_rounded,
                  color: context.colors.textTertiary,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: context.colors.primary,
                    width: 2,
                  ),
                ),
              ),
              style: TextStyle(color: context.colors.textPrimary),
            ),
            SizedBox(height: 28),

            // Currency selection
            Text(
              context.l10n.currency,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.colors.textSecondary,
              ),
            ),
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: context.colors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCurrency,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      value: 'USD',
                      child: Text('\$ USD - US Dollar'),
                    ),
                    DropdownMenuItem(value: 'EUR', child: Text('€ EUR - Euro')),
                    DropdownMenuItem(
                      value: 'GBP',
                      child: Text('£ GBP - British Pound'),
                    ),
                    DropdownMenuItem(
                      value: 'JPY',
                      child: Text('¥ JPY - Japanese Yen'),
                    ),
                    DropdownMenuItem(
                      value: 'AUD',
                      child: Text('A\$ AUD - Australian Dollar'),
                    ),
                    DropdownMenuItem(
                      value: 'CAD',
                      child: Text('C\$ CAD - Canadian Dollar'),
                    ),
                    DropdownMenuItem(
                      value: 'CHF',
                      child: Text('CHF CHF - Swiss Franc'),
                    ),
                    DropdownMenuItem(
                      value: 'CNY',
                      child: Text('¥ CNY - Chinese Yuan'),
                    ),
                    DropdownMenuItem(
                      value: 'INR',
                      child: Text('₹ INR - Indian Rupee'),
                    ),
                    DropdownMenuItem(
                      value: 'TRY',
                      child: Text('₺ TRY - Turkish Lira'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCurrency = value);
                    }
                  },
                  dropdownColor: context.colors.surfaceLight,
                  style: TextStyle(color: context.colors.textPrimary),
                ),
              ),
            ),
            SizedBox(height: 28),

            // Group type
            Text(
              context.l10n.type,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.colors.textSecondary,
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppConstants.groupTypeEmojis.entries.map((entry) {
                final isSelected = _selectedType == entry.key;
                
                String label = AppConstants.groupTypeLabels[entry.key] ?? '';
                switch(entry.key) {
                  case 'trip': label = context.l10n.trip; break;
                  case 'house': label = context.l10n.house; break;
                  case 'couple': label = context.l10n.couple; break;
                  case 'friends': label = context.l10n.friends; break;
                  case 'family': label = context.l10n.family; break;
                  case 'work': label = context.l10n.work; break;
                  case 'other': label = context.l10n.other; break;
                }

                return GestureDetector(
                  onTap: () => setState(() => _selectedType = entry.key),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.colors.primary.withValues(alpha: 0.15)
                          : context.colors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? context.colors.primary
                            : context.colors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(entry.value, style: TextStyle(fontSize: 18)),
                        SizedBox(width: 8),
                        Text(
                          label,
                          style: TextStyle(
                            color: isSelected
                                ? context.colors.primary
                                : context.colors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 28),

            // Invite Members section
            Row(
              children: [
                Text(
                  context.l10n.inviteMembers,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textSecondary,
                  ),
                ),
                Spacer(),
                Text(
                  '${_invitedMembers.length} ${context.l10n.selected}',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.colors.textTertiary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (_invitedMembers.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_invitedMembers.length, (index) {
                  final u = _invitedMembers[index];
                  return Chip(
                    backgroundColor: context.colors.surfaceElevated,
                    side: BorderSide(color: context.colors.border),
                    avatar: AvatarCircle(
                      name: u.name,
                      imageUrl: u.avatarUrl,
                      size: 24,
                    ),
                    label: Text(
                      u.username ?? u.name,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    onDeleted: () => _removeMember(index),
                    deleteIcon: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: context.colors.textTertiary,
                    ),
                  );
                }),
              ),
              SizedBox(height: 16),
            ],

            // Add member search
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: context.l10n.searchByUsername,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: context.colors.textTertiary,
                ),
                suffixIcon: _isSearching
                    ? Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              context.colors.primary,
                            ),
                          ),
                        ),
                      )
                    : null,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: context.colors.primary,
                    width: 2,
                  ),
                ),
              ),
              style: TextStyle(color: context.colors.textPrimary),
            ),

            if (_searchResults.isNotEmpty) ...[
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: context.colors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colors.border),
                ),
                child: Column(
                  children: _searchResults.map((u) {
                    return ListTile(
                      leading: AvatarCircle(
                        name: u.name,
                        imageUrl: u.avatarUrl,
                        size: 36,
                      ),
                      title: Text(
                        u.username ?? u.name,
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        u.name,
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      trailing: Text(
                        context.l10n.invite,
                        style: TextStyle(
                          color: context.colors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      onTap: () => _addMember(u),
                    );
                  }).toList(),
                ),
              ),
            ],

            SizedBox(height: 48),

            // Actions
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: context.colors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      context.l10n.cancel,
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GradientButton(
                    label: context.l10n.createGroup,
                    icon: Icons.check_rounded,
                    width: double.infinity,
                    isLoading: _isCreating,
                    onPressed:
                        _nameController.text.trim().isNotEmpty && !_isCreating
                        ? _createGroup
                        : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

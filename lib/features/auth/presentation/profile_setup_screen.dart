import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';
import '../data/auth_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  File? _selectedPhoto;
  bool _isCheckingUsername = false;
  bool _isUsernameAvailable = false;
  String? _usernameError;
  Timer? _debounceTimer;
  bool _isCreatingProfile = false;

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(() => setState(() {}));
    _lastNameController.addListener(() => setState(() {}));

    _prefillUserData();
  }

  void _prefillUserData() {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null &&
        user.displayName != null &&
        user.displayName!.trim().isNotEmpty) {
      final parts = user.displayName!.trim().split(' ');
      if (parts.isNotEmpty) {
        _firstNameController.text = parts.first;
        if (parts.length > 1) {
          _lastNameController.text = parts.sublist(1).join(' ');
        }
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _debounceTimer?.cancel();

    final username = value.trim().toLowerCase();

    // Validate format
    if (username.isEmpty) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = null;
        _isCheckingUsername = false;
      });
      return;
    }

    if (username.length < 3) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = 'Username must be at least 3 characters';
        _isCheckingUsername = false;
      });
      return;
    }

    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(username)) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = 'Only lowercase letters, numbers, and underscores';
        _isCheckingUsername = false;
      });
      return;
    }

    if (username.length > 20) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = 'Username must be 20 characters or less';
        _isCheckingUsername = false;
      });
      return;
    }

    // Show checking state
    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    // Debounce Firestore check (500ms)
    _debounceTimer = Timer(Duration(milliseconds: 500), () async {
      final authService = ref.read(authServiceProvider);
      final available = await authService.isUsernameAvailable(username);

      if (mounted && _usernameController.text.trim().toLowerCase() == username) {
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = available;
          _usernameError = available ? null : 'Username is already taken';
        });
      }
    });
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();

    // Show bottom sheet for camera/gallery choice
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
              'Choose Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.camera_alt_rounded,
                    color: context.colors.primary),
              ),
              title: Text('Take a Photo',
                  style: TextStyle(color: context.colors.textPrimary)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            SizedBox(height: 8),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.colors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.photo_library_rounded,
                    color: context.colors.accent),
              ),
              title: Text('Choose from Library',
                  style: TextStyle(color: context.colors.textPrimary)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (_selectedPhoto != null) ...[
              SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.colors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.delete_rounded,
                      color: context.colors.danger),
                ),
                title: Text('Remove Photo',
                    style: TextStyle(color: context.colors.danger)),
                onTap: () {
                  setState(() => _selectedPhoto = null);
                  Navigator.pop(context);
                },
              ),
            ],
            SizedBox(height: 12),
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
      setState(() {
        _selectedPhoto = File(pickedFile.path);
      });
    }
  }

  Future<void> _createProfile() async {
    final username = _usernameController.text.trim().toLowerCase();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    
    if (username.isEmpty || !_isUsernameAvailable || firstName.isEmpty || lastName.isEmpty) return;

    setState(() => _isCreatingProfile = true);

    final success = await ref.read(authNotifierProvider.notifier).createProfile(
          username: username,
          firstName: firstName,
          lastName: lastName,
          profilePhoto: _selectedPhoto,
        );

    if (mounted) {
      setState(() => _isCreatingProfile = false);
      if (success) {
        context.go('/groups');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create profile. Please try again.'),
            backgroundColor: context.colors.danger,
          ),
        );
      }
    }
  }

  String get _initial {
    final username = _usernameController.text.trim();
    return username.isNotEmpty ? username[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: context.colors.heroGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                SizedBox(height: 40),

                Text(
                  'Set Up Your Profile',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Choose a photo and a unique username',
                  style: TextStyle(
                    fontSize: 15,
                    color: context.colors.textSecondary,
                  ),
                ),

                SizedBox(height: 40),

                // Profile photo picker
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _selectedPhoto == null
                              ? context.colors.primaryGradient
                              : null,
                          border: Border.all(
                            color: context.colors.primary.withValues(alpha: 0.5),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: context.colors.primary.withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                          image: _selectedPhoto != null
                              ? DecorationImage(
                                  image: FileImage(_selectedPhoto!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _selectedPhoto == null
                            ? Center(
                                child: Text(
                                  _initial,
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.colors.accent,
                            border: Border.all(
                              color: context.colors.background,
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 8),
                Text(
                  _selectedPhoto != null ? 'Tap to change' : 'Tap to add photo (optional)',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.colors.textTertiary,
                  ),
                ),

                SizedBox(height: 36),

                // Name fields
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'First Name',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: _firstNameController,
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 16,
                            ),
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              hintText: 'John',
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: context.colors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: context.colors.primary, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Last Name',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: _lastNameController,
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 16,
                            ),
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              hintText: 'Doe',
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: context.colors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: context.colors.primary, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Username field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Username',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _usernameController,
                      onChanged: _onUsernameChanged,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. burak_42',
                        prefixIcon: Icon(Icons.alternate_email_rounded,
                            color: context.colors.textTertiary),
                        suffixIcon: _buildUsernameSuffix(),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _usernameError != null
                                ? context.colors.danger
                                : _isUsernameAvailable &&
                                        _usernameController.text
                                            .trim()
                                            .isNotEmpty
                                    ? context.colors.success
                                    : context.colors.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _usernameError != null
                                ? context.colors.danger
                                : _isUsernameAvailable
                                    ? context.colors.success
                                    : context.colors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    if (_usernameError != null)
                      Row(
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 14, color: context.colors.danger),
                          SizedBox(width: 6),
                          Text(
                            _usernameError!,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.colors.danger,
                            ),
                          ),
                        ],
                      )
                    else if (_isUsernameAvailable &&
                        _usernameController.text.trim().isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 14, color: context.colors.success),
                          SizedBox(width: 6),
                          Text(
                            'Username is available!',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.colors.success,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                SizedBox(height: 40),

                // Continue button
                GradientButton(
                  label: 'Continue',
                  icon: Icons.arrow_forward_rounded,
                  width: double.infinity,
                  isLoading: _isCreatingProfile,
                  onPressed: _isUsernameAvailable &&
                          !_isCreatingProfile &&
                          _firstNameController.text.trim().isNotEmpty &&
                          _lastNameController.text.trim().isNotEmpty
                      ? _createProfile
                      : null,
                ),

                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildUsernameSuffix() {
    if (_isCheckingUsername) {
      return Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
          ),
        ),
      );
    }
    if (_isUsernameAvailable && _usernameController.text.trim().isNotEmpty) {
      return Icon(Icons.check_circle_rounded, color: context.colors.success);
    }
    if (_usernameError != null) {
      return Icon(Icons.cancel_rounded, color: context.colors.danger);
    }
    return null;
  }
}

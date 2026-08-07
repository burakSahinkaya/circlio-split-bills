import 'package:flutter/material.dart';
import '../../../core/utils/l10n_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/gradient_button.dart';
import '../data/group_provider.dart';
import '../domain/group.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  final String inviteCode;

  const JoinGroupScreen({super.key, required this.inviteCode});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isJoining = false;
  Group? _group;
  String? _error;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _fetchGroup();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchGroup() async {
    try {
      final service = ref.read(groupServiceProvider);
      final group = await service.getGroupByInviteCode(widget.inviteCode);
      if (mounted) {
        setState(() {
          _group = group;
          _isLoading = false;
          _error = group == null ? 'Invalid or expired invite link' : null;
        });
        if (group != null) {
          _animController.forward();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load group: $e';
        });
      }
    }
  }

  Future<void> _joinGroup() async {
    setState(() => _isJoining = true);
    try {
      final service = ref.read(groupServiceProvider);
      final groupId =
          await service.joinGroupByInviteCode(widget.inviteCode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome to ${_group?.name ?? 'the group'}! 🎉'),
            backgroundColor: context.colors.success,
          ),
        );
        context.go('/groups/$groupId');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isJoining = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: context.colors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.joinGroup),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/groups'),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(
                        context.colors.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Loading group info...',
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? _buildErrorState()
              : _buildGroupPreview(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.danger.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.link_off_rounded,
                size: 40,
                color: context.colors.danger,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Invalid Invite Link',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
            ),
            SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: context.colors.textSecondary,
                height: 1.4,
              ),
            ),
            SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => context.go('/groups'),
              icon: Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(context.l10n.backToGroups),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.colors.textSecondary,
                side: BorderSide(color: context.colors.border),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupPreview() {
    final group = _group!;
    final emoji = AppConstants.groupTypeEmojis[group.type] ?? '📌';
    final typeLabel = AppConstants.groupTypeLabels[group.type] ?? 'Group';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              SizedBox(height: 32),

              // Group avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: [
                      context.colors.primary.withValues(alpha: 0.15),
                      context.colors.accent.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: context.colors.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  image: group.photoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(group.photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: group.photoUrl == null
                    ? Center(
                        child: Text(emoji, style: TextStyle(fontSize: 44)),
                      )
                    : null,
              ),

              SizedBox(height: 24),

              // Group name
              Text(
                group.name,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: context.colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 8),

              // Group type badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: context.colors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: TextStyle(fontSize: 16)),
                    SizedBox(width: 6),
                    Text(
                      typeLabel,
                      style: TextStyle(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Info card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.colors.border),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.people_rounded,
                      label: 'Members',
                      value: '${group.memberIds.length}',
                    ),
                    Divider(
                      height: 24,
                      color: context.colors.border,
                    ),
                    _InfoRow(
                      icon: Icons.monetization_on_rounded,
                      label: 'Currency',
                      value: group.currency,
                    ),
                    if (group.pendingMemberIds.isNotEmpty) ...[
                      Divider(
                        height: 24,
                        color: context.colors.border,
                      ),
                      _InfoRow(
                        icon: Icons.hourglass_top_rounded,
                        label: 'Pending invites',
                        value: '${group.pendingMemberIds.length}',
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Invite code display
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.colors.border.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.vpn_key_rounded,
                      size: 18,
                      color: context.colors.textTertiary,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Invite Code: ${widget.inviteCode.toUpperCase()}',
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40),

              // Join button
              GradientButton(
                label: 'Join Group',
                icon: Icons.group_add_rounded,
                width: double.infinity,
                isLoading: _isJoining,
                onPressed: _isJoining ? null : _joinGroup,
              ),

              SizedBox(height: 16),

              // Cancel button
              TextButton(
                onPressed: () => context.go('/groups'),
                child: Text(
                  'Not now',
                  style: TextStyle(
                    color: context.colors.textTertiary,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: context.colors.textTertiary),
        SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 15,
          ),
        ),
        Spacer(),
        Text(
          value,
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

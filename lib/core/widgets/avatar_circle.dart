import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AvatarCircle extends StatelessWidget {
  final String name;
  final double size;
  final Color? backgroundColor;
  final String? imageUrl;

  const AvatarCircle({
    super.key,
    required this.name,
    this.size = 40,
    this.backgroundColor,
    this.imageUrl,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color _color(BuildContext context) {
    if (backgroundColor != null) return backgroundColor!;
    final colors = [
      context.colors.primary,
      context.colors.accent,
      context.colors.info,
      context.colors.warning,
      context.colors.success,
      Color(0xFFE040FB),
      Color(0xFFFF6E40),
      Color(0xFF448AFF),
    ];
    final index = name.hashCode.abs() % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _color(context).withValues(alpha: 0.5),
            width: 1.5,
          ),
          image: DecorationImage(
            image: NetworkImage(imageUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _color(context).withValues(alpha: 0.2),
        border: Border.all(
          color: _color(context).withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: _color(context),
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class AvatarStack extends StatelessWidget {
  final List<String> names;
  final double size;
  final int maxDisplay;

  const AvatarStack({
    super.key,
    required this.names,
    this.size = 32,
    this.maxDisplay = 4,
  });

  @override
  Widget build(BuildContext context) {
    final displayCount = names.length > maxDisplay ? maxDisplay : names.length;
    final remaining = names.length - maxDisplay;

    return SizedBox(
      height: size,
      width: size + (displayCount - 1) * (size * 0.65) + (remaining > 0 ? size * 0.65 : 0),
      child: Stack(
        children: [
          for (int i = 0; i < displayCount; i++)
            Positioned(
              left: i * (size * 0.65),
              child: AvatarCircle(name: names[i], size: size),
            ),
          if (remaining > 0)
            Positioned(
              left: displayCount * (size * 0.65),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.surfaceElevated,
                  border: Border.all(color: context.colors.border, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '+$remaining',
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: size * 0.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

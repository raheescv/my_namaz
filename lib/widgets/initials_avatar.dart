import 'dart:io';
import 'package:flutter/material.dart';

import '../theme/colors.dart';

class InitialsAvatar extends StatelessWidget {
  final String name;
  final String? avatarPath;
  final double radius;
  final VoidCallback? onTap;

  const InitialsAvatar({
    super.key,
    required this.name,
    this.avatarPath,
    this.radius = 24,
    this.onTap,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarPath != null && File(avatarPath!).existsSync();
    final child = hasAvatar
        ? CircleAvatar(
            radius: radius,
            backgroundImage: FileImage(File(avatarPath!)),
          )
        : CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.avatarColorFor(name),
            child: Text(
              _initials,
              style: TextStyle(
                fontSize: radius * 0.7,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          );

    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: child,
    );
  }
}

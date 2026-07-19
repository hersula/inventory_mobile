import 'package:flutter/material.dart';
import '../core/theme.dart';

enum BadgeTone { slate, green, amber, red, brand }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeTone tone;

  const StatusBadge(this.label, {super.key, this.tone = BadgeTone.slate});

  Color get _bg {
    switch (tone) {
      case BadgeTone.green:
        return AppColors.emerald500.withOpacity(0.12);
      case BadgeTone.amber:
        return AppColors.amber500.withOpacity(0.15);
      case BadgeTone.red:
        return AppColors.red500.withOpacity(0.12);
      case BadgeTone.brand:
        return AppColors.brand100;
      case BadgeTone.slate:
        return AppColors.slate100;
    }
  }

  Color get _fg {
    switch (tone) {
      case BadgeTone.green:
        return AppColors.emerald600;
      case BadgeTone.amber:
        return const Color(0xFFB45309);
      case BadgeTone.red:
        return AppColors.red600;
      case BadgeTone.brand:
        return AppColors.brand700;
      case BadgeTone.slate:
        return AppColors.slate600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: _fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

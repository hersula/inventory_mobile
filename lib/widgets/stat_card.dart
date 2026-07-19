import 'package:flutter/material.dart';
import '../core/theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;
  final IconData icon;
  final Color tone;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.hint,
    this.tone = AppColors.brand600,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: tone.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: tone, size: 20),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: AppColors.slate500, fontSize: 12.5, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: AppColors.slate800, fontSize: 18, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(hint!, style: const TextStyle(color: AppColors.slate400, fontSize: 11.5)),
          ],
        ],
      ),
    );
  }
}

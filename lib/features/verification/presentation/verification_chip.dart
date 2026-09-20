import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../domain/models/unified_verification_models.dart';

class VerificationChip extends StatelessWidget {
  final VerificationStatus status;
  final String? label;
  final VoidCallback? onTap;

  const VerificationChip({
    super.key,
    required this.status,
    this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String text = label ?? '';

    switch (status) {
      case VerificationStatus.verified:
        bg = AppColors.successBg;
        fg = AppColors.success;
        icon = Icons.check_circle;
        if (text.isEmpty) text = 'Verified';
        break;
      case VerificationStatus.mismatch:
        bg = Colors.deepOrange.withValues(alpha: 0.15);
        fg = Colors.deepOrange;
        icon = Icons.warning_amber;
        if (text.isEmpty) text = 'Mismatch Flagged';
        break;
      case VerificationStatus.manualReview:
      case VerificationStatus.pending:
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        icon = Icons.schedule;
        if (text.isEmpty) text = 'Under Review';
        break;
      case VerificationStatus.sourceUnavailable:
        bg = AppColors.surfaceVariant;
        fg = AppColors.textSecondary;
        icon = Icons.cloud_off;
        if (text.isEmpty) text = 'Source Outage';
        break;
      case VerificationStatus.failed:
        bg = AppColors.errorBg;
        fg = AppColors.error;
        icon = Icons.error_outline;
        if (text.isEmpty) text = 'Review Required';
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: fg.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

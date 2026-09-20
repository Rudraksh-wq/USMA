import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../domain/digilocker_client.dart';
import '../domain/digilocker_consent.dart';

final digilockerClientProvider = Provider<DigiLockerClient>((ref) {
  return const MockDigiLockerClient();
});

class DigiLockerConsentScreen extends ConsumerStatefulWidget {
  final String userId;
  final VoidCallback onConsentGranted;

  const DigiLockerConsentScreen({
    super.key,
    required this.userId,
    required this.onConsentGranted,
  });

  @override
  ConsumerState<DigiLockerConsentScreen> createState() =>
      _DigiLockerConsentScreenState();
}

class _DigiLockerConsentScreenState
    extends ConsumerState<DigiLockerConsentScreen> {
  bool _agreedToTerms = false;
  bool _isProcessing = false;

  Future<void> _handleConsent() async {
    if (!_agreedToTerms) return;

    setState(() => _isProcessing = true);

    try {
      final client = ref.read(digilockerClientProvider);
      final verifier = PkceHelper.generateVerifier();
      final challenge = PkceHelper.computeChallenge(verifier);
      final state = PkceHelper.generateState();

      // Build OAuth PKCE authorization
      client.buildAuthUrl(
        clientId: 'USMA_MOTA_PORTAL',
        redirectUri: 'usma://oauth/digilocker/callback',
        codeChallenge: challenge,
        codeChallengeMethod: 'S256',
        state: state,
      );

      // In mock/demo mode, complete the handshake directly
      await client.exchangeCode(
        code: 'demo_auth_code',
        codeVerifier: verifier,
        redirectUri: 'usma://oauth/digilocker/callback',
        clientId: 'USMA_MOTA_PORTAL',
      );

      if (mounted) {
        widget.onConsentGranted();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('DigiLocker linked successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to link DigiLocker: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DigiLocker Data Consent'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Consent for Document Access',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Under DPDP Act 2023 and DigiLocker Integration Guidelines:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              elevation: 0,
              color: AppColors.surfaceVariant,
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text(
                  DigiLockerConsent.scholarshipPurpose,
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Data items to be fetched:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.xs),
            _buildScopeItem(Icons.badge, 'Caste Certificate (ST Category)'),
            _buildScopeItem(Icons.attach_money, 'Income Certificate (Revenue Dept)'),
            _buildScopeItem(Icons.school, 'Academic Marksheet / Degree (CBSE / State Board / University)'),
            _buildScopeItem(Icons.fingerprint, 'Aadhaar Verification (UIDAI Masked)'),
            const SizedBox(height: AppSpacing.lg),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _agreedToTerms,
              onChanged: _isProcessing
                  ? null
                  : (v) => setState(() => _agreedToTerms = v ?? false),
              title: const Text(
                'I give voluntary consent to USMA and Ministry of Tribal Affairs to access my documents via DigiLocker for scholarship processing only.',
                style: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _agreedToTerms && !_isProcessing ? _handleConsent : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Authorize with DigiLocker'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// USMA — Integration Status Screen
// integration_status_screen.dart
//
// DEMO MODE BANNER is always visible when isSimulated = true.
// Never present mock verification as real government verification.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/unified_verification_orchestrator.dart';
import '../domain/integration_provider.dart' show GovernmentSystem, GovernmentSystemLabel;


class IntegrationStatusScreen extends ConsumerWidget {
  const IntegrationStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(integrationStatusListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Integration Status',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          _DemoBadge(),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          _DemoBanner(),
          Expanded(
            child: statusAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF4F86F7)),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: Colors.redAccent)),
              ),
              data: (list) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SectionHeader('PROPOSED INTEGRATION ARCHITECTURE'),
                  const SizedBox(height: 4),
                  _ArchNote(),
                  const SizedBox(height: 20),
                  _SectionHeader('SYSTEM CONNECTIVITY'),
                  const SizedBox(height: 8),
                  ...list.map((s) => _SystemTile(status: s)),
                  const SizedBox(height: 24),
                  _MismatchPolicyCard(),
                  const SizedBox(height: 16),
                  _FailurePolicyCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Demo banner ────────────────────────────────────────────
class _DemoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF7C3AED),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: const [
          Icon(Icons.science_outlined, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'DEMO DATA — MOCK GOVERNMENT SERVICES\n'
              'No real connection to UIDAI, DigiLocker, UDISE+, APAAR, AISHE, NSP, PFMS, UGC or NTA.',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7C3AED)),
      ),
      child: const Text(
        'DEMO MODE',
        style: TextStyle(
            color: Color(0xFFA78BFA),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5),
      ),
    );
  }
}

// ─── Section header ─────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: Color(0xFF8B949E),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      );
}

// ─── Architecture note ───────────────────────────────────────
class _ArchNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: const Text(
        'Mapping below is a PROPOSED architecture and not an official '
        'government API contract. Each mapping shows which system would '
        'verify which data in a future production integration.',
        style: TextStyle(color: Color(0xFF8B949E), fontSize: 12, height: 1.5),
      ),
    );
  }
}

// ─── System tile ─────────────────────────────────────────────
class _SystemTile extends StatelessWidget {
  final IntegrationSystemStatus status;
  const _SystemTile({required this.status});

  @override
  Widget build(BuildContext context) {
    final isConnected = status.isConnected;
    final dot = isConnected ? '🟢' : '🟡';
    final color = isConnected
        ? const Color(0xFF3FB950)
        : const Color(0xFFD29922);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        children: [
          Text(dot, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.system.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _descriptionFor(status.system),
                  style: const TextStyle(
                      color: Color(0xFF8B949E), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text(
              status.statusLabel,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _descriptionFor(GovernmentSystem system) {
    switch (system) {
      case GovernmentSystem.digiLocker:
        return 'Identity, Aadhaar, academic certificates';
      case GovernmentSystem.udisePlus:
        return 'School enrolment, UDISE code, grade';
      case GovernmentSystem.apaar:
        return 'APAAR ID, Academic Bank of Credits';
      case GovernmentSystem.aishe:
        return 'College AISHE code, course affiliation';
      case GovernmentSystem.nsp:
        return 'Scholarship application status';
      case GovernmentSystem.pfms:
        return 'DBT payment, bank account seeding';
      case GovernmentSystem.stateEDistrict:
        return 'ST certificate, income, domicile';
      case GovernmentSystem.ugc:
        return 'UGC-approved institution, NET/JRF';
      case GovernmentSystem.nta:
        return 'NTA exam score, rank verification';
    }
  }
}

// ─── Policy cards ────────────────────────────────────────────
class _MismatchPolicyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _PolicyCard(
      icon: Icons.warning_amber_rounded,
      color: const Color(0xFFD29922),
      title: 'Mismatch Policy',
      body: 'When two sources disagree (e.g. "Rahul Kumar" vs "Rahul K."), '
          'the application is NEVER automatically rejected.\n\n'
          'The discrepancy is flagged as Manual Review and routed to the '
          'District Nodal Officer for human verification.',
    );
  }
}

class _FailurePolicyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _PolicyCard(
      icon: Icons.refresh_rounded,
      color: const Color(0xFF4F86F7),
      title: 'Source Unavailable Policy',
      body: 'If a government source times out or is unreachable:\n'
          '1. Retry up to 2 times with 800 ms back-off.\n'
          '2. If still unavailable → status = Source Unavailable.\n'
          '3. Application is NOT rejected — routed to Manual Review.',
    );
  }
}

class _PolicyCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _PolicyCard(
      {required this.icon,
      required this.color,
      required this.title,
      required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ]),
          const SizedBox(height: 10),
          Text(body,
              style: const TextStyle(
                  color: Color(0xFFCDD9E5), fontSize: 12, height: 1.6)),
        ],
      ),
    );
  }
}

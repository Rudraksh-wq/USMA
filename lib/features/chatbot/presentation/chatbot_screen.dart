// ============================================================
// USMA — JAGO Scholarship Assistance System
// chatbot_screen.dart
//
// Context-Aware UI displaying:
// - Structured Answer / Reason / Status / Required Action / Source
// - Actionable Quick Buttons ([View Application], [Check Documents], etc.)
// - Draft Grievance Card with explicit submit safety guard
// - Voice-Ready Mock Dictation bar
// - Language Switcher (English, हिन्दी, ਓଡିଆ)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/tokens.dart';
import '../data/chatbot_service.dart';
import '../domain/jago_intent_and_context.dart';
import '../domain/jago_localization.dart';
import '../domain/models/chat_message_model.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  String _selectedLanguage = JagoLocalization.langEnglish;
  bool _isListeningVoice = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? presetText]) {
    final text = presetText ?? _inputController.text.trim();
    if (text.isEmpty) return;

    if (presetText == null) _inputController.clear();

    ref.read(chatMessagesProvider.notifier).sendMessage(text);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _simulateVoiceInput() {
    setState(() => _isListeningVoice = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        content: Row(
          children: [
            const Icon(Icons.mic_rounded, color: AppColors.surface),
            const SizedBox(width: AppSpacing.sm),
            Text(
              _selectedLanguage == JagoLocalization.langHindi
                  ? 'आवाज़ रिकॉर्डिंग सक्रिय... (डेमो)'
                  : 'Voice Dictation Active... (Speech-to-Text Demo)',
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isListeningVoice = false);
        _sendMessage('Why haven\'t I received my scholarship?');
      }
    });
  }

  void _handleAction(JagoAction action) async {
    if (action.isExternal) {
      final uri = Uri.parse(action.route);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      context.push(action.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    JagoLocalization.get('app_title', lang: _selectedLanguage),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  Text(
                    JagoLocalization.get('subtitle', lang: _selectedLanguage),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Language selector
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              icon: const Icon(Icons.language_rounded, size: 20, color: AppColors.primary),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'hi', child: Text('हिन्दी', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'or', child: Text('ଓଡ଼ିଆ', style: TextStyle(fontSize: 12))),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedLanguage = val);
              },
            ),
          ),
          IconButton(
            tooltip: 'Restart Conversation',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(chatMessagesProvider.notifier).clearChat();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Disclaimer Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    JagoLocalization.get('disclaimer', lang: _selectedLanguage),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // Quick Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
            color: AppColors.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _QuickChip(
                    label: JagoLocalization.get('check_eligibility', lang: _selectedLanguage),
                    icon: Icons.fact_check_outlined,
                    onTap: () => _sendMessage('Am I eligible for Post-Matric?'),
                  ),
                  _QuickChip(
                    label: JagoLocalization.get('track_application', lang: _selectedLanguage),
                    icon: Icons.track_changes_outlined,
                    onTap: () => _sendMessage('Why is my application pending?'),
                  ),
                  _QuickChip(
                    label: JagoLocalization.get('check_documents', lang: _selectedLanguage),
                    icon: Icons.description_outlined,
                    onTap: () => _sendMessage('What documents are missing?'),
                  ),
                  _QuickChip(
                    label: JagoLocalization.get('track_payment', lang: _selectedLanguage),
                    icon: Icons.currency_rupee_rounded,
                    onTap: () => _sendMessage('When was my last payment?'),
                  ),
                  _QuickChip(
                    label: JagoLocalization.get('view_schemes', lang: _selectedLanguage),
                    icon: Icons.account_balance_outlined,
                    onTap: () => _sendMessage('Which official scholarship schemes are covered under MoTA?'),
                  ),
                  _QuickChip(
                    label: JagoLocalization.get('raise_grievance', lang: _selectedLanguage),
                    icon: Icons.report_problem_outlined,
                    onTap: () => _sendMessage('How do I raise a grievance?'),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Chat message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: messages.length,
              itemBuilder: (context, idx) {
                final msg = messages[idx];
                final isUser = msg.sender == MessageSender.user;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isUser) ...[
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(Icons.smart_toy_outlined, size: 16, color: AppColors.primary),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                              decoration: BoxDecoration(
                                color: isUser ? AppColors.primary : AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                  color: isUser ? AppColors.primary : AppColors.border,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.text,
                                    style: TextStyle(
                                      color: isUser ? AppColors.surface : AppColors.textPrimary,
                                      fontSize: 13.5,
                                      height: 1.45,
                                    ),
                                  ),

                                  // Grievance Draft Card if applicable
                                  if (!isUser && msg.structuredResponse?.isGrievanceDraft == true) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    _GrievanceDraftCard(
                                      draft: msg.structuredResponse!.grievanceDraft!,
                                      lang: _selectedLanguage,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Actionable Response Buttons
                      if (!isUser && msg.actions != null && msg.actions!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 36.0),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: msg.actions!.map((act) {
                              return OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: const Size(0, 32),
                                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                icon: Icon(
                                  act.isExternal ? Icons.open_in_new_rounded : Icons.arrow_forward_rounded,
                                  size: 14,
                                ),
                                label: Text(act.label),
                                onPressed: () => _handleAction(act),
                              );
                            }).toList(),
                          ),
                        ),
                      ],

                      // Suggestion Chips
                      if (!isUser && msg.suggestions != null && msg.suggestions!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 36.0),
                          child: Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: 4,
                            children: msg.suggestions!
                                .map(
                                  (sug) => ActionChip(
                                    backgroundColor: AppColors.surfaceVariant,
                                    side: const BorderSide(color: AppColors.border),
                                    label: Text(sug, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                                    onPressed: () => _sendMessage(sug),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // Input Bar with Voice Support
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: JagoLocalization.get('voice_hint', lang: _selectedLanguage),
                  icon: Icon(
                    _isListeningVoice ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: _isListeningVoice ? AppColors.error : AppColors.primary,
                  ),
                  onPressed: _simulateVoiceInput,
                ),
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      hintText: JagoLocalization.get('input_hint', lang: _selectedLanguage),
                      hintStyle: const TextStyle(fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                  ),
                  onPressed: () => _sendMessage(),
                  icon: const Icon(Icons.send_rounded, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.0),
      child: ActionChip(
        avatar: Icon(icon, size: 14, color: AppColors.primary),
        backgroundColor: AppColors.surfaceVariant,
        side: const BorderSide(color: AppColors.border),
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        onPressed: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}

class _GrievanceDraftCard extends StatelessWidget {
  final Map<String, dynamic> draft;
  final String lang;

  const _GrievanceDraftCard({
    required this.draft,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_outlined, size: 16, color: AppColors.warning),
              const SizedBox(width: 6),
              Text(
                JagoLocalization.get('draft_summary', lang: lang),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.warning),
              ),
            ],
          ),
          const Divider(height: 12),
          _GrievanceRow(label: JagoLocalization.get('category', lang: lang), value: draft['category'] ?? ''),
          _GrievanceRow(label: JagoLocalization.get('scheme', lang: lang), value: draft['scheme'] ?? ''),
          _GrievanceRow(label: 'App ID', value: draft['applicationId'] ?? ''),
          _GrievanceRow(label: JagoLocalization.get('description', lang: lang), value: draft['description'] ?? ''),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              JagoLocalization.get('submit_disabled', lang: lang),
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrievanceRow extends StatelessWidget {
  final String label;
  final String value;

  const _GrievanceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text('$label:', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

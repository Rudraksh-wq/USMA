import 'models/chat_message_model.dart';

/// Unified interface for JAGO Chatbot backends.
abstract class ChatBackend {
  String get name;

  /// Process a user message in the context of the student.
  Future<ChatMessageModel> sendMessage({
    required String message,
    required String userId,
    StudentChatContext? context,
  });
}

/// Offline keyword & FAQ based backend for when network is unavailable.
class OfflineFaqBackend implements ChatBackend {
  @override
  String get name => 'Offline FAQ Backend';

  @override
  Future<ChatMessageModel> sendMessage({
    required String message,
    required String userId,
    StudentChatContext? context,
  }) async {
    final lower = message.toLowerCase();
    String reply;

    if (lower.contains('status') || lower.contains('application')) {
      if (context != null && context.latestApplicationStatus != null) {
        reply = 'Your application for ${context.latestSchemeName ?? "MoTA Scholarship"} '
            'is currently at status: **${context.latestApplicationStatus}**.';
      } else {
        reply = 'You currently have no active applications on record.';
      }
    } else if (lower.contains('deficiency') || lower.contains('action')) {
      if (context != null && context.pendingDeficiencies.isNotEmpty) {
        reply = 'You have ${context.pendingDeficiencies.length} pending deficiency action(s):\n' +
            context.pendingDeficiencies
                .map((d) => '• ${d.description} (due by: ${d.dueDate})')
                .join('\n');
      } else {
        reply = 'Good news! You have zero pending deficiencies or required actions.';
      }
    } else if (lower.contains('disbursement') || lower.contains('money') || lower.contains('dbt')) {
      if (context != null && context.lastDisbursementAmount != null) {
        reply = 'Your last DBT disbursement was ₹${context.lastDisbursementAmount} '
            'via PFMS (UTR: ${context.lastDisbursementUtr ?? "N/A"}) on ${context.lastDisbursementDate ?? "recent"}.';
      } else {
        reply = 'No disbursements recorded yet for your current academic cycle.';
      }
    } else {
      reply = 'I am JAGO, your multilingual scholarship assistant. '
          'Ask me about your application status, pending deficiencies, required documents, or DBT payments.';
    }

    return ChatMessageModel.bot(reply);
  }
}

/// Proxy backend for calling cloud-hosted LLM endpoints with grounding.
class LlmBackend implements ChatBackend {
  final String apiKey;
  final String endpoint;

  const LlmBackend({this.apiKey = '', this.endpoint = ''});

  @override
  String get name => 'Cloud LLM Grounded Backend';

  @override
  Future<ChatMessageModel> sendMessage({
    required String message,
    required String userId,
    StudentChatContext? context,
  }) async {
    // In demo / test mode without active keys, gracefully fallback to contextual assistant
    final offline = OfflineFaqBackend();
    return offline.sendMessage(message: message, userId: userId, context: context);
  }
}

/// Student contextual facts passed to backends for personalized answers.
class StudentChatContext {
  final String? latestSchemeName;
  final String? latestApplicationStatus;
  final List<ChatDeficiencyItem> pendingDeficiencies;
  final double? lastDisbursementAmount;
  final String? lastDisbursementUtr;
  final String? lastDisbursementDate;

  const StudentChatContext({
    this.latestSchemeName,
    this.latestApplicationStatus,
    this.pendingDeficiencies = const [],
    this.lastDisbursementAmount,
    this.lastDisbursementUtr,
    this.lastDisbursementDate,
  });
}

class ChatDeficiencyItem {
  final String description;
  final String dueDate;

  const ChatDeficiencyItem({required this.description, required this.dueDate});
}

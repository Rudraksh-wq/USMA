import 'package:flutter_test/flutter_test.dart';
import 'package:usma/features/chatbot/domain/chat_backend.dart';
import 'package:usma/features/chatbot/domain/models/chat_message_model.dart';

void main() {
  group('JAGO ChatBackend Tests', () {
    test('OfflineFaqBackend responds with context when application status requested', () async {
      final backend = OfflineFaqBackend();
      const context = StudentChatContext(
        latestSchemeName: 'Pre-Matric ST Scholarship',
        latestApplicationStatus: 'InstituteVerified',
      );

      final resp = await backend.sendMessage(
        message: 'What is my application status?',
        userId: 'student_123',
        context: context,
      );

      expect(resp.sender, MessageSender.bot);
      expect(resp.text, contains('Pre-Matric ST Scholarship'));
      expect(resp.text, contains('InstituteVerified'));
    });

    test('OfflineFaqBackend reports pending deficiencies correctly', () async {
      final backend = OfflineFaqBackend();
      const context = StudentChatContext(
        pendingDeficiencies: [
          ChatDeficiencyItem(description: 'Upload valid Caste Certificate', dueDate: '30-Oct-2026'),
        ],
      );

      final resp = await backend.sendMessage(
        message: 'Do I have any deficiency or action needed?',
        userId: 'student_123',
        context: context,
      );

      expect(resp.sender, MessageSender.bot);
      expect(resp.text, contains('Upload valid Caste Certificate'));
      expect(resp.text, contains('30-Oct-2026'));
    });

    test('OfflineFaqBackend reports disbursements correctly', () async {
      final backend = OfflineFaqBackend();
      const context = StudentChatContext(
        lastDisbursementAmount: 18000,
        lastDisbursementUtr: 'PFMS20260900123',
        lastDisbursementDate: '15-Aug-2026',
      );

      final resp = await backend.sendMessage(
        message: 'When will I get my money or scholarship dbt?',
        userId: 'student_123',
        context: context,
      );

      expect(resp.sender, MessageSender.bot);
      expect(resp.text, contains('18000'));
      expect(resp.text, contains('PFMS20260900123'));
    });
  });
}

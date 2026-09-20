import { VerificationRequest, VerificationResult } from './types';

export interface AuditLogEntry {
  auditId: string;
  timestamp: string;
  requestId: string;
  applicationId: string;
  userIdHash: string; // Pseudonymised or non-reversible identifier
  sourceSystem: string;
  documentOrFieldType: string;
  verificationStatus: string;
  confidence: number;
  hasMismatches: boolean;
  mismatchFieldNames: string[]; // Field names ONLY, no actual PII values
  requiresManualReview: boolean;
}

export class VerificationAuditLogger {
  private static inMemoryAuditLogs: AuditLogEntry[] = [];

  public static async logVerification(
    request: VerificationRequest,
    result: VerificationResult
  ): Promise<AuditLogEntry> {
    const entry: AuditLogEntry = {
      auditId: `audit_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      timestamp: new Date().toISOString(),
      requestId: request.requestId,
      applicationId: request.applicationId,
      userIdHash: `user_hash_${request.userId.substring(0, 4)}`,
      sourceSystem: result.source,
      documentOrFieldType: request.documentOrFieldType,
      verificationStatus: result.status,
      confidence: result.confidence,
      hasMismatches: result.diffs.length > 0,
      mismatchFieldNames: result.diffs.map((d) => d.fieldName), // No values, only names!
      requiresManualReview: result.requiresManualReview,
    };

    this.inMemoryAuditLogs.push(entry);
    return entry;
  }

  public static getEntries(): AuditLogEntry[] {
    return [...this.inMemoryAuditLogs];
  }

  public static clear(): void {
    this.inMemoryAuditLogs = [];
  }
}

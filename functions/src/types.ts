export type VerificationStatus = 'verified' | 'mismatch' | 'unavailable' | 'pendingManual';

export interface FieldDiff {
  fieldName: string;
  declaredValue: string;
  sourceValue: string;
  reason: string;
}

export interface VerificationRequest {
  requestId: string;
  applicationId: string;
  userId: string;
  sourceType: string;
  documentOrFieldType: string;
  payload: Record<string, any>;
  state?: string;
  institutionId?: string;
  persona?: 'all-verified' | 'name-mismatch' | 'income-mismatch' | 'source-timeout';
}

export interface VerificationResult {
  status: VerificationStatus;
  source: string;
  timestamp: string;
  confidence: number;
  diffs: FieldDiff[];
  requiresManualReview: boolean;
  message?: string;
  isSimulated: boolean;
}

export interface VerificationSource {
  readonly sourceName: string;
  readonly supportedTypes: string[];
  verify(request: VerificationRequest): Promise<VerificationResult>;
}

export interface CircuitBreakerOptions {
  failureThreshold: number; // e.g. 3 consecutive failures
  resetTimeoutMs: number; // e.g. 30,000 ms before trial
  requestTimeoutMs: number; // e.g. 5,000 ms timeout per call
}

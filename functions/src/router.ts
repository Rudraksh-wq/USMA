import {
  AisheAdapter,
  ApaarAdapter,
  DigiLockerAdapter,
  SchemeStatusAdapter,
  StateEDistrictAdapter,
  UgcNtaAdapter,
  UdiseAdapter,
  UidaiAdapter,
} from './adapters/all_adapters';
import { VerificationAuditLogger } from './audit_log';
import { CircuitBreaker } from './circuit_breaker';
import { VerificationRequest, VerificationResult, VerificationSource } from './types';

export class UnifiedVerificationRouter {
  private sources: Map<string, VerificationSource> = new Map();
  private circuitBreakers: Map<string, CircuitBreaker> = new Map();

  constructor() {
    this.registerDefaultSources();
  }

  /**
   * Registers a verification source adapter.
   * Adding a new source requires only creating an adapter class and calling registerSource!
   */
  public registerSource(source: VerificationSource): void {
    this.sources.set(source.sourceName, source);
    this.circuitBreakers.set(
      source.sourceName,
      new CircuitBreaker(source.sourceName)
    );
  }

  private registerDefaultSources(): void {
    this.registerSource(new DigiLockerAdapter());
    this.registerSource(new UidaiAdapter());
    this.registerSource(new AisheAdapter());
    this.registerSource(new UdiseAdapter());
    this.registerSource(new ApaarAdapter());
    this.registerSource(new StateEDistrictAdapter());
    this.registerSource(new UgcNtaAdapter());
    this.registerSource(new SchemeStatusAdapter());
  }

  /**
   * Routes a request to the appropriate verification source based on document/field type
   */
  public resolveSource(documentOrFieldType: string): VerificationSource {
    const typeUpper = documentOrFieldType.toUpperCase();

    for (const source of this.sources.values()) {
      if (
        source.supportedTypes.some(
          (t) => t.toUpperCase() === typeUpper || typeUpper.contains?.(t)
        )
      ) {
        return source;
      }
    }

    // Default fallback to DigiLocker for document verifications
    return (
      this.sources.get('DigiLocker (API Setu / MeitY)') ||
      this.sources.values().next().value
    );
  }

  /**
   * Executes verification through the router, protected by the per-source circuit breaker,
   * and logged to the append-only PII-free audit log.
   */
  public async executeVerification(
    request: VerificationRequest
  ): Promise<VerificationResult> {
    const source = this.resolveSource(request.documentOrFieldType);
    const breaker =
      this.circuitBreakers.get(source.sourceName) ||
      new CircuitBreaker(source.sourceName);

    const result = await breaker.execute(source, request);

    // Append to PII-free audit log
    await VerificationAuditLogger.logVerification(request, result);

    return result;
  }

  public getRegisteredSourcesCount(): number {
    return this.sources.size;
  }

  public getCircuitBreaker(sourceName: string): CircuitBreaker | undefined {
    return this.circuitBreakers.get(sourceName);
  }
}

import { CircuitBreakerOptions, VerificationRequest, VerificationResult, VerificationSource } from './types';

enum CircuitState {
  CLOSED,
  OPEN,
  HALF_OPEN,
}

export class CircuitBreaker {
  private state: CircuitState = CircuitState.CLOSED;
  private failureCount: number = 0;
  private nextAttempt: number = Date.now();

  constructor(
    public readonly sourceName: string,
    private readonly options: CircuitBreakerOptions = {
      failureThreshold: 3,
      resetTimeoutMs: 30000,
      requestTimeoutMs: 5000,
    }
  ) {}

  public getState(): 'CLOSED' | 'OPEN' | 'HALF_OPEN' {
    return CircuitState[this.state] as 'CLOSED' | 'OPEN' | 'HALF_OPEN';
  }

  public async execute(
    source: VerificationSource,
    request: VerificationRequest
  ): Promise<VerificationResult> {
    const now = Date.now();

    // If Open, check if reset timeout elapsed to transition to Half-Open
    if (this.state === CircuitState.OPEN) {
      if (now > this.nextAttempt) {
        this.state = CircuitState.HALF_OPEN;
      } else {
        return {
          status: 'unavailable',
          source: source.sourceName,
          timestamp: new Date().toISOString(),
          confidence: 0.0,
          diffs: [],
          requiresManualReview: true,
          message: `Circuit breaker OPEN for ${source.sourceName}. Source is temporarily unavailable; routed to manual review.`,
          isSimulated: true,
        };
      }
    }

    // Attempt execution with timeout & retry
    try {
      const result = await this.executeWithTimeoutAndRetry(source, request);
      this.onSuccess();
      return result;
    } catch (err: any) {
      this.onFailure();
      return {
        status: 'unavailable',
        source: source.sourceName,
        timestamp: new Date().toISOString(),
        confidence: 0.0,
        diffs: [],
        requiresManualReview: true,
        message: `Execution failed for ${source.sourceName}: ${err.message}. Routed to manual review queue.`,
        isSimulated: true,
      };
    }
  }

  private async executeWithTimeoutAndRetry(
    source: VerificationSource,
    request: VerificationRequest,
    retries: number = 1
  ): Promise<VerificationResult> {
    let lastError: any;
    for (let attempt = 0; attempt <= retries; attempt++) {
      try {
        return await Promise.race([
          source.verify(request),
          new Promise<VerificationResult>((_, reject) =>
            setTimeout(
              () => reject(new Error(`Timeout after ${this.options.requestTimeoutMs}ms`)),
              this.options.requestTimeoutMs
            )
          ),
        ]);
      } catch (e) {
        lastError = e;
        if (attempt < retries) {
          // Exponential backoff
          await new Promise((res) => setTimeout(res, 200 * Math.pow(2, attempt)));
        }
      }
    }
    throw lastError;
  }

  private onSuccess(): void {
    this.failureCount = 0;
    this.state = CircuitState.CLOSED;
  }

  private onFailure(): void {
    this.failureCount++;
    if (this.failureCount >= this.options.failureThreshold) {
      this.state = CircuitState.OPEN;
      this.nextAttempt = Date.now() + this.options.resetTimeoutMs;
    }
  }
}

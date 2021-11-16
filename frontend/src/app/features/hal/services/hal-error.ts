import { HttpErrorResponse } from '@angular/common/http';
import { ErrorResource } from 'core-app/features/hal/resources/error-resource';

export class HalError extends Error {
  readonly name = 'HALError';

  get message():string {
    return this.resource?.message || this.httpError?.message || 'Unknown error';
  }

  get errorIdentifier():string {
    return this.resource?.errorIdentifier || 'unknown';
  }

  constructor(
    readonly httpError:HttpErrorResponse,
    readonly resource:ErrorResource|null,
  ) {
    super();
    Object.setPrototypeOf(this, HalError.prototype);
  }
}

import { HttpErrorResponse } from '@angular/common/http';
import { ErrorResource } from 'core-app/features/hal/resources/error-resource';

export class HalError implements Error {
  readonly name = 'HALError';

  get message():string {
    return this.resource.message || this.httpError?.message || 'Unknown error';
  }

  get errorIdentifier():string {
    return this.resource.errorIdentifier;
  }

  constructor(
    readonly httpError:HttpErrorResponse,
    readonly resource:ErrorResource,
  ) {
  }
}

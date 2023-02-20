import {
  ErrorHandler,
  Injectable,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { ErrorResource } from 'core-app/features/hal/resources/error-resource';
import { HalError } from 'core-app/features/hal/services/hal-error';
import { HttpErrorResponse } from '@angular/common/http';

interface RejectedPromise {
  rejection:unknown;
}

@Injectable()
export class HalAwareErrorHandler extends ErrorHandler {
  private text = {
    internal_error: this.I18n.t('js.error.internal'),
  };

  constructor(private readonly I18n:I18nService) {
    super();
  }

  public handleError(error:unknown):void {
    let message:string = this.text.internal_error;

    // Angular wraps our errors into uncaught promises if
    // no one catches the error explicitly. Unwrap the error in that case
    if ((error as RejectedPromise)?.rejection instanceof HalError) {
      this.handleError((error as RejectedPromise).rejection);
      return;
    }

    if (error instanceof HalError) {
      console.error('Returned HTTP HAL error resource %O', error.message);
      message = error.httpError?.status >= 500 ? `${message} ${error.message}` : error.message;
      HalAwareErrorHandler.captureError(error.httpError);
    } else if (error instanceof ErrorResource) {
      console.error('Returned error resource %O', error);
      message += ` ${error.errorMessages.join('\n')}`;
    } else if (error instanceof HalResource) {
      console.error('Returned hal resource %O', error);
      message += `Resource returned ${error.name}`;
    } else if (error instanceof Error) {
      window.ErrorReporter.captureException(error);
    } else if (error instanceof HttpErrorResponse) {
      HalAwareErrorHandler.captureError(error);
      message = error.message;
    } else if (typeof error === 'string') {
      window.ErrorReporter.captureMessage(error);
      message = error;
    }

    super.handleError(message);
  }

  /**
   * Report any errors to APM tool, if configured.
   *
   * The Application Performance Monitoring tool will filter according to their
   * error status.
   *
   * @param error
   * @private
   */
  private static captureError(error:Error|HttpErrorResponse):void {
    window.ErrorReporter.captureException(error);
  }
}

import { ErrorReporterBase } from 'core-app/core/errors/error-reporter-base';
import { AppsignalReporter } from 'core-app/core/errors/appsignal/appsignal-reporter';
import { LocalReporter } from 'core-app/core/errors/local/local-reporter';

export function configureErrorReporter():ErrorReporterBase {
  const appsignalElement = document.querySelector('meta[name=openproject_appsignal]') as HTMLElement;
  if (appsignalElement !== null) {
    return new AppsignalReporter();
  }

  return new LocalReporter();
}

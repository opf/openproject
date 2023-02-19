import { ErrorReporterBase } from 'core-app/core/errors/error-reporter-base';
import { SentryReporter } from 'core-app/core/errors/sentry/sentry-reporter';
import { AppsignalReporter } from 'core-app/core/errors/appsignal/appsignal-reporter';
import { LocalReporter } from 'core-app/core/errors/local/local-reporter';

export function configureErrorReporter():ErrorReporterBase {
  const sentryElement = document.querySelector('meta[name=openproject_sentry]') as HTMLElement;
  if (sentryElement !== null) {
    return new SentryReporter();
  }

  const appsignalElement = document.querySelector('meta[name=openproject_appsignal]') as HTMLElement;
  if (appsignalElement !== null) {
    return new AppsignalReporter();
  }

  return new LocalReporter();
}

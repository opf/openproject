import { ErrorReporterBase } from 'core-app/core/errors/error-reporter-base';
import { AppsignalReporter } from 'core-app/core/errors/appsignal/appsignal-reporter';
import { LocalReporter } from 'core-app/core/errors/local/local-reporter';
import { getMetaElement } from '../setup/globals/global-helpers';

export function configureErrorReporter():ErrorReporterBase {
  const appsignalElement = getMetaElement('openproject_appsignal');
  if (appsignalElement !== null) {
    return new AppsignalReporter();
  }

  return new LocalReporter();
}

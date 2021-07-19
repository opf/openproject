import { OpenProjectModule } from 'core-app/app.module';
import { enableProdMode } from '@angular/core';
import * as jQuery from 'jquery';
import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';
import { SentryReporter } from 'core-app/core/errors/sentry/sentry-reporter';
import { whenDebugging } from 'core-app/shared/helpers/debug_output';
import { enableReactiveStatesLogging } from 'reactivestates';
import { initializeLocale } from 'core-app/core/setup/init-locale';
import { environment } from './environments/environment';

(window as any).global = window;

// Ensure we set the correct dynamic frontend path
// based on the RAILS_RELATIVE_URL_ROOT setting
// https://webpack.js.org/guides/public-path/
const ASSET_BASE_PATH = '/assets/frontend/';

// Sets the relative base path
window.appBasePath = jQuery('meta[name=app_base_path]').attr('content') || '';

// Ensure to set the asset base for dynamic code loading
// https://webpack.js.org/guides/public-path/
__webpack_public_path__ = window.appBasePath + ASSET_BASE_PATH;

window.ErrorReporter = new SentryReporter();

require('core-app/core/setup/init-vendors');
require('core-app/core/setup/init-globals');

if (environment.production) {
  enableProdMode();
}

// Enable debug logging for reactive states
whenDebugging(() => {
  (window as any).enableReactiveStatesLogging = () => enableReactiveStatesLogging(true);
  (window as any).disableReactiveStatesLogging = () => enableReactiveStatesLogging(false);
});

// Import the correct locale early on
void initializeLocale()
  .then(() => {
    jQuery(() => {
      // Due to the behaviour of the Edge browser we need to wait for 'DOM ready'
      void platformBrowserDynamic()
        .bootstrapModule(OpenProjectModule)
        .then(() => {
          jQuery('body').addClass('__ng2-bootstrap-has-run');
        });
    });
  });

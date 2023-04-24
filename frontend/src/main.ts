import { OpenProjectModule } from 'core-app/app.module';
import { enableProdMode } from '@angular/core';
import * as jQuery from 'jquery';
import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';
import { whenDebugging } from 'core-app/shared/helpers/debug_output';
import { initializeLocale } from 'core-app/core/setup/init-locale';
import { environment } from './environments/environment';
import { configureErrorReporter } from 'core-app/core/errors/configure-reporter';
import { initializeGlobalListeners } from 'core-app/core/setup/globals/global-listeners';

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

window.ErrorReporter = configureErrorReporter();

require('core-app/core/setup/init-vendors');
require('core-app/core/setup/init-globals');

if (environment.production) {
  enableProdMode();
}

// Import the correct locale early on
void initializeLocale()
  .then(() => {
    jQuery(() => {
      // Now that DOM is loaded, also run the global listeners
      initializeGlobalListeners();

      // Due to the behaviour of the Edge browser we need to wait for 'DOM ready'
      void platformBrowserDynamic()
        .bootstrapModule(OpenProjectModule)
        .then(() => {
          jQuery('body').addClass('__ng2-bootstrap-has-run');
        });
    });
  });

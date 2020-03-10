import {OpenProjectModule} from 'core-app/angular4-modules';
import {enableProdMode} from '@angular/core';
import * as jQuery from "jquery";
import {environment} from './environments/environment';
import {platformBrowserDynamic} from '@angular/platform-browser-dynamic';

(window as any).global = window;


/** Load sentry integration as soon as possible */
import {SentryReporter} from "core-app/sentry/sentry-reporter";
window.ErrorReporter = new SentryReporter();

require('core-app/init-vendors');
require('./app/init-globals');


if (environment.production) {
  enableProdMode();
}


jQuery(function () {
  // Due to the behaviour of the Edge browser we need to wait for 'DOM ready'
  platformBrowserDynamic()
    .bootstrapModule(OpenProjectModule)
    .then(platformRef => {
      jQuery('body').addClass('__ng2-bootstrap-has-run');
    });
});


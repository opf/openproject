import {enableProdMode} from '@angular/core';
import {platformBrowserDynamic} from '@angular/platform-browser-dynamic';
import * as jQuery from 'jquery';
import {environment} from '../environments/environment';
import {OpenProjectModule} from "core-app/angular4-modules";


if (environment.production) {
  enableProdMode();
}

declare const angular:any;

jQuery(function() {
  // Due to the behaviour of the Edge browser we need to wait for 'DOM ready'
  platformBrowserDynamic()
    .bootstrapModule(OpenProjectModule)
    .then(platformRef => {
      angular.element('body').addClass('__ng2-bootstrap-has-run');
    });
});



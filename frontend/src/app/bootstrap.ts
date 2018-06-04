import {enableProdMode} from '@angular/core';
import {platformBrowserDynamic} from '@angular/platform-browser-dynamic';
import * as jQuery from 'jquery';
import {AppModule} from './app.module';
import {environment} from '../environments/environment';


if (environment.production) {
  enableProdMode();
}

declare const angular:any;

jQuery(function() {
  // Due to the behaviour of the Edge browser we need to wait for 'DOM ready'
  platformBrowserDynamic()
    .bootstrapModule(AppModule)
    .then(platformRef => {
      angular.element('body').addClass('__ng2-bootstrap-has-run');
    });
});



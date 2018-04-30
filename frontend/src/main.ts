import {enableProdMode, NgModuleRef} from '@angular/core';
import {platformBrowserDynamic} from '@angular/platform-browser-dynamic';
import {AppModule} from './app/app.module';
import {environment} from './environments/environment';
import {UpgradeModule} from '@angular/upgrade/static';
import * as jQuery from 'jquery';
import {setAngularJSGlobal} from '@angular/upgrade/static';


import './app/ng1';

if (environment.production) {
  enableProdMode();
}

declare const angular: any;

export function bootstrapWithUiRouter(platformRef: NgModuleRef<any>): void {
  setAngularJSGlobal(angular);
  const injector = platformRef.injector;
  const upgradeModule = injector.get(UpgradeModule);
  upgradeModule.bootstrap(document.body, ['ng1mod'], {strictDi: true});
}

jQuery(function () {
  // Due to the behaviour of the Edge browser we need to wait for 'DOM ready'
  platformBrowserDynamic()
    .bootstrapModule(AppModule)
    .then(platformRef => bootstrapWithUiRouter(platformRef));
});


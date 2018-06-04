import {enableProdMode, NgModuleRef} from '@angular/core';
import {platformBrowserDynamic} from '@angular/platform-browser-dynamic';
import {setAngularJSGlobal, UpgradeModule} from '@angular/upgrade/static';
import * as jQuery from 'jquery';
import {AppModule} from './app.module';
import {environment} from '../environments/environment';


if (environment.production) {
  enableProdMode();
}

declare const angular:any;

export function bootstrapWithUiRouter(platformRef:NgModuleRef<any>):void {
  setAngularJSGlobal(angular);
  const injector = platformRef.injector;
  const upgradeModule = injector.get(UpgradeModule);
  upgradeModule.bootstrap(document.body, [openprojectModule.name], {strictDi: false});
  angular.element('body').addClass('__ng2-bootstrap-has-run');
}

jQuery(function() {
  // Due to the behaviour of the Edge browser we need to wait for 'DOM ready'
  platformBrowserDynamic()
    .bootstrapModule(AppModule)
    .then(platformRef => {
      return bootstrapWithUiRouter(platformRef);
    });
});



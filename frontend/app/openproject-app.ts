//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See docs/COPYRIGHT.rdoc for more details.
//++

require('./init-app');

// load Angular 4 modules
require("./angular4-modules");


import {NgModuleRef} from '@angular/core';
import {platformBrowser} from '@angular/platform-browser';
import {openprojectModule} from './angular-modules';
// import {OpenProjectModule} from './angular4-modules';
import {OpenProjectModule} from './angular4-modules';
import {UpgradeModule} from '@angular/upgrade/static';
import {getUIRouter} from '@uirouter/angular-hybrid';

openprojectModule
  .config([ '$urlServiceProvider', ($urlServiceProvider:any) => {
    // Defer the routing until the upgraded module is being bootstrapped
    $urlServiceProvider.deferIntercept();
  }])
  .run(['$$angularInjector', ($$angularInjector:any) => {
    // Synchronize the current URL now that we are being bootstrapped
    const url:any = getUIRouter($$angularInjector).urlService;
    url.listen();
    url.sync();
  }]);

export function bootstrapWithUiRouter(platformRef:NgModuleRef<any>): void {
  const injector = window.ng2Injector = platformRef.injector;
  const upgradeModule = injector.get(UpgradeModule);

  upgradeModule.bootstrap(document.body, [ openprojectModule.name ], { strictDi: false });
  angular.element('body').addClass('__ng2-bootstrap-has-run');
}

jQuery(function () {
  // Due to the behaviour of the Edge browser we need to wait for 'DOM ready'

  platformBrowser()
    .bootstrapModule(OpenProjectModule)
    .then(platformRef => bootstrapWithUiRouter(platformRef));
});

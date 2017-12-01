// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {InjectionToken} from '@angular/core';
import {IRootScopeService} from 'angular';

export const $rootScopeToken = new InjectionToken<IRootScopeService>('$rootScope');
export const I18nToken = new InjectionToken<op.I18n>('I18n');
export const columnsModalToken = new InjectionToken<any>('columnsModal');
export const focusHelperToken = new InjectionToken<any>('FocusHelper');
export const NotificationsServiceToken = new InjectionToken<any>('NotificationsService');

export function upgradeService(ng1InjectorName:string, providedType:any) {
  return {
    provide: providedType,
    useFactory: (i:any) => i.get(ng1InjectorName),
    deps: ['$injector']
  };
}

export function upgradeServiceWithToken(ng1InjectorName:string, token:InjectionToken<any>) {
  return {
    provide: token,
    useFactory: (i:any) => i.get(ng1InjectorName),
    deps: ['$injector']
  };
}

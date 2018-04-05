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

import {Inject, InjectionToken} from '@angular/core';
import {IQService, IRootScopeService, ITimeoutService} from 'angular';
import {StateService} from '@uirouter/core';

export const $rootScopeToken = new InjectionToken<IRootScopeService>('$rootScope');
export const $qToken = new InjectionToken<IQService>('$q');
export const $timeoutToken = new InjectionToken<ITimeoutService>('$timeout');
export const $localeToken = new InjectionToken<any>('$locale');
export const $stateToken = new InjectionToken<StateService>('$state');

export const I18nToken = new InjectionToken<op.I18n>('I18n');
export const columnsModalToken = new InjectionToken<any>('columnsModal');
export const sortingModalToken = new InjectionToken<any>('sortingModal');
export const groupingModalToken =  new InjectionToken<any>('groupingModal');
export const shareModalToken = new InjectionToken<any>('shareModal');
export const saveModalToken = new InjectionToken<any>('saveModal');
export const settingsModalToken = new InjectionToken<any>('settingsModal');
export const exportModalToken = new InjectionToken<any>(' exportModal');
export const timelinesModalToken = new InjectionToken<any>('timelinesModal');

export const FocusHelperToken = new InjectionToken<any>('FocusHelper');
export const NotificationsServiceToken = new InjectionToken<any>('NotificationsService');
export const v3PathToken = new InjectionToken<any>('v3Path');
export const PathHelperToken = new InjectionToken<any>('PathHelper');
export const halRequestToken = new InjectionToken<any>('halRequest');
export const wpMoreMenuServiceToken = new InjectionToken<any>('wpMoreMenuService');
export const TimezoneServiceToken = new InjectionToken<any>('TimezoneService');
export const $httpToken = new InjectionToken<any>('$http');
export const halResourceFactoryToken = new InjectionToken<any>('halResourceFactory');
export const wpDestroyModalToken = new InjectionToken<any>('wpDestroyModal');
export const OpContextMenuLocalsToken = new InjectionToken<any>('CONTEXT_MENU_LOCALS');
export const HookServiceToken = new InjectionToken<any>('HookService');
export const UrlParamsHelperToken = new InjectionToken<any>('UrlParamsHelper');
export const QueryResourceToken = new InjectionToken<any>('QueryResource');
export const QueryFilterInstanceResourceToken = new InjectionToken<any>('QueryFilterInstanceResource');
export const HalResourceToken = new InjectionToken<any>('HalResource');
export const UrlParamsHelperServiceToken = new InjectionToken<any>('UrlParamsHelperService');

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

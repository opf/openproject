//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable } from '@angular/core';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentUser, CurrentUserStore } from './current-user.store';
import { CurrentUserQuery } from './current-user.query';
import { CapabilitiesResourceService } from 'core-app/core/state/capabilities/capabilities.service';
import { Observable } from 'rxjs';
import { distinctUntilChanged, map, switchMap, take } from 'rxjs/operators';
import { ApiV3ListFilter } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { ICapability } from 'core-app/core/state/capabilities/capability.model';

@Injectable({ providedIn: 'root' })
export class CurrentUserService {
  constructor(
    private apiV3Service:ApiV3Service,
    private currentUserStore:CurrentUserStore,
    private currentUserQuery:CurrentUserQuery,
    private capabilitiesService:CapabilitiesResourceService,
  ) {
    this.setupLegacyDataListeners();
  }

  public isLoggedIn$ = this.currentUserQuery.isLoggedIn$;

  public user$ = this.currentUserQuery.user$;

  /**
   * Set the current user object
   *
   * This refetches the global and current project capabilities
   */
  public setUser(user:CurrentUser):void {
    this.currentUserStore.update((state) => ({
      ...state,
      ...user,
    }));
  }

  /**
   * Returns the set of capabilities for the given context and/or actions
   */
  public capabilities$(actions:string[] = [], projectContext:string|null):Observable<ICapability[]> {
    return this
      .principalFilter$()
      .pipe(
        map((userFilter) => {
          const filters:ApiV3ListFilter[] = _.compact([userFilter]);

          if (projectContext) {
            filters.push(['context', '=', [projectContext === 'global' || projectContext === 'projects' ? 'g' : `p${projectContext}`]]);
          }

          if (actions.length > 0) {
            filters.push(['action', '=', actions]);
          }

          return { filters, pageSize: -1 };
        }),
        switchMap((params) => this.capabilitiesService.requireCollection(params)),
      );
  }

  /**
   * Returns an Observable<boolean> indicating whether the current user has the required capabilities
   * in the provided context.
   */
  public hasCapabilities$(action:string|string[], projectContext:string|null):Observable<boolean> {
    const actions = _.castArray(action);
    return this
      .capabilities$(actions, projectContext)
      .pipe(
        map((capabilities) => actions.reduce(
          (acc, contextAction) => acc && !!capabilities.find((cap) => cap._links.action.href.endsWith(`/api/v3/actions/${contextAction}`)),
          capabilities.length > 0,
        )),
        distinctUntilChanged(),
      );
  }

  /**
   * Returns an Observable<boolean> indicating whether the current user
   * has any of the required capabilities in the provided context.
   */
  public hasAnyCapabilityOf$(actions:string|string[], projectContext:string|null):Observable<boolean> {
    const actionsToFilter = _.castArray(actions);
    return this
      .capabilities$(actionsToFilter, projectContext)
      .pipe(
        map((capabilities) => capabilities.reduce(
          (acc, cap) => acc || !!actionsToFilter.find((action) => cap._links.action.href.endsWith(`/api/v3/actions/${action}`)),
          false,
        )),
        distinctUntilChanged(),
      );
  }

  /**
   * Returns a principal filter for the current user.
   */
  private principalFilter$():Observable<ApiV3ListFilter|null> {
    return this
      .user$
      .pipe(
        take(1),
        map((user) => {
          if (user.id === null) {
            return null;
          }

          return ['principal', '=', [user.id]];
        }),
      );
  }

  // Everything below this is deprecated legacy interfacing and should not be used

  private setupLegacyDataListeners() {
    this.currentUserQuery.user$.subscribe((user) => (this._user = user));
    this.currentUserQuery.isLoggedIn$.subscribe((isLoggedIn) => (this._isLoggedIn = isLoggedIn));
  }

  private _isLoggedIn = false;

  /** @deprecated Use the store mechanism `currentUserQuery.isLoggedIn$` */
  public get isLoggedIn():boolean {
    return this._isLoggedIn;
  }

  private _user:CurrentUser = {
    id: null,
    name: null,
    loggedIn: false,
  };

  /** @deprecated Use the store mechanism `currentUserQuery.user$` */
  public get userId():string {
    return this._user.id || '';
  }

  /** @deprecated Use the store mechanism `currentUserQuery.user$` */
  public get name():string {
    return this._user.name || '';
  }

  /** @deprecated Use the store mechanism `currentUserQuery.user$` */
  public get href():string {
    return `/api/v3/users/${this.userId}`;
  }

  /** @deprecated Use `I18nService.locale` instead */
  public get language():string {
    return I18n.locale || 'en';
  }
}

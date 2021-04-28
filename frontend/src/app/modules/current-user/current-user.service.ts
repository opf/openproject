//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import { Injectable } from "@angular/core";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { take, map } from 'rxjs/operators';
import { CurrentUserStore, CurrentUser } from "./current-user.store";
import { CapabilityResource } from "core-app/modules/hal/resources/capability-resource";
import { CurrentUserQuery } from "./current-user.query";

@Injectable({ providedIn: 'root' })
export class CurrentUserService {
  constructor(
    private apiV3Service: APIV3Service,
    private currentUserStore: CurrentUserStore,
    private currentUserQuery: CurrentUserQuery,
  ) {
    this.setupLegacyDataListeners();
  }

  public capabilities$ = this.currentUserQuery.capabilities$;
  public isLoggedIn$ = this.currentUserQuery.isLoggedIn$;
  public user$ = this.currentUserQuery.user$;

  public setUser(user: CurrentUser) {
    this.currentUserStore.update(state => ({
      ...state,
      ...user,
    }));

    this.fetchCapabilities();
  }

  public fetchCapabilities(context:string = '') {
    this.user$.pipe(take(1)).subscribe((user) => {
      if (!user.id) {
        this.currentUserStore.update(state => ({
          ...state,
          capabilities: [],
        }));

        return;
      }

      const filters = [ ['principal', '=', [user.id]] ];
      if (context !== '') {
        const contextFilter = context === 'global' ? 'g' : `p${context}`;
        filters.push(['context', '=', context]);
      }

      this.apiV3Service.capabilities.list({
        pageSize: 1000,
        filters,
      }).subscribe((data) => {
        this.currentUserStore.update(state => ({
          ...state,
          capabilities: data.elements,
        }));
      });
    });

    return this.currentUserQuery.capabilities$;
  }

  /**
   * Returns the users' capabilities filtered by context
   */
  public capabilitiesForContext$(contextId: string) {
    this.apiV3Service.fetchCapabilities(contextId);
    return this.capabilities$.pipe(
      map((capabilities) => capabilities.filter(cap => cap.context.href.endsWith(`/${contextId}`))),
      distinctUntilChanged(),
    );
  }

  /**
   * Returns an Observable<boolean> indicating whether the user has the required capabilities in the provided context. 
   */
  public hasCapabilities$(action: string|string[], contextId: string = 'global') {
    const actions = _.castArray(action);
    return this.capabilitiesForContext$(contextId).pipe(
      map((capabilities) => capabilities.reduce(
        (acc, cap) => acc && !!actions.find(action => cap.actions.href.endsWith(`/${action}`)),
        true,
      )))
      distinctUntilChanged(),
    );
  }

  /**
   * Returns an Observable<boolean> indicating whether the user has any of the required capabilities in the provided context. 
   */
  public hasAnyCapabilityOf$(actions: string|string[], contextId: string = 'global') {
    const actions = _.castArray(actions);
    return this.capabilitiesForContext$(contextId).pipe(
      map((capabilities) => capabilities.reduce(
        (acc, cap) => acc || !!actions.find(action => cap.actions.href.endsWith(`/${action}`)),
        false,
      )))
      distinctUntilChanged(),
    );
  }

  // Everything below this is deprecated legacy interfacing and should not be used


  private setupLegacyDataListeners() {
    this.currentUserQuery.user$.subscribe(user => this._user = user);
    this.currentUserQuery.isLoggedIn$.subscribe(isLoggedIn => this._isLoggedIn = isLoggedIn);
  }

  private _isLoggedIn = false;
  /** @deprecated Use the store mechanism `currentUserQuery.isLoggedIn$` */
  public get isLoggedIn() {
    return this._isLoggedIn;
  }

  private _user: CurrentUser = {
    id: null,
    name: null,
    mail: null,
  };

  /** @deprecated Use the store mechanism `currentUserQuery.user$` */
  public get userId() {
    return this._user.id || '';
  }

  /** @deprecated Use the store mechanism `currentUserQuery.user$` */
  public get name() {
    return this._user.name || '';
  }

  /** @deprecated Use the store mechanism `currentUserQuery.user$` */
  public get mail() {
    return this._user.mail || '';
  }

  /** @deprecated Use the store mechanism `currentUserQuery.user$` */
  public get href() {
    return `/api/v3/users/${this.userId}`;
  }

  /** @deprecated Use `I18nService.locale` instead */
  public get language() {
    return I18n.locale || 'en';
  }
}

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

import { Injectable, Injector } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';

import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

@Injectable()
export class GlobalSearchService {
  private _searchTerm = new BehaviorSubject<string>('');

  public searchTerm$ = this._searchTerm.asObservable();

  // Default selected tab is Work Packages
  private _currentTab = new BehaviorSubject<any>('work_packages');

  public currentTab$ = this._currentTab.asObservable();

  // Default project scope is "this project and all subprojects"
  private _projectScope = new BehaviorSubject<any>('');

  public projectScope$ = this._projectScope.asObservable();

  private _tabs = new BehaviorSubject<any>([]);

  public tabs$ = this._tabs.asObservable();

  // Sometimes we need to be able to hide the search results altogether, i.e. while expecting a full page reload.
  private _resultsHidden = new BehaviorSubject<any>(false);

  public resultsHidden$ = this._resultsHidden.asObservable();

  constructor(
    protected I18n:I18nService,
    protected injector:Injector,
    protected PathHelper:PathHelperService,
    protected currentProjectService:CurrentProjectService,
  ) {
    this.initialize();
  }

  private initialize():void {
    const initialData = this.loadGonData();
    if (initialData) {
      if (initialData.available_search_types) {
        this._tabs.next(initialData.available_search_types);
      }
      if (initialData.search_term) {
        this._searchTerm.next(initialData.search_term);
      }
      if (initialData.current_tab) {
        this._currentTab.next(initialData.current_tab);
      }

      if (initialData.project_scope) {
        this._projectScope.next(initialData.project_scope);
      } else if (!this.currentProjectService.path) {
        this._projectScope.next('all');
      }
    }
  }

  private loadGonData():{ available_search_types:string[],
    search_term:string,
    project_scope:string,
    current_tab:string }|null {
    try {
      return (window as any).gon.global_search;
    } catch (e) {
      return null;
    }
  }

  public submitSearch():void {
    window.location.href = this.searchPath();
  }

  public searchPath() {
    let searchPath:string = this.PathHelper.staticBase;
    if (this.currentProjectService.path && this.projectScope !== 'all') {
      searchPath = this.currentProjectService.path;
    }
    searchPath += `/search?${this.searchQueryParams()}`;
    return searchPath;
  }

  public set searchTerm(searchTerm:string) {
    this._searchTerm.next(searchTerm);
  }

  public get searchTerm():string {
    return this._searchTerm.value;
  }

  public get searchTermIsId():boolean {
    return this.searchTermWithoutHash !== this.searchTerm;
  }

  public get searchTermWithoutHash():string {
    if (/^#(\d+)/.exec(this.searchTerm)) {
      return this.searchTerm.substr(1);
    }
    return this.searchTerm;
  }

  public get tabs():string {
    return this._tabs.value;
  }

  public get currentTab():string {
    return this._currentTab.value;
  }

  public set currentTab(tab:string) {
    this._currentTab.next(tab);
  }

  public get projectScope():string {
    return this._projectScope.value;
  }

  public set projectScope(value:string) {
    this._projectScope.next(value);
  }

  public get resultsHidden():boolean {
    return this._resultsHidden.value;
  }

  public set resultsHidden(value:boolean) {
    this._resultsHidden.next(value);
  }

  private searchQueryParams():string {
    let params:string;

    params = `q=${encodeURIComponent(this.searchTerm)}`;

    if (this.currentTab.length > 0 && this.currentTab !== 'all') {
      params = `${params}&${this.currentTab}=1`;
    }
    if (this.projectScope.length > 0) {
      params = `${params}&scope=${this.projectScope}`;
    }

    return params;
  }

  public isAfterSearch():boolean {
    return (jQuery('body.controller-search').length > 0);
  }
}

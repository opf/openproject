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

import {Injectable} from '@angular/core';
import {BehaviorSubject} from 'rxjs';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {Injector} from "@angular/core";

@Injectable()
export class GlobalSearchService {
  private _searchTerm = new BehaviorSubject<string>('');
  public searchTerm$ = this._searchTerm.asObservable();

  private _currentTab = new BehaviorSubject<any>('work_packages');
  public currentTab$ = this._currentTab.asObservable();

  private _projectScope = new BehaviorSubject<any>('all');
  public projectScope$ = this._projectScope.asObservable();

  private _tabs = new BehaviorSubject<any>([]);
  public tabs$ = this._tabs.asObservable();

  constructor(protected I18n:I18nService,
              protected injector:Injector,
              readonly currentProjectService:CurrentProjectService) {
    this.initialize();
  }

  private initialize():void {
    let initialData = this.loadGonData();
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
      }
    }
  }

  private loadGonData():{available_search_types:string[],
                                search_term:string,
                                project_scope:string,
                                current_tab:string}|null {
    try {
      return (window as any).gon.global_search;
    } catch (e) {
      return null;
    }
  }

  public submitSearch():void {
    let searchPath:string = '';
    if (this.currentProjectService.path) {
      searchPath = this.currentProjectService.path;
    }
    searchPath = searchPath + `/search?${this.searchQueryParams()}`;
    window.location.href = searchPath;
  }

  public set searchTerm(searchTerm:string) {
    this._searchTerm.next(searchTerm);
  }

  public get searchTerm():string {
    return this._searchTerm.value;
  }

  public get tabs():string {
    return this._tabs.value;
  }

  public get currentTab():string {
    return this._currentTab.value;
  }

  public get projectScope():string {
    return this._projectScope.value;
  }

  public set projectScope(value:string) {
    this._projectScope.next(value);
  }

  private searchQueryParams():string {
    let params:string;

    params = `q=${this.searchTerm}&scope=${this.projectScope}`;

    if (this.currentTab.length > 0) {
      params = `${params}&${this.currentTab}=1`;
    }
    if (this.projectScope.length > 0) {
      params = `${params}&scope=${this.projectScope}`;
    }

    return params;
  }
}

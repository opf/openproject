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
  public changeData$ = this._currentTab.asObservable();

  private _projectScope = new BehaviorSubject<any>('all');
  public projectScope$ = this._projectScope.asObservable();

  private tabs = new BehaviorSubject<any>([]);
  public tabs$ = this.tabs.asObservable();


  constructor(protected I18n:I18nService,
              protected injector:Injector) {
    this.initialize();
  }

  private initialize():void {
    let initialData = this.loadGonData();
    if (initialData) {
      if (initialData.available_search_types) {
        this.tabs.next(initialData.available_search_types);
      }
      if (initialData.search_term) {
        this.tabs.next(initialData.search_term);
      }
      if (initialData.current_tab) {
        this.tabs.next(initialData.current_tab);
      }
      if (initialData.project_scope) {
        this.tabs.next(initialData.project_scope);
      }
    }
  }

  private loadGonData():{available_search_types:string[],
                                search_term:string,
                                project_scope:string,
                                current_tab:string}|null {
    try {
      return (window as any).gon.search_options;
    } catch (e) {
      console.log("Can't load initial search options from gon: " + e);
      return null;
    }
  }

  public set searchTerm(searchTerm:string) {
    this._searchTerm.next(searchTerm);
  }
}

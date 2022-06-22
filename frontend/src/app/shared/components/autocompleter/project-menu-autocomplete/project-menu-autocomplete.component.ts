// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2022 the OpenProject GmbH
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

import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HttpClient } from '@angular/common/http';
import {
  ChangeDetectionStrategy,
  Component,
  OnInit,
} from '@angular/core';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { BehaviorSubject } from 'rxjs';
import {
  debounceTime,
  map,
  shareReplay,
  switchMap,
} from 'rxjs/operators';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { loadAvailableProjects } from 'core-app/shared/components/autocompleter/project-autocompleter/load-projects';
import { IProjectAutocompleteItem } from 'core-app/shared/components/autocompleter/project-autocompleter/project-autocomplete-item';
import { ApiV3ListFilter } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';

export interface IProjectMenuEntry {
  id:number;
  name:string;
  identifier:string;
  parents:IProjectMenuEntry[];
  level:number;
}

export const projectMenuAutocompleteSelector = 'project-menu-autocomplete';

@Component({
  templateUrl: './project-menu-autocomplete.template.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: projectMenuAutocompleteSelector,
})
export class ProjectMenuAutocompleteComponent implements OnInit {
  dropModalOpen = false;

  private _searchText = '';

  public get searchText():string {
    return this._searchText;
  }

  public set searchText(val:string) {
    this._searchText = val;
    this.searchText$.next(val);
  }

  public searchText$ = new BehaviorSubject('');

  projects$ = this
    .searchText$
    .pipe(
      debounceTime(200),
      switchMap((term) => this.loadProjects(term)),
      shareReplay(),
    );

  public text = {
    project: {
      singular: this.I18n.t('js.label_project'),
      plural: this.I18n.t('js.label_project_plural'),
      list: this.I18n.t('js.label_project_list'),
      select: this.I18n.t('js.label_select_project'),
    },
    search_placeholder: this.I18n.t('js.include_projects.search_placeholder'),
  };

  constructor(
    protected pathHelper:PathHelperService,
    protected I18n:I18nService,
    protected currentProject:CurrentProjectService,
    protected apiV3Service:ApiV3Service,
    protected http:HttpClient,
  ) {}

  ngOnInit():void {
  }

  toggleDropModal():void {
    this.dropModalOpen = !this.dropModalOpen;
  }

  close():void {
    this.dropModalOpen = false;
  }

  currentProjectName():string {
    if (this.currentProject.name !== null) {
      return this.currentProject.name;
    }

    return this.text.project.select;
  }

  allProjectsPath():string {
    return this.pathHelper.projectsPath();
  }

  newProjectPath():string {
    const parentParam = this.currentProject.id ? `?parent_id=${this.currentProject.id}` : '';
    return `${this.pathHelper.projectsNewPath()}${parentParam}`;
  }

  private loadProjects(searchString:string) {
    const apiFilters:ApiV3ListFilter[] = [];
    const apiUrl = this.apiV3Service.projects.path;
    const mapResultsFn = (projects:IProjectAutocompleteItem[]) => projects;

    return loadAvailableProjects(
      searchString,
      apiFilters,
      apiUrl,
      mapResultsFn,
      this.http,
    )
      .pipe(
        map((projects) => {
          return projects.map((project) => ({
            id: project.id,
            href: project.href,
            name: project.name,
            found: true,
            children: project.children,
          }));
        }),
      );
  }

  /*
  onItemSelected(project:IProjectMenuEntry):void {
    window.location.href = this.projectLink(project.identifier);
  }

  projectLink(identifier:string):string {
    const currentMenuItem = jQuery('meta[name="current_menu_item"]').attr('content');
    let url = this.PathHelper.projectPath(identifier);

    if (currentMenuItem) {
      url += `?jump=${encodeURIComponent(currentMenuItem)}`;
    }

    return url;
  }
  */
}

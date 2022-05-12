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

import {
  Component, ElementRef, EventEmitter, Injector, Input, OnInit, Output, ViewChild,
} from '@angular/core';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import {
  DebouncedRequestSwitchmap,
  errorNotificationHandler,
} from 'core-app/shared/helpers/rxjs/debounced-input-switchmap';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { NgSelectComponent } from '@ng-select/ng-select';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { DatasetInputs } from 'core-app/shared/components/dataset-inputs.decorator';
import { ApiV3ListFilter, listParamsString } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { getPaginatedResults } from 'core-app/core/apiv3/helpers/get-paginated-results';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { IProject } from 'core-app/core/state/projects/project.model';
import { HttpClient } from '@angular/common/http';

import { insertInList } from '../../project-include/insert-in-list';
import { recursiveSort } from '../../project-include/recursive-sort';
import { IProjectData } from '../../project-include/project-data';
import { ID } from '@datorama/akita';

export const projectsAutocompleterSelector = 'op-project-autocompleter';

export interface IProjectAutocompleteItem {
  name:string;
  id:ID;
  href:string|null;
  numberOfAncestors:number;
  disabled?:boolean;
  disabledReason?:string;
}

const flattenProjectTree = (projectTree:IProjectData, depth = 0):IProjectAutocompleteItem[] => {
  let projectList = [
    {
      name: projectTree.name,
      id: projectTree.id,
      href: projectTree.href,
      numberOfAncestors: depth,
    }
  ];

  return projectTree.children.reduce((list, child) => [
    ...list,
    ...flattenProjectTree(child, depth + 1),
  ], projectList);
};

@DatasetInputs
@Component({
  templateUrl: './project-autocompleter.component.html',
  selector: projectsAutocompleterSelector,
})
export class ProjectAutocompleterComponent implements OnInit {
  projectTracker = (item:any) => item.href || item.id;

  @ViewChild(NgSelectComponent, { static: true }) public ngSelectComponent:NgSelectComponent;

  @Output() public onChange = new EventEmitter<IProjectAutocompleteItem>();

  @Input() public clearAfterSelection = false;

  // Load all projects as default
  @Input() public url:string = this.apiV3Service.projects.path;

  @Input() public allowEmpty = false;

  @Input() public appendTo = '';

  @Input() public multiple = false;

  @Input() public initialSelection:number|null = null;

  @Input() public APIFilters:ApiV3ListFilter[] = [];

  @Input() public resultsFilterFn:(projects:IProject[]) => IProject[] = (projects) => projects;

  // Update an input field after changing, used when externally loaded
  private updateInputField:HTMLInputElement|undefined;

  /** Keep a switchmap for search term and loading state */
  public requests = new DebouncedRequestSwitchmap<string, IProjectAutocompleteItem>(
    (searchTerm:string) => this.getAvailableProjects(searchTerm),
    errorNotificationHandler(this.halNotification),
  );

  constructor(
    public elementRef:ElementRef,
    protected halResourceService:HalResourceService,
    protected I18n:I18nService,
    protected halNotification:HalResourceNotificationService,
    readonly http:HttpClient,
    readonly pathHelper:PathHelperService,
    readonly apiV3Service:ApiV3Service,
    readonly injector:Injector,
  ) { }

  ngOnInit() { }

  public onFocus() {
    if (!this.requests.lastRequestedValue) {
      this.requests.input$.next('');
    }
  }

  public onModelChange(project:any) {
    if (project) {
      this.onChange.emit(project);
      this.requests.input$.next('');

      if (this.clearAfterSelection) {
        this.ngSelectComponent.clearItem(project);
      }

      if (this.updateInputField) {
        if (this.multiple) {
          this.updateInputField.value = project.map((u:ProjectResource) => u.id);
        } else {
          this.updateInputField.value = project.id;
        }
      }
    }
  }

  protected getAvailableProjects(searchTerm:string):Observable<IProjectAutocompleteItem[]> {
    return getPaginatedResults<IProject>(
      (params) => {
        const filters:ApiV3ListFilter[] = [ ...this.APIFilters ];
        const fullParams = {
          filters,
          select: [
            'elements/id',
            'elements/name',
            'elements/identifier',
            'elements/self',
            'elements/ancestors',
            'total',
            'count',
            'pageSize',
          ],
          ...params,
        };
        const collectionURL = listParamsString(fullParams);
        return this.http.get<IHALCollection<IProject>>(this.url + collectionURL);
      },
    )
      .pipe(
        map(this.resultsFilterFn),
        map((projects) => projects
          .sort((a, b) => a._links.ancestors.length - b._links.ancestors.length)
          .reduce(
            (list, project) => {
              const { ancestors } = project._links;

              return insertInList(projects, project, list, ancestors);
            },
            [] as IProjectData[],
          )
        ),
        map((projects) => recursiveSort(projects)),
        map((projectTreeItems) => projectTreeItems
          .map(item => flattenProjectTree(item))
          .reduce((total, list) => [...total, ...list], []),
       )
      );
  }

  private setInitialSelection() {
    if (this.updateInputField) {
      const id = parseInt(this.updateInputField.value);
      this.initialSelection = isNaN(id) ? null : id;
    }
  }
}

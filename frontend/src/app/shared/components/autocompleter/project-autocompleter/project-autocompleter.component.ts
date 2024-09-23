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

import {
  ChangeDetectionStrategy,
  Component,
  EventEmitter,
  forwardRef,
  HostBinding,
  Input,
  OnInit,
  Output,
  ViewEncapsulation,
} from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';
import { merge, Observable, of } from 'rxjs';
import { map, switchMap } from 'rxjs/operators';
import { ID } from '@datorama/akita';
import { IProjectAutocompleteItem } from './project-autocomplete-item';
import { flattenProjectTree } from './flatten-project-tree';
import { getPaginatedResults } from 'core-app/core/apiv3/helpers/get-paginated-results';
import { IProject } from 'core-app/core/state/projects/project.model';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { buildTree } from 'core-app/shared/components/autocompleter/project-autocompleter/insert-in-list';
import { recursiveSort } from 'core-app/shared/components/autocompleter/project-autocompleter/recursive-sort';
import {
  OpAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/op-autocompleter/op-autocompleter.component';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import {
  ProjectAutocompleterTemplateComponent,
} from 'core-app/shared/components/autocompleter/project-autocompleter/project-autocompleter-template.component';
import { addFiltersToPath } from 'core-app/core/apiv3/helpers/add-filters-to-path';

export const projectsAutocompleterSelector = 'op-project-autocompleter';

export interface IProjectAutocompleterData {
  id:ID;
  href:string;
  name:string;
}

@Component({
  templateUrl: '../op-autocompleter/op-autocompleter.component.html',
  styleUrls: ['./project-autocompleter.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  selector: projectsAutocompleterSelector,
  providers: [{
    provide: NG_VALUE_ACCESSOR,
    useExisting: forwardRef(() => ProjectAutocompleterComponent),
    multi: true,
  }],
})
export class ProjectAutocompleterComponent extends OpAutocompleterComponent<IProjectAutocompleterData> implements OnInit, ControlValueAccessor {
  @HostBinding('class.op-project-autocompleter') public className = true;

  @HostBinding('class.op-project-autocompleter_inline')
  public get inlineClass():boolean {
    return this.isInlineContext;
  }

  // Load all projects as default
  @Input() public url:string = this.apiV3Service.projects.path;

  @Input() public isInlineContext = false;

  @Input() public disabledProjects:{ [key:string]:string|boolean } = {};

  // This function allows mapping of the results before they are fed to the tree
  // structuring and destructuring algorithms used internally the this component
  // to show the tree structure. By default it does not do much, but it is
  // overwritable so additional filtering or transforming can be done on the
  // API result set.
  @Input()
  public mapResultsFn:(projects:IProjectAutocompleteItem[]) => IProjectAutocompleteItem[] = (projects) => projects;

  /* eslint-disable-next-line @angular-eslint/no-output-rename */
  @Output('valueChange') valueChange = new EventEmitter<IProjectAutocompleterData|IProjectAutocompleterData[]|null>();

  projectTracker = (item:IProjectAutocompleteItem):ID => item.href || item.id;

  getOptionsFn = this.getAvailableProjects.bind(this);

  dataLoaded = false;

  projects:IProjectAutocompleteItem[];

  ngOnInit() {
    super.ngOnInit();

    this.applyTemplates(ProjectAutocompleterTemplateComponent, {});
  }

  private matchingItems(elements:IProjectAutocompleteItem[], matching:string):Observable<IProjectAutocompleteItem[]> {
    let filtered:IProjectAutocompleteItem[];

    if (matching === '' || !matching) {
      filtered = elements;
    } else {
      const lowered = matching.toLowerCase();
      filtered = elements.filter((el) => el.name.toLowerCase().includes(lowered));
    }

    return of(filtered);
  }

  private disableSelectedItems(
    projects:IProjectAutocompleteItem[],
    value:IProjectAutocompleterData|IProjectAutocompleterData[]|null|undefined,
  ) {
    if (!this.multiple) {
      return projects;
    }

    const normalizedValue = (value || []);
    const arrayedValue = (Array.isArray(normalizedValue) ? normalizedValue : [normalizedValue]).map((p) => p.href || p.id);
    return projects.map((project) => {
      const isSelected = !!arrayedValue.find((selected) => selected === this.projectTracker(project));
      const id = project.id.toString();
      const disabled = isSelected || project.disabled || !!this.disabledProjects[id];
      return {
        ...project,
        disabled,
        disabledReason: (typeof this.disabledProjects[id] === 'string') ? this.disabledProjects[id] as string : '',
      };
    });
  }

  public getAvailableProjects(searchTerm:string):Observable<IProjectAutocompleteItem[]> {
    if (this.dataLoaded) {
      return this.matchingItems(this.projects, searchTerm).pipe(
        map(this.mapResultsFn),
        map((projects) => projects.sort((a, b) => a.ancestors.length - b.ancestors.length)),
        map((projects) => buildTree(projects)),
        map((projects) => recursiveSort(projects)),
        map((projectTreeItems) => flattenProjectTree(projectTreeItems)),
        switchMap(
          (projects) => merge(of([]), this.valueChange).pipe(
            map(() => this.disableSelectedItems(projects, this.model)),
          ),
        ),
      );
    }
    return getPaginatedResults<IProject>(
      (params) => {
        const filteredURL = this.buildFilteredURL(searchTerm);

        filteredURL.searchParams.set('pageSize', params.pageSize?.toString() || '-1');
        filteredURL.searchParams.set('offset', params.offset?.toString() || '1');
        filteredURL.searchParams.set('select', 'elements/id,elements/name,elements/identifier,elements/self,elements/ancestors,total,count,pageSize');

        return this
          .http
          .get<IHALCollection<IProject>>(filteredURL.toString());
      },
    )
      .pipe(
        map((projects) => projects.map((project) => {
          const id = project.id.toString();
          const disabled = !!this.disabledProjects[id];

          return {
            id: project.id,
            href: project._links.self.href,
            name: project.name,
            disabled,
            disabledReason: (typeof this.disabledProjects[id] === 'string') ? this.disabledProjects[id] as string : '',
            ancestors: project._links.ancestors,
            children: [],
          };
        })),
        map(this.mapResultsFn),
        map((projects) => {
          this.dataLoaded = true;
          this.projects = projects;
          return projects.sort((a, b) => a.ancestors.length - b.ancestors.length);
        }),
        map((projects) => buildTree(projects)),
        map((projects) => recursiveSort(projects)),
        map((projectTreeItems) => flattenProjectTree(projectTreeItems)),
        switchMap(
          (projects) => merge(of([]), this.valueChange).pipe(
            map(() => this.disableSelectedItems(projects, this.model)),
          ),
        ),
      );
  }

  // Todo: Reduce duplication with method from user-autocompleter
  protected buildFilteredURL(searchTerm?:string):URL {
    const filterObject = _.keyBy(this.filters, 'name');
    const searchFilters = ApiV3FilterBuilder.fromFilterObject(filterObject);

    if (searchTerm?.length) {
      searchFilters.add('typeahead', '**', [searchTerm]);
    }

    return addFiltersToPath(this.url, searchFilters);
  }
}

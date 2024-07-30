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
  HostBinding,
  OnInit,
} from '@angular/core';
import { BehaviorSubject, combineLatest } from 'rxjs';
import {
  debounceTime,
  distinctUntilChanged,
  filter,
  map,
  mergeMap,
  shareReplay,
  take,
} from 'rxjs/operators';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import {
  WorkPackageViewFiltersService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import {
  WorkPackageViewIncludeSubprojectsService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-include-subprojects.service';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { IProject } from 'core-app/core/state/projects/project.model';
import {
  SearchableProjectListService,
} from 'core-app/shared/components/searchable-project-list/searchable-project-list.service';
import { IProjectData } from 'core-app/shared/components/searchable-project-list/project-data';

import { insertInList } from './insert-in-list';
import { recursiveSort } from './recursive-sort';
import { calculatePositions } from 'core-app/shared/components/project-include/calculate-positions';

@Component({
  selector: 'op-project-include',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './project-include.component.html',
  styleUrls: ['./project-include.component.sass'],
  providers: [
    SearchableProjectListService,
  ],
})
export class OpProjectIncludeComponent extends UntilDestroyedMixin implements OnInit {
  @HostBinding('class.op-project-include') className = true;

  public text = {
    toggle_title: this.I18n.t('js.include_projects.toggle_title'),
    title: this.I18n.t('js.include_projects.title'),
    filter_all: this.I18n.t('js.include_projects.selected_filter.all'),
    filter_selected: this.I18n.t('js.include_projects.selected_filter.selected'),
    search_placeholder: this.I18n.t('js.include_projects.search_placeholder'),
    clear_selection: this.I18n.t('js.include_projects.clear_selection'),
    apply: this.I18n.t('js.include_projects.apply'),
    include_subprojects: this.I18n.t('js.include_projects.include_subprojects'),
    no_results: this.I18n.t('js.include_projects.no_results'),
  };

  public opened = false;

  public textFieldFocused = false;

  public query$ = this.wpTableFilters.querySpace.query.values$();

  public displayModeOptions = [
    { value: 'all', title: this.text.filter_all },
    { value: 'selected', title: this.text.filter_selected },
  ];

  private _displayMode = 'all';

  public get displayMode():string {
    return this._displayMode;
  }

  public set displayMode(val:string) {
    this._displayMode = val;
    this.displayMode$.next(val);
  }

  public displayMode$ = new BehaviorSubject('all');

  private _includeSubprojects = true;

  public get includeSubprojects():boolean {
    return this._includeSubprojects;
  }

  public set includeSubprojects(val:boolean) {
    this._includeSubprojects = val;
    this.includeSubprojects$.next(val);
  }

  public includeSubprojects$ = new BehaviorSubject(true);

  private _selectedProjects:string[] = [];

  public get selectedProjects():string[] {
    return this._selectedProjects;
  }

  public set selectedProjects(val:string[]) {
    this._selectedProjects = val;
    this.selectedProjects$.next(val);
  }

  public selectedProjects$ = new BehaviorSubject<string[]>([]);

  private projectsInFilter$ = this.wpTableFilters
    .live$()
    .pipe(
      this.untilDestroyed(),
      map((queryFilters) => {
        const projectFilter = queryFilters.find((queryFilter) => queryFilter._type === 'ProjectQueryFilter');
        const selectedProjectHrefs = ((projectFilter?.values || []) as HalResource[]).map((p) => p.href);
        const currentProjectHref = this.currentProjectService.apiv3Path;
        if (selectedProjectHrefs.includes(currentProjectHref)) {
          return selectedProjectHrefs;
        }
        const selectedProjects = [...selectedProjectHrefs];
        if (currentProjectHref) {
          selectedProjects.push(currentProjectHref);
        }
        return selectedProjects;
      }),
    );

  public numberOfProjectsInFilter$ = this.projectsInFilter$.pipe(map((selected) => selected.length));

  public projects$ = combineLatest([
    this.searchableProjectListService.allProjects$,
    this.displayMode$.pipe(distinctUntilChanged()),
    this.includeSubprojects$.pipe(debounceTime(20)),
    this.searchableProjectListService.searchText$.pipe(debounceTime(200)),
  ]).pipe(
    mergeMap(([projects, displayMode, includeSubprojects, searchText]) => this.selectedProjects$.pipe(
      take(1),
      map((selected) => [projects, displayMode, includeSubprojects, searchText, selected]),
    )),
    map(
      ([projects, displayMode, includeSubprojects, searchText, selected]:[IProject[], string, boolean, string, string[]]) => [
        projects
          .filter(
            (project) => {
              if (searchText.length) {
                const matches = project.name.toLowerCase().includes(searchText.toLowerCase());

                if (!matches) {
                  return false;
                }
              }

              if (displayMode !== 'selected') {
                return true;
              }

              if (selected.includes(project._links.self.href)) {
                return true;
              }

              const hasSelectedAncestor = project._links.ancestors.reduce(
                (anySelected, ancestor) => anySelected || selected.includes(ancestor.href),
                false,
              );

              if (includeSubprojects && hasSelectedAncestor) {
                return true;
              }

              return false;
            },
          )
          .sort((a, b) => a._links.ancestors.length - b._links.ancestors.length)
          .reduce(
            (list, project) => {
              const { ancestors } = project._links;

              return insertInList(
                projects,
                project,
                list,
                ancestors,
              );
            },
            [] as IProjectData[],
          ),
        includeSubprojects,
      ],
    ),
    mergeMap(([projects, includeSubprojects]) => this.selectedProjects$.pipe(
      map((selected) => [projects, includeSubprojects, selected]),
    )),
    map(([projects, includeSubprojects, selected]:[IProjectData[], boolean, string[]]) => {
      const isDisabled = (project:IProjectData, parentChecked:boolean) => {
        if (project.disabled) {
          return true;
        }

        if (project.href === this.currentProjectService.apiv3Path) {
          return true;
        }

        return includeSubprojects && parentChecked;
      };

      const setDisabledStatus = (project:IProjectData, parentChecked:boolean):IProjectData => ({
        ...project,
        disabled: isDisabled(project, parentChecked),
        children: project.children.map(
          (child) => setDisabledStatus(child, parentChecked || selected.includes(project.href)),
        ),
      });

      return projects.map((project) => setDisabledStatus(project, false));
    }),
    map((projects) => recursiveSort(projects)),
    map((projects) => (calculatePositions(projects))[0]),
    shareReplay(),
  );

  /* This seems like a way too convoluted loading check, but there's a good reason we need it.
   * The searchableProjectListService says fetching is "done" when the request returns.
   * However, this causes flickering on the initial load, since `projects$` still needs
   * to do the tree calculation. In the template, we show the project-list when `loading$ | async` is false,
   * but if we would only make this depend on `fetchingProjects$` Angular would still wait with
   * rendering the project-list until `projects$ | async` has also fired.
   *
   * To fix this, we first wait for fetchingProjects$ to be true once,
   * then switch over to projects$, and after that has pinged once, it switches back to
   * fetchingProjects$ as the decider for when fetching is done.
   */
  public loading$ = this.searchableProjectListService.fetchingProjects$.pipe(
    filter((fetching) => fetching),
    take(1),
    mergeMap(() => this.projects$),
    mergeMap(() => this.searchableProjectListService.fetchingProjects$),
  );

  constructor(
    readonly I18n:I18nService,
    readonly wpTableFilters:WorkPackageViewFiltersService,
    readonly wpIncludeSubprojects:WorkPackageViewIncludeSubprojectsService,
    readonly halResourceService:HalResourceService,
    readonly currentProjectService:CurrentProjectService,
    readonly searchableProjectListService:SearchableProjectListService,
  ) {
    super();

    this.projects$
      .pipe(
        this.untilDestroyed(),
        filter((p) => p.length > 0),
        take(1),
      )
      .subscribe((projects) => {
        this.searchableProjectListService.resetActiveResult(projects);
      });
  }

  public ngOnInit():void {
    this.query$
      .pipe(
        map((query) => query.includeSubprojects),
        distinctUntilChanged(),
      )
      .subscribe((includeSubprojects) => {
        this.includeSubprojects = includeSubprojects;
      });
  }

  public toggleIncludeSubprojects():void {
    this.wpIncludeSubprojects.setIncludeSubprojects(!this.wpIncludeSubprojects.current);
  }

  public toggleOpen():void {
    this.opened = !this.opened;

    if (this.opened) {
      this.searchableProjectListService.loadAllProjects();
      this.projectsInFilter$
        .pipe(
          take(1),
        )
        .subscribe((selectedProjects) => {
          this.displayMode = 'all';
          this.searchableProjectListService.searchText = '';
          this.selectedProjects = selectedProjects as string[];
        });
    }
  }

  public clearSelection():void {
    this.selectedProjects = [this.currentProjectService.apiv3Path || ''];
  }

  public onSubmit(e:Event):void {
    e.preventDefault();

    // Replace actually also instantiates if it does not exist, which is handy here
    this.wpTableFilters.replace('project', (projectFilter:QueryFilterInstanceResource) => {
      const projectHrefs = this.selectedProjects;
      // eslint-disable-next-line no-param-reassign
      projectFilter.values = projectHrefs.map((href:string) => this.halResourceService.createHalResource({ href }, true));
    });

    this.wpIncludeSubprojects.update(this.includeSubprojects);

    this.close();
  }

  public close():void {
    this.opened = false;
  }
}

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

import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ChangeDetectionStrategy, Component, HostBinding, ViewEncapsulation } from '@angular/core';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { combineLatest, Observable, ReplaySubject } from 'rxjs';
import { debounceTime, defaultIfEmpty, filter, map, mergeMap, shareReplay, take } from 'rxjs/operators';
import { IProject } from 'core-app/core/state/projects/project.model';
import { insertInList } from 'core-app/shared/components/project-include/insert-in-list';
import { recursiveSort } from 'core-app/shared/components/project-include/recursive-sort';
import {
  SearchableProjectListService,
} from 'core-app/shared/components/searchable-project-list/searchable-project-list.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { IProjectData } from 'core-app/shared/components/searchable-project-list/project-data';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3Filter } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { ConfigurationService } from 'core-app/core/config/configuration.service';


@Component({
  selector: 'opce-header-project-select',
  templateUrl: './header-project-select.component.html',
  styleUrls: ['./header-project-select.component.sass'],
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    SearchableProjectListService,
  ],
})
export class OpHeaderProjectSelectComponent extends UntilDestroyedMixin {
  @HostBinding('class.op-header-project-select') className = true;

  public dropModalOpen = false;

  public textFieldFocused = false;

  public canCreateNewProjects$ = this.currentUserService.hasCapabilities$('projects/create', 'global');

  public projects$ = combineLatest([
    this.searchableProjectListService.allProjects$,
    this.searchableProjectListService.searchText$.pipe(debounceTime(200)),
  ]).pipe(
    map(
      ([projects, searchText]:[IProject[], string]) => projects
        .filter(
          (project) => {
            if (searchText.length) {
              const matches = project.name.toLowerCase().includes(searchText.toLowerCase());

              if (!matches) {
                return false;
              }
            }

            return true;
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
    ),
    map((projects) => recursiveSort(projects)),
    shareReplay(),
  );

  public favorites$:Observable<string[]> = this
    .apiV3Service
    .projects
    .signalled(
      ApiV3Filter('favored', '=', true),
      [
        'elements/id',
      ],
      { pageSize: '-1' },
    )
    .pipe(
      map((collection:IHALCollection<{ id:string|number }>) => collection._embedded.elements || []),
      map((elements) => elements.map((item) => item.id.toString())),
      defaultIfEmpty([]),
      shareReplay(1),
    );

  public text = {
    all: this.I18n.t('js.label_all_uppercase'),
    favored: this.I18n.t('js.label_favorites'),
    no_favorites: this.I18n.t('js.favorite_projects.no_results'),
    no_favorites_subtext: this.I18n.t('js.favorite_projects.no_results_subtext'),
    project: {
      singular: this.I18n.t('js.label_project'),
      plural: this.I18n.t('js.label_project_plural'),
      list: this.I18n.t('js.label_project_list'),
      select: this.I18n.t('js.label_select_project'),
    },
    search_placeholder: this.I18n.t('js.include_projects.search_placeholder'),
    no_results: this.I18n.t('js.include_projects.no_results'),
  };

  public displayMode:'all'|'favored' = 'all';

  public displayModeOptions = [
    { value: 'all', title: this.text.all },
    { value: 'favored', title: this.text.favored },
  ];

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

  private scrollToCurrent = false;

  private subscriptionComplete$ = new ReplaySubject<void>(1);

  constructor(
    readonly pathHelper:PathHelperService,
    readonly configuration:ConfigurationService,
    readonly I18n:I18nService,
    readonly currentProject:CurrentProjectService,
    readonly searchableProjectListService:SearchableProjectListService,
    readonly currentUserService:CurrentUserService,
    readonly apiV3Service:ApiV3Service,
  ) {
    super();

    this.projects$
      .pipe(this.untilDestroyed())
      .subscribe((projects) => {
        if (this.currentProject.id && projects.length && this.scrollToCurrent) {
          this.searchableProjectListService.selectedItemID$.next(parseInt(this.currentProject.id, 10));
        } else {
          this.searchableProjectListService.resetActiveResult(projects);
        }

        this.scrollToCurrent = false;
        this.subscriptionComplete$.next(); // Signal that subscription logic is complete
      });
  }

  toggleDropModal():void {
    this.subscriptionComplete$.pipe(take(1)).subscribe(() => {
      this.dropModalOpen = !this.dropModalOpen;
      if (this.dropModalOpen) {
        this.scrollToCurrent = true;
        this.searchableProjectListService.loadAllProjects();
      }
    });
  }

  displayModeChange(mode:'all'|'favored'):void {
    this.displayMode = mode;

    if (this.currentProject?.id) {
      this.searchableProjectListService.selectedItemID$.next(parseInt(this.currentProject.id, 10));
    }
  }

  close():void {
    this.searchableProjectListService.searchText = '';
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

  anyProjectsFound(projects:IProjectData[], favorites:string[]):boolean {
    if (this.displayMode === 'all') {
      return projects.length > 0;
    }

    return projects.length > 0 && favorites.length > 0;
  }
}

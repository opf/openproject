//-- copyright
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
//++

import {AfterContentInit, Component, Input, ViewChild, ViewEncapsulation} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {Observable, of, Subject} from "rxjs";
import {catchError, debounceTime, distinctUntilChanged, map, switchMap, tap} from "rxjs/operators";
import {WorkPackageInlineCreateService} from "core-components/wp-inline-create/wp-inline-create.service";
import {WorkPackageNotificationService} from "core-components/wp-edit/wp-notification.service";
import {NgSelectComponent} from "@ng-select/ng-select";
import {WorkPackageInlineCreateComponent} from "core-components/wp-inline-create/wp-inline-create.component";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {WorkPackageTableRefreshService} from "core-components/wp-table/wp-table-refresh-request.service";
import {WorkPackageCollectionResource} from "core-app/modules/hal/resources/wp-collection-resource";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {ApiV3FilterBuilder} from "core-components/api/api-v3/api-v3-filter-builder";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {ReorderQueryService} from "core-app/modules/boards/drag-and-drop/reorder-query.service";

@Component({
  selector: 'board-inline-add-autocompleter',
  templateUrl: './board-inline-add-autocompleter.html',

  // Allow styling the embedded ng-select
  encapsulation: ViewEncapsulation.None,
  styleUrls: ['./board-inline-add-autocompleter.sass']
})
export class BoardInlineAddAutocompleterComponent implements AfterContentInit {
  readonly text = {
    placeholder: this.I18n.t('js.relations_autocomplete.placeholder')
  };

  @Input() appendToContainer:string = '.boards-list--item';
  @ViewChild(NgSelectComponent) public ngSelectComponent:NgSelectComponent;

  // Whether we're currently loading
  public isLoading = false;

  // Search input from ng-select
  public searchInput$ = new Subject<string>();

  // Search results mapped to input
  public results$:Observable<WorkPackageResource[]> = this.searchInput$.pipe(
    debounceTime(250),
    distinctUntilChanged(),
    tap(() => this.isLoading = true),
    switchMap(queryString => this.autocompleteWorkPackages(queryString))
  );

  constructor(private readonly parent:WorkPackageInlineCreateComponent,
              private readonly querySpace:IsolatedQuerySpace,
              private readonly pathHelper:PathHelperService,
              private readonly wpTableRefresh:WorkPackageTableRefreshService,
              private readonly wpInlineCreateService:WorkPackageInlineCreateService,
              private readonly wpNotificationsService:WorkPackageNotificationService,
              private readonly CurrentProject:CurrentProjectService,
              private readonly halResourceService:HalResourceService,
              private readonly reorderQueryService:ReorderQueryService,
              private readonly I18n:I18nService) {
  }

  ngAfterContentInit():void {
    this.ngSelectComponent && this.ngSelectComponent.open();
  }

  cancel() {
    this.parent.resetRow();
  }

  public addWorkPackageToQuery(wpId:string) {
    this.reorderQueryService
      .add(this.querySpace, wpId)
      .then(() => this.wpTableRefresh.request('Row added', 'update'));
  }

  private autocompleteWorkPackages(query:string):Observable<WorkPackageResource[]> {
    const path = this.pathHelper.api.v3.withOptionalProject(this.CurrentProject.id).work_packages;
    const filters:ApiV3FilterBuilder = new ApiV3FilterBuilder();
    const rows:WorkPackageResource[] = this.querySpace.rows.getValueOr([]);

    filters.add('subjectOrId', '**', [query]);

    if (rows.length > 0) {
      filters.add('id', '!', rows.map((wp:WorkPackageResource) => wp.id));
    }

    return this.halResourceService
      .get<WorkPackageCollectionResource>(path.filtered(filters))
      .pipe(
        map(collection => collection.elements),
        catchError((error:unknown) => {
          this.wpNotificationsService.handleRawError(error);
          return of([]);
        }),
        tap(() => this.isLoading = false)
      );
  }
}

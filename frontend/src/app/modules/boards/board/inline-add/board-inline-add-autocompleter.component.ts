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

import {
  AfterContentInit,
  ChangeDetectorRef,
  Component,
  EventEmitter,
  Input,
  Output,
  ViewChild,
  ViewEncapsulation
} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {Observable, of, Subject} from "rxjs";
import {catchError, debounceTime, distinctUntilChanged, map, switchMap, tap} from "rxjs/operators";
import {WorkPackageNotificationService} from "core-components/wp-edit/wp-notification.service";
import {NgSelectComponent} from "@ng-select/ng-select";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {WorkPackageCollectionResource} from "core-app/modules/hal/resources/wp-collection-resource";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {ApiV3FilterBuilder} from "core-components/api/api-v3/api-v3-filter-builder";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {SchemaCacheService} from "core-components/schemas/schema-cache.service";

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

  @Input() appendToContainer:string = '.board--container';
  @ViewChild(NgSelectComponent) public ngSelectComponent:NgSelectComponent;

  @Output() onCancel = new EventEmitter<undefined>();
  @Output() onReferenced = new EventEmitter<WorkPackageResource>();

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

  constructor(private readonly querySpace:IsolatedQuerySpace,
              private readonly pathHelper:PathHelperService,
              private readonly wpNotificationsService:WorkPackageNotificationService,
              private readonly CurrentProject:CurrentProjectService,
              private readonly halResourceService:HalResourceService,
              private readonly schemaCacheService:SchemaCacheService,
              private readonly cdRef:ChangeDetectorRef,
              private readonly I18n:I18nService) {
  }

  ngAfterContentInit():void {
    if (!this.ngSelectComponent) {
      return;
    }
    this.ngSelectComponent.open();

    setTimeout(() => {
      this.ngSelectComponent.focus();
    }, 25);
  }

  cancel() {
    this.onCancel.emit();
  }

  public addWorkPackageToQuery(workPackage?:WorkPackageResource) {
    if (workPackage) {
      this.schemaCacheService
        .ensureLoaded(workPackage)
        .then(() => {
          this.onReferenced.emit(workPackage);
          this.ngSelectComponent.close();
        });
    }
  }

  private autocompleteWorkPackages(query:string):Observable<WorkPackageResource[]> {
    // Return when the search string is empty
    if (query.length === 0) {
      this.isLoading = false;
      return of([]);
    }

    const path = this.pathHelper.api.v3.withOptionalProject(this.CurrentProject.id).work_packages;
    const filters:ApiV3FilterBuilder = new ApiV3FilterBuilder();
    const rows:WorkPackageResource[] = this.querySpace.rows.getValueOr([]);

    filters.add('subjectOrId', '**', [query]);

    if (rows.length > 0) {
      filters.add('id', '!', rows.map((wp:WorkPackageResource) => wp.id!));
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

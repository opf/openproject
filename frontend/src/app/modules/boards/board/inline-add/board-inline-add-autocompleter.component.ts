//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import {
  AfterViewInit,
  ChangeDetectorRef,
  Component,
  EventEmitter,
  Input,
  Output,
  ViewChild,
  ViewEncapsulation
} from '@angular/core';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { Observable, of, Subject } from "rxjs";
import { catchError, debounceTime, distinctUntilChanged, map, switchMap, tap } from "rxjs/operators";
import { NgSelectComponent } from "@ng-select/ng-select";
import { IsolatedQuerySpace } from "core-app/modules/work_packages/query-space/isolated-query-space";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { WorkPackageCollectionResource } from "core-app/modules/hal/resources/wp-collection-resource";
import { CurrentProjectService } from "core-components/projects/current-project.service";
import { ApiV3FilterBuilder } from "core-components/api/api-v3/api-v3-filter-builder";
import { HalResourceService } from "core-app/modules/hal/services/hal-resource.service";
import { SchemaCacheService } from "core-components/schemas/schema-cache.service";
import { WorkPackageCardDragAndDropService } from "core-components/wp-card-view/services/wp-card-drag-and-drop.service";
import { WorkPackageNotificationService } from "core-app/modules/work_packages/notifications/work-package-notification.service";
import { UrlParamsHelperService } from "core-components/wp-query/url-params-helper";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { OpAutocompleterComponent } from "core-app/modules/autocompleter/op-autocompleter/op-autocompleter.component";
import { QueryFilterResource } from 'core-app/modules/hal/resources/query-filter-resource';

@Component({
  selector: 'board-inline-add-autocompleter',
  templateUrl: './board-inline-add-autocompleter.html',

  // Allow styling the embedded ng-select
  encapsulation: ViewEncapsulation.None,
  styleUrls: ['./board-inline-add-autocompleter.sass']
})

export class BoardInlineAddAutocompleterComponent implements AfterViewInit {

  readonly text = {
    placeholder: this.I18n.t('js.relations_autocomplete.placeholder')
  };

  // Whether we're currently loading
  public isLoading = false;

  getAutocompleterData = (searchString:string):Observable<WorkPackageResource[]> =>
  {
    // Return when the search string is empty
    if (searchString.length === 0) {
      this.isLoading = false;
      return of([]);
    }

    const filters:ApiV3FilterBuilder = new ApiV3FilterBuilder();
    const results = this.querySpace.results.value;

    filters.add('subjectOrId', '**', [searchString]);

    if (results && results.elements.length > 0) {
      filters.add('id', '!', results.elements.map((wp:WorkPackageResource) => wp.id!));
    }
    // Add the subproject filter, if any
    const query = this.querySpace.query.value;
    if (query?.filters) {
      const currentFilters = this.urlParamsHelper.buildV3GetFilters(query.filters);
      filters.merge(currentFilters, 'subprojectId');
    }

    return this
      .apiV3Service
      .withOptionalProject(this.CurrentProject.id)
      .work_packages
      .filtered(filters)
      .get()
      .pipe(
        map(collection => collection.elements),
        catchError((error:unknown) => {
          this.notificationService.handleRawError(error);
          return of([]);
        }),
        tap(() => this.isLoading = false)
      );
  }

  public autocompleterOptions = {
    filters: [],
    resource:'work_packages',
    searchKey:'subjectOrId',
    getOptionsFn: this.getAutocompleterData
  }

  @Input() appendToContainer = 'body';
  @ViewChild(OpAutocompleterComponent) public ngSelectComponent:OpAutocompleterComponent;

  @Output() onCancel = new EventEmitter<undefined>();
  @Output() onReferenced = new EventEmitter<WorkPackageResource>();

  
  constructor(private readonly querySpace:IsolatedQuerySpace,
              private readonly pathHelper:PathHelperService,
              private readonly apiV3Service:APIV3Service,
              private readonly urlParamsHelper:UrlParamsHelperService,
              private readonly notificationService:WorkPackageNotificationService,
              private readonly CurrentProject:CurrentProjectService,
              private readonly halResourceService:HalResourceService,
              private readonly schemaCacheService:SchemaCacheService,
              private readonly cdRef:ChangeDetectorRef,
              private readonly I18n:I18nService,
              private readonly wpCardDragDrop:WorkPackageCardDragAndDropService) {
  }

  ngAfterViewInit():void {
    if (!this.ngSelectComponent.ngSelectInstance) {
      return;
    }
    this.ngSelectComponent.ngSelectInstance.open();

    setTimeout(() => {
      this.ngSelectComponent.ngSelectInstance.focus();
    }, 25);

    this.wpCardDragDrop.removeReferenceWorkPackageForm();
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
          this.ngSelectComponent.ngSelectInstance.close();
        });
    }
  }

  public opened() {
    // Force reposition as a workaround for BUG
    // https://github.com/ng-select/ng-select/issues/1259
    setTimeout(() => {
      const component = this.ngSelectComponent.ngSelectInstance as any;
     
      if (component && component.dropdownPanel) {
        component.dropdownPanel._updatePosition();
      }
    }, 25);
  }
}

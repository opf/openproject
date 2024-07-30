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
  AfterViewInit,
  ChangeDetectorRef,
  Component,
  EventEmitter,
  Input,
  Output,
  ViewChild,
  ViewEncapsulation,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { Observable, of } from 'rxjs';
import { catchError, map, tap } from 'rxjs/operators';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { WorkPackageCardDragAndDropService } from 'core-app/features/work-packages/components/wp-card-view/services/wp-card-drag-and-drop.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { UrlParamsHelperService } from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { OpAutocompleterComponent } from 'core-app/shared/components/autocompleter/op-autocompleter/op-autocompleter.component';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';

@Component({
  selector: 'board-inline-add-autocompleter',
  templateUrl: './board-inline-add-autocompleter.html',

  // Allow styling the embedded ng-select
  encapsulation: ViewEncapsulation.None,
  styleUrls: ['./board-inline-add-autocompleter.sass'],
})

export class BoardInlineAddAutocompleterComponent implements AfterViewInit {
  readonly text = {
    placeholder: this.I18n.t('js.relations_autocomplete.placeholder'),
  };

  getAutocompleterData = (searchString:string):Observable<WorkPackageResource[]> => {
    // Return when the search string is empty
    if (searchString.length === 0) {
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
        map((collection) => collection.elements),
        catchError((error:unknown) => {
          this.notificationService.handleRawError(error);
          return of([]);
        }),
      );
  };

  public autocompleterOptions = {
    resource: 'work_packages',
    getOptionsFn: this.getAutocompleterData,
  };

  @Input() appendToContainer = 'body';

  @ViewChild(OpAutocompleterComponent) public ngSelectComponent:OpAutocompleterComponent;

  @Output() onCancel = new EventEmitter<undefined>();

  @Output() onReferenced = new EventEmitter<WorkPackageResource>();

  constructor(private readonly querySpace:IsolatedQuerySpace,
    private readonly pathHelper:PathHelperService,
    private readonly apiV3Service:ApiV3Service,
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
    this.ngSelectComponent.openSelect();
    this.ngSelectComponent.focusSelect();
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
          this.ngSelectComponent.closeSelect();
        });
    }
  }
}

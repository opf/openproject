//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
  AfterContentInit,
  ChangeDetectorRef,
  Component,
  EventEmitter, HostListener,
  Input,
  Output,
  ViewChild,
  ViewEncapsulation
} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {from, Observable, of, Subject} from "rxjs";
import {catchError, debounceTime, distinctUntilChanged, map, switchMap, tap} from "rxjs/operators";
import {NgSelectComponent} from "@ng-select/ng-select";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {WorkPackageCollectionResource} from "core-app/modules/hal/resources/wp-collection-resource";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {ApiV3Filter} from "core-components/api/api-v3/api-v3-filter-builder";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {SchemaCacheService} from "core-components/schemas/schema-cache.service";
import {WorkPackageNotificationService} from "core-app/modules/work_packages/notifications/work-package-notification.service";

@Component({
  selector: 'wp-relations-autocomplete',
  templateUrl: './wp-relations-autocomplete.html',

  // Allow styling the embedded ng-select
  encapsulation: ViewEncapsulation.None,
  styleUrls: ['./wp-relations-autocomplete.sass']
})
export class WorkPackageRelationsAutocomplete implements AfterContentInit {
  readonly text = {
    placeholder: this.I18n.t('js.relations_autocomplete.placeholder')
  };

  @Input() inputPlaceholder:string = this.text.placeholder;
  @Input() workPackage:WorkPackageResource;
  @Input() selectedRelationType:string;
  @Input() filterCandidatesFor:string;

  /** Do we take the current query filters into account? */
  @Input() additionalFilters:ApiV3Filter[] = [];

  @Input() hiddenOverflowContainer:string = 'body';
  @ViewChild(NgSelectComponent, { static: true }) public ngSelectComponent:NgSelectComponent;

  @Output() onCancel = new EventEmitter<undefined>();
  @Output() onSelected = new EventEmitter<WorkPackageResource>();
  @Output() onEmptySelected = new EventEmitter<undefined>();

  // Whether we're currently loading
  public isLoading = false;

  // Search input from ng-select
  public searchInput$ = new Subject<string>();

  public appendToContainer = 'body';

  // Search results mapped to input
  public results$:Observable<WorkPackageResource[]> = this.searchInput$.pipe(
    debounceTime(250),
    distinctUntilChanged(),
    tap(() => this.isLoading = true),
    switchMap(queryString => this.autocompleteWorkPackages(queryString))
  );

  constructor(private readonly querySpace:IsolatedQuerySpace,
              private readonly pathHelper:PathHelperService,
              private readonly notificationService:WorkPackageNotificationService,
              private readonly CurrentProject:CurrentProjectService,
              private readonly halResourceService:HalResourceService,
              private readonly schemaCacheService:SchemaCacheService,
              private readonly cdRef:ChangeDetectorRef,
              private readonly I18n:I18nService) {
  }

  @HostListener('keydown.escape')
  public reset() {
    this.cancel();
  }

  ngAfterContentInit():void {
    if (!this.ngSelectComponent) {
      return;
    }

    setTimeout(() => {
      this.ngSelectComponent.focus();
    }, 25);
  }

  cancel() {
    this.onCancel.emit();
  }

  public onWorkPackageSelected(workPackage?:WorkPackageResource) {
    if (workPackage) {
      this.schemaCacheService
        .ensureLoaded(workPackage)
        .then(() => {
          this.onSelected.emit(workPackage);
          this.ngSelectComponent.close();
        });
    }
  }

  private autocompleteWorkPackages(query:string):Observable<WorkPackageResource[]> {
    // Return when the search string is empty
    if (query === null || query.length === 0) {
      this.isLoading = false;
      return of([]);
    }

    // Remove prefix # from search
    query = query.replace(/^#/, '');

    return from(
      this.workPackage.availableRelationCandidates.$link.$fetch({
        query: query,
        filters: JSON.stringify(this.additionalFilters),
        type: this.filterCandidatesFor || this.selectedRelationType
      }) as Promise<WorkPackageCollectionResource>
    )
    .pipe(
        map(collection => collection.elements),
        catchError((error:unknown) => {
          this.notificationService.handleRawError(error);
          return of([]);
        }),
        tap(() => this.isLoading = false)
      );
  }

  onOpen() {
    // Force reposition as a workaround for BUG
    // https://github.com/ng-select/ng-select/issues/1259
    setTimeout(() => {
      const component = (this.ngSelectComponent) as any;
      if (component && component.dropdownPanel) {
        component.dropdownPanel._updatePosition();
      }

      jQuery(this.hiddenOverflowContainer).one('scroll', () => {
        this.ngSelectComponent.close();
      });
    }, 25);

  }
}

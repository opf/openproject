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

import { ChangeDetectionStrategy, Component, HostListener, Input } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { from, Observable, of } from 'rxjs';
import { catchError, map } from 'rxjs/operators';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import {
  OpAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/op-autocompleter/op-autocompleter.component';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { ApiV3Filter, ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import {
  WorkPackageNotificationService,
} from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';

export interface IWorkPackageAutocompleteItem extends WorkPackageResource {
  id:string,
}

@Component({
  selector: 'wp-relations-autocomplete',
  templateUrl: '../../../../../../shared/components/autocompleter/op-autocompleter/op-autocompleter.component.html',
  styleUrls: ['../../../../../../shared/components/autocompleter/op-autocompleter/op-autocompleter.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WorkPackageRelationsAutocompleteComponent extends OpAutocompleterComponent<IWorkPackageAutocompleteItem> {
  @Input() workPackage:WorkPackageResource;

  @Input() selectedRelationType:string;

  @Input() filterCandidatesFor:string;

  @Input() hiddenOverflowContainer = 'body';

  @InjectField(WorkPackageNotificationService) notificationService:WorkPackageNotificationService;

  @InjectField(SchemaCacheService) schemaCacheService:SchemaCacheService;

  resource:TOpAutocompleterResource = 'work_packages';

  appendTo = 'body';

  placeholder = this.I18n.t('js.relations_autocomplete.placeholder');

  getOptionsFn = this.getAutocompleterData.bind(this);

  @HostListener('keydown.escape')
  public reset() {
    this.cancel.emit();
  }

  changed(workPackage:IWorkPackageAutocompleteItem|null) {
    if (workPackage) {
      void this.schemaCacheService
        .ensureLoaded(workPackage)
        .then(() => {
          this.change.emit(workPackage);
          this.ngSelectInstance.close();
        });
    }
  }

  opened() {
    // Force reposition as a workaround for BUG
    // https://github.com/ng-select/ng-select/issues/1259
    this.ngZone.runOutsideAngular(() => {
      setTimeout(() => {
        this.ngSelectInstance.dropdownPanel.adjustPosition();
        jQuery(this.hiddenOverflowContainer).one('scroll', () => {
          this.ngSelectInstance.close();
        });
      }, 25);
    });
  }

  getAutocompleterData(query:string|null):Observable<HalResource[]> {
    // Return when the search string is empty
    if (query === null || query.length === 0) {
      return of([]);
    }

    return from(
      this.workPackage.availableRelationCandidates.$link.$fetch({
        query,
        filters: JSON.stringify(this.createFilters()),
        type: this.filterCandidatesFor || this.selectedRelationType,
        sortBy: JSON.stringify([['updatedAt', 'desc']]),
      }) as Promise<WorkPackageCollectionResource>,
    )
      .pipe(
        map((collection) => collection.elements),
        catchError((error:unknown) => {
          this.notificationService.handleRawError(error);
          return of([]);
        }),
      );
  }

  private createFilters():ApiV3Filter[] {
    const finalFilters = new ApiV3FilterBuilder();

    if (this.filters) {
      this.filters.forEach((filter) => {
        finalFilters.add(filter.name, filter.operator, filter.values);
      });
    }

    return finalFilters.filters;
  }
}

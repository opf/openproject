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

import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnInit, Output, ViewChild, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResourceSortingService } from 'core-app/features/hal/services/hal-resource-sorting.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { NgSelectComponent } from '@ng-select/ng-select';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { compareByHref } from 'core-app/shared/helpers/angular/tracking-functions';

@Component({
  selector: 'op-filter-toggled-multiselect-value',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './filter-toggled-multiselect-value.component.html',
  standalone: false,
})
export class FilterToggledMultiselectValueComponent implements OnInit, AfterViewInit {
  readonly halResourceService = inject(HalResourceService);
  readonly halSorting = inject(HalResourceSortingService);
  readonly PathHelper = inject(PathHelperService);
  readonly apiV3Service = inject(ApiV3Service);
  readonly currentUser = inject(CurrentUserService);
  readonly cdRef = inject(ChangeDetectorRef);
  readonly I18n = inject(I18nService);

  @Input() public shouldFocus = false;

  @Input() public filter:QueryFilterInstanceResource;

  @Output() public filterChanged = new EventEmitter<QueryFilterInstanceResource>();

  @ViewChild('ngSelectInstance', { static: true }) ngSelectInstance:NgSelectComponent;

  public availableOptions:HalResource[] = [];

  itemTracker = (item:HalResource):string => item.href || item.id || item.name;

  compareByHref = compareByHref;

  readonly text = {
    placeholder: this.I18n.t('js.placeholders.selection'),
  };

  ngOnInit():void {
    const values = (this.filter.currentSchema!.values!.allowedValues as HalResource[]);
    this.availableOptions = this.halSorting.sort(values);
  }

  ngAfterViewInit():void {
    if (this.ngSelectInstance && this.shouldFocus) {
      this.ngSelectInstance.focus();
    }
  }

  public get value():unknown[] {
    return this.filter.values;
  }

  public setValues(val:HalResource[]|string[]|string|HalResource):void {
    this.filter.values = _.castArray(val) as HalResource[]|string[];
    this.filterChanged.emit(this.filter);
    this.cdRef.detectChanges();
  }
}

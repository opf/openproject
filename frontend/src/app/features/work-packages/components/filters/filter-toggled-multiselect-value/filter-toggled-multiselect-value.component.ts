// -- copyright
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import {
  AfterViewInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  EventEmitter,
  Input,
  OnInit,
  Output,
  ViewChild,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { compareByHrefOrString } from 'core-app/shared/helpers/angular/tracking-functions';
import { HalResourceSortingService } from 'core-app/features/hal/services/hal-resource-sorting.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { NgSelectComponent } from '@ng-select/ng-select';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';

@Component({
  selector: 'filter-toggled-multiselect-value',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './filter-toggled-multiselect-value.component.html',
})
export class FilterToggledMultiselectValueComponent implements OnInit, AfterViewInit {
  @Input() public shouldFocus = false;

  @Input() public filter:QueryFilterInstanceResource;

  @Output() public filterChanged = new EventEmitter<QueryFilterInstanceResource>();

  @ViewChild('ngSelectInstance', { static: true }) ngSelectInstance:NgSelectComponent;

  public _availableOptions:HalResource[] = [];

  public compareByHrefOrString = compareByHrefOrString;

  private _isEmpty:boolean;

  readonly text = {
    placeholder: this.I18n.t('js.placeholders.selection'),
  };

  constructor(readonly halResourceService:HalResourceService,
    readonly halSorting:HalResourceSortingService,
    readonly PathHelper:PathHelperService,
    readonly apiV3Service:ApiV3Service,
    readonly currentUser:CurrentUserService,
    readonly cdRef:ChangeDetectorRef,
    readonly I18n:I18nService) {
  }

  ngOnInit():void {
    this.availableOptions = (this.filter.currentSchema!.values!.allowedValues as HalResource[]);
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

  public get availableOptions():HalResource[] {
    return this._availableOptions;
  }

  public set availableOptions(val:HalResource[]) {
    this._availableOptions = this.halSorting.sort(val);
  }

  public get isEmpty():boolean {
    return this._isEmpty = this.value.length === 0;
  }

  public repositionDropdown() {
    if (this.ngSelectInstance) {
      setTimeout(() => {
        const component = (this.ngSelectInstance) as any;
        if (component && component.dropdownPanel) {
          component.dropdownPanel._updatePosition();
        }
      }, 25);
    }
  }
}

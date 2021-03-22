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

import { HalResource } from 'core-app/modules/hal/resources/hal-resource';
import { UserResource } from 'core-app/modules/hal/resources/user-resource';
import { CollectionResource } from 'core-app/modules/hal/resources/collection-resource';
import { RootResource } from 'core-app/modules/hal/resources/root-resource';
import { QueryFilterInstanceResource } from 'core-app/modules/hal/resources/query-filter-instance-resource';
import {
  AfterViewInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  EventEmitter,
  Input,
  OnInit,
  Output,
  ViewChild
} from '@angular/core';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { AngularTrackingHelpers } from 'core-components/angular/tracking-functions';
import { HalResourceService } from 'core-app/modules/hal/services/hal-resource.service';
import { HalResourceSortingService } from "core-app/modules/hal/services/hal-resource-sorting.service";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { NgSelectComponent } from "@ng-select/ng-select";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { CurrentUserService } from "core-components/user/current-user.service";

@Component({
  selector: 'filter-toggled-multiselect-value',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './filter-toggled-multiselect-value.component.html'
})
export class FilterToggledMultiselectValueComponent implements OnInit, AfterViewInit {
  @Input() public shouldFocus = false;
  @Input() public filter:QueryFilterInstanceResource;
  @Output() public filterChanged = new EventEmitter<QueryFilterInstanceResource>();

  @ViewChild('ngSelectInstance', { static: true }) ngSelectInstance:NgSelectComponent;

  public _availableOptions:HalResource[] = [];
  public compareByHrefOrString = AngularTrackingHelpers.compareByHrefOrString;

  private _isEmpty:boolean;

  readonly text = {
    placeholder: this.I18n.t('js.placeholders.selection'),
  };

  constructor(readonly halResourceService:HalResourceService,
              readonly halSorting:HalResourceSortingService,
              readonly PathHelper:PathHelperService,
              readonly apiV3Service:APIV3Service,
              readonly currentUser:CurrentUserService,
              readonly cdRef:ChangeDetectorRef,
              readonly I18n:I18nService) {
  }

  ngOnInit() {
    this.fetchAllowedValues();
  }

  ngAfterViewInit():void {
    if (this.ngSelectInstance && this.shouldFocus) {
      this.ngSelectInstance.focus();
    }
  }

  public get value() {
    return this.filter.values;
  }

  public setValues(val:any) {
    this.filter.values = _.castArray(val);
    this.filterChanged.emit(this.filter);
    this.cdRef.detectChanges();
  }

  public get availableOptions() {
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

  private get isUserResource() {
    const type = _.get(this.filter.currentSchema, 'values.type', null);
    return type && type.indexOf('User') > 0;
  }

  private fetchAllowedValues() {
    if ((this.filter.currentSchema!.values!.allowedValues as CollectionResource)['$load']) {
      this.loadAllowedValues();
    } else {
      this.availableOptions = (this.filter.currentSchema!.values!.allowedValues as HalResource[]);
    }
  }

  private loadAllowedValues() {
    const valuesSchema = this.filter.currentSchema!.values!;
    const loadingPromises = [(valuesSchema.allowedValues as any).$load()];

    // If it is a User resource, we want to have the 'me' option.
    // We therefore fetch the current user from the api and copy
    // the current user's value from the set of allowedValues. The
    // copy will have it's name altered to 'me' and will then be
    // prepended to the list.
    if (this.isUserResource) {
      loadingPromises.push(this.apiV3Service.root.get().toPromise());
    }

    Promise.all(loadingPromises)
      .then(((resources:Array<HalResource>) => {
        const options = (resources[0] as CollectionResource).elements;

        this.availableOptions = options;

        if (this.isUserResource && this.filter.filter.id !== 'memberOfGroup') {
          this.addMeValue((resources[1] as RootResource).user);
        }
      }));
  }

  private addMeValue(currentUser:UserResource) {
    if (!(currentUser && currentUser.$href)) {
      return;
    }

    const me:HalResource = this.halResourceService.createHalResource(
      {
        _links: {
          self: {
            href: this.apiV3Service.users.me,
            title: this.I18n.t('js.label_me')
          }
        }
      }, true
    );

    this._availableOptions.unshift(me);
  }
}

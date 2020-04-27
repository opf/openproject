// -- copyright
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
// ++

import {Component, ElementRef, EventEmitter, Injector, Input, OnInit, Output, ViewChild} from '@angular/core';
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {ApiV3FilterBuilder, FilterOperator} from "core-components/api/api-v3/api-v3-filter-builder";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {Observable} from "rxjs";
import {map} from "rxjs/operators";
import {DebouncedRequestSwitchmap, errorNotificationHandler} from "core-app/helpers/rxjs/debounced-input-switchmap";
import {HalResourceNotificationService} from "core-app/modules/hal/services/hal-resource-notification.service";
import {NgSelectComponent} from "@ng-select/ng-select";
import {UserResource} from "core-app/modules/hal/resources/user-resource";

export const usersAutocompleterSelector = 'user-autocompleter';

@Component({
  templateUrl: './user-autocompleter.component.html',
  selector: usersAutocompleterSelector
})
export class UserAutocompleterComponent implements OnInit {
  userTracker = (item:any) => item.href || item.id;

  @ViewChild(NgSelectComponent, { static: true }) public ngSelectComponent:NgSelectComponent;
  @Output() public onChange = new EventEmitter<void>();
  @Input() public clearAfterSelection:boolean = false;

  // Load all users as default
  @Input() public url:string = this.pathHelper.api.v3.users.path;
  @Input() public allowEmpty:boolean = false;
  @Input() public appendTo:string = '';
  @Input() public multiple:boolean = false;

  @Input() public initialSelection:number|null = null;

  // Update an input field after changing, used when externally loaded
  private updateInputField:HTMLInputElement|undefined;

  /** Keep a switchmap for search term and loading state */
  public requests = new DebouncedRequestSwitchmap<string, {[key:string]:string|null}>(
    (searchTerm:string) => this.getAvailableUsers(this.url, searchTerm),
    errorNotificationHandler(this.halNotification)
  );

  public inputFilters:ApiV3FilterBuilder = new ApiV3FilterBuilder();

  constructor(protected elementRef:ElementRef,
              protected halResourceService:HalResourceService,
              protected I18n:I18nService,
              protected halNotification:HalResourceNotificationService,
              readonly pathHelper:PathHelperService,
              readonly injector:Injector) {
  }

  ngOnInit() {
    const input = this.elementRef.nativeElement.dataset['updateInput'];
    const allowEmpty = this.elementRef.nativeElement.dataset['allowEmpty'];
    const appendTo = this.elementRef.nativeElement.dataset['appendTo'];
    const multiple = this.elementRef.nativeElement.dataset['multiple'];
    const url = this.elementRef.nativeElement.dataset['url'];

    if (input) {
      this.updateInputField = document.getElementsByName(input)[0] as HTMLInputElement|undefined;
      this.setInitialSelection();
    }

    let filterInput  = this.elementRef.nativeElement.dataset['additionalFilter'];
    if (filterInput) {
      JSON.parse(filterInput).forEach((filter:{selector:string; operator:FilterOperator, values:string[]}) => {
        this.inputFilters.add(filter['selector'], filter['operator'], filter['values']);
      });
    }

    if (allowEmpty === 'true') {
      this.allowEmpty = true;
    }

    if (appendTo) {
      this.appendTo = appendTo;
    }

    if (multiple === 'true') {
      this.multiple = true;
    }

    if (url) {
      this.url = url;
    }
  }

  public onFocus() {
    if (!this.requests.lastRequestedValue) {
      this.requests.input$.next('');
    }
  }

  public onModelChange(user:any) {
    if (user) {
      this.onChange.emit(user);
      this.requests.input$.next('');

      if (this.clearAfterSelection) {
        this.ngSelectComponent.clearItem(user);
      }

      if (this.updateInputField) {
        if (this.multiple) {
          this.updateInputField.value = user.map((u:UserResource) => u.id);
        } else {
          this.updateInputField.value = user.id;
        }
      }
    }
  }

  protected getAvailableUsers(url:string, searchTerm:any):Observable<{[key:string]:string|null}[]> {
    // Need to clone the filters to not add additional filters on every
    // search term being processed.
    let searchFilters = this.inputFilters.clone();

    if (searchTerm && searchTerm.length) {
      searchFilters.add('name', '~', [searchTerm]);
    }

    return this.halResourceService
      .get(url, { filters: searchFilters.toJson() })
      .pipe(
        map(res => {
          let options = res.elements.map((el:any) => {
            return {name: el.name, id: el.id, href: el.href, avatar: el.avatar};
          });

          if (this.allowEmpty) {
            options.unshift({name: this.I18n.t('js.timelines.filter.noneSelection'), href: null, id: null});
          }

          return options;
        })
      );
  }

  private setInitialSelection() {
    if (this.updateInputField) {
      const id = parseInt(this.updateInputField.value);
      this.initialSelection = isNaN(id) ? null : id;
    }
  }
}


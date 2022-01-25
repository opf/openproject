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

import {
  Component, ElementRef, EventEmitter, Injector, Input, OnInit, Output, ViewChild,
} from '@angular/core';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import {
  DebouncedRequestSwitchmap,
  errorNotificationHandler,
} from 'core-app/shared/helpers/rxjs/debounced-input-switchmap';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { NgSelectComponent } from '@ng-select/ng-select';
import { UserResource } from 'core-app/features/hal/resources/user-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3FilterBuilder, FilterOperator } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';

export const usersAutocompleterSelector = 'user-autocompleter';

export interface IUserAutocompleteItem {
  name:string;
  id:string|null;
  href:string|null;
  avatar:string|null;
}

@Component({
  templateUrl: './user-autocompleter.component.html',
  selector: usersAutocompleterSelector,
})
export class UserAutocompleterComponent implements OnInit {
  userTracker = (item:any) => item.href || item.id;

  @ViewChild(NgSelectComponent, { static: true }) public ngSelectComponent:NgSelectComponent;

  @Output() public onChange = new EventEmitter<IUserAutocompleteItem>();

  @Input() public clearAfterSelection = false;

  // Load all users as default
  @Input() public url:string = this.apiV3Service.users.path;

  @Input() public allowEmpty = false;

  @Input() public appendTo = '';

  @Input() public multiple = false;

  @Input() public initialSelection:number|null = null;

  // Update an input field after changing, used when externally loaded
  private updateInputField:HTMLInputElement|undefined;

  /** Keep a switchmap for search term and loading state */
  public requests = new DebouncedRequestSwitchmap<string, IUserAutocompleteItem>(
    (searchTerm:string) => this.getAvailableUsers(this.url, searchTerm),
    errorNotificationHandler(this.halNotification),
  );

  public inputFilters:ApiV3FilterBuilder = new ApiV3FilterBuilder();

  constructor(protected elementRef:ElementRef,
    protected halResourceService:HalResourceService,
    protected I18n:I18nService,
    protected halNotification:HalResourceNotificationService,
    readonly pathHelper:PathHelperService,
    readonly apiV3Service:ApiV3Service,
    readonly injector:Injector) {
  }

  ngOnInit() {
    const input = this.elementRef.nativeElement.dataset.updateInput;
    const { allowEmpty } = this.elementRef.nativeElement.dataset;
    const { appendTo } = this.elementRef.nativeElement.dataset;
    const { multiple } = this.elementRef.nativeElement.dataset;
    const { url } = this.elementRef.nativeElement.dataset;

    if (input) {
      this.updateInputField = document.getElementsByName(input)[0] as HTMLInputElement|undefined;
      this.setInitialSelection();
    }

    const filterInput = this.elementRef.nativeElement.dataset.additionalFilter;
    if (filterInput) {
      JSON.parse(filterInput).forEach((filter:{ selector:string; operator:FilterOperator, values:string[] }) => {
        this.inputFilters.add(filter.selector, filter.operator, filter.values);
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

  protected getAvailableUsers(url:string, searchTerm:any):Observable<IUserAutocompleteItem[]> {
    // Need to clone the filters to not add additional filters on every
    // search term being processed.
    const searchFilters = this.inputFilters.clone();

    if (searchTerm && searchTerm.length) {
      searchFilters.add('name', '~', [searchTerm]);
    }

    return this.halResourceService
      .get(url, { filters: searchFilters.toJson() })
      .pipe(
        map((res) => {
          const options = res.elements.map((el:any) => ({
            name: el.name, id: el.id, href: el.href, avatar: el.avatar,
          }));

          if (this.allowEmpty) {
            options.unshift({ name: this.I18n.t('js.timelines.filter.noneSelection'), href: null, id: null });
          }

          return options;
        }),
      );
  }

  private setInitialSelection() {
    if (this.updateInputField) {
      const id = parseInt(this.updateInputField.value);
      this.initialSelection = isNaN(id) ? null : id;
    }
  }
}

// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2023 the OpenProject GmbH
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
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  EventEmitter,
  forwardRef,
  Injector,
  Input,
  OnInit,
  Output,
  ViewChild,
} from '@angular/core';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { Observable } from 'rxjs';
import {
  filter,
  map,
} from 'rxjs/operators';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { NgSelectComponent } from '@ng-select/ng-select';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import {
  ApiV3FilterBuilder,
  FilterOperator,
} from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';
import {
  ControlValueAccessor,
  NG_VALUE_ACCESSOR,
} from '@angular/forms';
import { ID } from '@datorama/akita';
import { addFiltersToPath } from 'core-app/core/apiv3/helpers/add-filters-to-path';
import { OpInviteUserModalService } from 'core-app/features/invite-user-modal/invite-user-modal.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { UserResource } from 'core-app/features/hal/resources/user-resource';

export const usersAutocompleterSelector = 'op-user-autocompleter';

export interface IUserAutocompleteItem {
  id:ID;
  name:string;
  href:string|null;
  avatar:string|null;
}

@Component({
  templateUrl: './user-autocompleter.component.html',
  selector: usersAutocompleterSelector,
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => UserAutocompleterComponent),
      multi: true,
    },
    // Provide a new version of the modal invite service,
    // as otherwise the close event will be shared across all instances
    OpInviteUserModalService,
  ],
})
export class UserAutocompleterComponent extends UntilDestroyedMixin implements OnInit, ControlValueAccessor {
  userTracker = (item:{ href?:string, id:string }):string => item.href || item.id;

  @ViewChild(NgSelectComponent, { static: true }) public ngSelectComponent:NgSelectComponent;

  @Input() public clearAfterSelection = false;

  @Input() public name = '';

  // Load all users as default
  @Input() public url:string = this.apiV3Service.users.path;

  // ID that should be set on the input HTML element. It is used with
  // <label> tags that have `for=""` set
  @Input() public labelForId = '';

  @Input() public appendTo = '';

  @Input() public multiple = false;

  @Input() public openDirectly = false;

  @Input() public focusDirectly = false;

  // eslint-disable-next-line @angular-eslint/no-input-rename
  @Input('value') public _value:IUserAutocompleteItem|IUserAutocompleteItem[]|null = null;

  @Input() public inviteUserToProject:string|undefined;

  get value():IUserAutocompleteItem|IUserAutocompleteItem[]|null {
    return this._value;
  }

  set value(value:IUserAutocompleteItem|IUserAutocompleteItem[]|null) {
    this._value = value;
    this.onChange(value);
    this.valueChange.emit(value);
    this.onTouched(value);
    setTimeout(() => {
      this.hiddenInput.nativeElement?.dispatchEvent(new Event('change'));
    }, 100);
  }

  get plainValue():ID|ID[] {
    return (Array.isArray(this.value) ? this.value?.map((i) => i.id) : this.value?.id) || '';
  }

  @Input() public additionalFilters:{ selector:string; operator:FilterOperator, values:string[] }[] = [];

  public inputFilters:ApiV3FilterBuilder = new ApiV3FilterBuilder();

  @Output() public valueChange = new EventEmitter<IUserAutocompleteItem|IUserAutocompleteItem[]|null>();

  @Output() cancel = new EventEmitter();

  @Output() public userInvited = new EventEmitter<HalResource>();

  @ViewChild('hiddenInput') hiddenInput:ElementRef<HTMLElement>;

  constructor(
    public elementRef:ElementRef,
    protected halResourceService:HalResourceService,
    protected I18n:I18nService,
    protected halNotification:HalResourceNotificationService,
    readonly pathHelper:PathHelperService,
    readonly apiV3Service:ApiV3Service,
    readonly injector:Injector,
    readonly opInviteUserModalService:OpInviteUserModalService,
  ) {
    super();
    populateInputsFromDataset(this);
  }

  ngOnInit():void {
    // eslint-disable-next-line @typescript-eslint/no-shadow
    this.additionalFilters.forEach((filter) => this.inputFilters.add(filter.selector, filter.operator, filter.values));

    this.opInviteUserModalService.close
      .pipe(
        this.untilDestroyed(),
        filter((user) => !!user),
      )
      .subscribe((user:HalResource) => {
        this.userInvited.emit(user);
      });
  }

  public getAvailableUsers(searchTerm?:string):Observable<IUserAutocompleteItem[]> {
    // Need to clone the filters to not add additional filters on every
    // search term being processed.
    const searchFilters = this.inputFilters.clone();

    if (searchTerm?.length) {
      searchFilters.add('name', '~', [searchTerm]);
    }

    const filteredURL = addFiltersToPath(this.url, searchFilters);

    return this
      .halResourceService
      .get<CollectionResource<UserResource>>(filteredURL.toString(), { pageSize: -1 })
      .pipe(
        map((res) => res.elements.map((el) => ({
          name: el.name, id: el.id, href: el.href, avatar: el.avatar,
        })) as IUserAutocompleteItem[]),
      );
  }

  writeValue(value:IUserAutocompleteItem|null):void {
    this.value = value;
  }

  onChange = (_:IUserAutocompleteItem|IUserAutocompleteItem[]|null):void => {};

  onTouched = (_:IUserAutocompleteItem|IUserAutocompleteItem[]|null):void => {};

  registerOnChange(fn:(_:IUserAutocompleteItem|IUserAutocompleteItem[]|null) => void):void {
    this.onChange = fn;
  }

  registerOnTouched(fn:(_:IUserAutocompleteItem|IUserAutocompleteItem[]|null) => void):void {
    this.onTouched = fn;
  }
}

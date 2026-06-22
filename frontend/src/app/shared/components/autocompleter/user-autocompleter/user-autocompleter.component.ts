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

import { keyBy } from 'lodash-es';
import {
  ChangeDetectionStrategy,
  Component,
  EventEmitter,
  forwardRef,
  inject,
  Input,
  OnInit,
  Output,
  ViewEncapsulation,
} from '@angular/core';
import { Observable } from 'rxjs';
import { filter, map } from 'rxjs/operators';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';
import { ID } from '@datorama/akita';
import { OpInviteUserDialogService } from 'core-app/features/invite-user-modal/invite-user-dialog.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import {
  OpAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/op-autocompleter/op-autocompleter.component';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { addFiltersToPath } from 'core-app/core/apiv3/helpers/add-filters-to-path';
import {
  UserAutocompleterTemplateComponent,
} from 'core-app/shared/components/autocompleter/user-autocompleter/user-autocompleter-template.component';
import { IUser } from 'core-app/core/state/principals/user.model';
import { compareByAttribute } from 'core-app/shared/helpers/angular/tracking-functions';

export const usersAutocompleterSelector = 'op-user-autocompleter';

export interface IUserAutocompleteItem {
  id:ID;
  name:string;
  email?:string|null;
  href:string|null;
  avatar?:string|null;
}

@Component({
  templateUrl: '../op-autocompleter/op-autocompleter.component.html',
  selector: usersAutocompleterSelector,
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => UserAutocompleterComponent),
      multi: true,
    },
  ],
  styleUrls: ['./user-autocompleter.component.sass'],
  encapsulation: ViewEncapsulation.None,
  standalone: false,
})
export class UserAutocompleterComponent extends OpAutocompleterComponent<IUserAutocompleteItem> implements OnInit, ControlValueAccessor {
  @Input() public inviteUserToProject:string|undefined;

  @Input() public isOpenedInModal = false;
  @Input() public hoverCards = true;

  @Input() public url:string = this.apiV3Service.users.path;

  @Input() public additionalOptions:IUserAutocompleteItem[]|null = null;

  @Output() public userInvited = new EventEmitter<HalResource>();

  readonly opInviteUserDialogService = inject(OpInviteUserDialogService);

  getOptionsFn = this.getAvailableUsers.bind(this);

  ngOnInit():void {
    super.ngOnInit();

    this.applyTemplates(UserAutocompleterTemplateComponent, {
      inviteUserToProject: this.inviteUserToProject,
      isOpenedInModal: this.isOpenedInModal,
      hoverCards: this.hoverCards,
    });

    this
      .opInviteUserDialogService
      .close
      .pipe(
        this.untilDestroyed(),
        filter((user) => !!user),
      )
      .subscribe((user:HalResource) => {
        this.userInvited.emit(user);
      });
  }

  public getAvailableUsers(searchTerm?:string):Observable<IUserAutocompleteItem[]> {
    const filteredURL = this.buildFilteredURL(searchTerm);

    filteredURL.searchParams.set('pageSize', '-1');
    filteredURL.searchParams.set('select', 'elements/id,elements/name,elements/email,elements/self,total,count,pageSize');

    return this
      .http
      .get<IHALCollection<IUser>>(filteredURL.toString())
      .pipe(
        map((res) => _.uniqBy(res._embedded.elements, (el) => el._links.self?.href || el.id)),
        map((users) => {
          const mapped:IUserAutocompleteItem[] = users.map((user) => {
              return { id: user.id, name: user.name, href: user._links.self?.href, email: user.email };
          });

          if (this.additionalOptions) {
            return this.additionalOptions.concat(mapped);
          }

          return mapped;
          }),
      );
  }

  protected buildFilteredURL(searchTerm?:string):URL {
    const filterObject = keyBy(this.filters, 'name');
    const searchFilters = ApiV3FilterBuilder.fromFilterObject(filterObject);

    if (searchTerm?.length) {
      searchFilters.add(this.searchKey || 'name', '~', [searchTerm]);
    }

    return addFiltersToPath(this.url, searchFilters);
  }

  public addNewObjectFn(searchString:string):IUserAutocompleteItem {
    return {
      id: searchString,
      name: searchString,
      href: null,
      avatar: null,
    };
  }

  protected defaultTrackByFunction():(item:{ href:unknown, name:unknown }) => unknown {
    return (item) => item.href || item.name;
  }

  protected defaultCompareWithFunction():(a:unknown, b:unknown) => boolean {
    return compareByAttribute('href', 'name');
  }
}

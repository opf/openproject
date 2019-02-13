// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {Component, EventEmitter, Input, OnInit, Output, ViewChild} from '@angular/core';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {ApiV3FilterBuilder} from "core-components/api/api-v3/api-v3-filter-builder";
import {NgSelectComponent} from "@ng-select/ng-select/dist";

@Component({
  template: `
    <ng-select [items]="options"
               bindLabel="name"
               bindValue="id"
               [virtualScroll]="true"
               (search)="onSearch($event)"
               (change)="onModelChange($event)" >
      <ng-template ng-option-tmp let-item="item" let-index="index">
        <user-avatar [attr.data-user-id]="item.id"
                     data-class-list="avatar-mini">
        </user-avatar>
        {{ item.name }}
      </ng-template>
    </ng-select>
  `,
  selector: 'user-autocompleter'
})
export class UserAutocompleterComponent implements OnInit {
  @ViewChild(NgSelectComponent) public ngSelectComponent:NgSelectComponent;
  @Output() public onChange = new EventEmitter<void>();
  @Input() public clearAfterSelection:boolean = false;

  // Load all users as default
  @Input() public url:string = this.pathHelper.api.v3.users.path;

  public options:any[];

  constructor(protected halResourceService:HalResourceService,
              readonly pathHelper:PathHelperService) {
  }

  ngOnInit() {
    this.setAvailableUsers(this.url, '');
  }

  public onModelChange(user:any) {
    if (user) {
      this.onChange.emit(user);

      if (this.clearAfterSelection) {
        this.ngSelectComponent.clearItem(user);
      }
    }
  }

  public onSearch($event:any) {
    let urlQuery:any;
    if($event) {
      let filters = new ApiV3FilterBuilder();
      filters.add('name', '~', [$event]);
      urlQuery = { filters: filters.toJson() };
    }

    this.setAvailableUsers(this.url, urlQuery);
  }

  private setAvailableUsers(url:string, filters:any) {
    this.halResourceService.get(url, filters)
      .subscribe(res => {
        this.options = res.elements.map((el:any) => {
          return {name: el.name, id: el.id, href: el.href};
        });
      });
  }
}

DynamicBootstrapper.register({ selector: 'user-autocompleter', cls: UserAutocompleterComponent  });

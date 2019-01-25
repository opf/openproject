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

import {Component, ElementRef, OnInit} from '@angular/core';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";

@Component({
  template: `
    <ng-select [items]="options"
               bindLabel="name"
               bindValue="id"
               [virtualScroll]="true">
    </ng-select>
  `,
  selector: 'user-autocompleter'
})
export class UserAutocompleterComponent implements OnInit {
  public options:any[];
  public url:string;

  constructor(protected halResourceService:HalResourceService,
              readonly pathHelper:PathHelperService) {
  }

  ngOnInit() {
    this.url = this.pathHelper.api.v3.users.path;
    this.setAvailableUsers(this.url);
  }

  private setAvailableUsers(url:string) {
    this.halResourceService.get(url)
      .subscribe(res => {
        this.options = res.elements.map((el:any) => {
          return {name: el.name, id: el.id};
        });
      });
  }
}

DynamicBootstrapper.register({ selector: 'user-autocompleter', cls: UserAutocompleterComponent  });

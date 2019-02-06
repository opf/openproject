//-- copyright
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
//++

import {UserResource} from 'core-app/modules/hal/resources/user-resource';
import {Component, Input, OnInit} from "@angular/core";
import {UserCacheService} from "core-components/user/user-cache.service";

@Component({
  selector: 'user-avatar',
  templateUrl: './user-avatar.component.html'
})
export class UserAvatarComponent implements OnInit {
  @Input() public user:UserResource;
  @Input() public classes:string;

  public userInitials:string;
  public userAvatar:string;
  public userName:string;

  constructor(readonly userCacheService:UserCacheService,) {
  }

  public ngOnInit() {
    if(this.user) {
      this.userCacheService
        .require(this.user.idFromLink)
        .then((user:UserResource) => {
          this.userInitials = user.firstName.charAt(0).toUpperCase() + user.lastName.charAt(0).toUpperCase();
          this.userAvatar = user.avatar;
          this.userName = user.name;
        });
    }
  }
}

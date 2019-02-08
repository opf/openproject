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
import {AfterViewInit, ChangeDetectorRef, Component, ElementRef} from "@angular/core";
import {UserCacheService} from "core-components/user/user-cache.service";
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";

@Component({
  selector: 'user-avatar',
  templateUrl: './user-avatar.component.html'
})
export class UserAvatarComponent implements AfterViewInit {
  public $element:JQuery;
  public userInitials:string;
  public userAvatar:string;
  public userName:string;
  public colorCode:string;
  public userID:string;
  public classes:string;
  public useFallback:boolean;

  constructor(readonly userCacheService:UserCacheService,
              protected elementRef:ElementRef,
              protected ref:ChangeDetectorRef) {
  }

  public ngAfterViewInit() {
    this.$element = jQuery(this.elementRef.nativeElement);

    this.userID = this.$element.data('user-id')!;
    this.classes = this.$element.data('class-list')!;
    this.useFallback = this.$element.data('use-fallback')!;

    if (this.userID) {
      this.userCacheService
        .require(this.userID)
        .then((user:UserResource) => {
          this.userInitials = user.firstName.charAt(0).toUpperCase() + user.lastName.charAt(0).toUpperCase();
          this.userAvatar = user.avatar;
          this.userName = user.name;
          this.colorCode = this.computeColor(this.userInitials);
        });
    }
    this.ref.detectChanges();
  }

  public replaceWithDefault() {
    this.useFallback = true;
    this.ref.detectChanges();
  }

  public computeColor(initials:string) {
    let hash = 0;
    for (var i = 0; i < initials.length; i++) {
      hash = initials.charCodeAt(i) + ((hash << 5) - hash);
    }

    let h = hash % 360;

    return 'hsl('+ h +', 50%, 50%)';
  }
}

DynamicBootstrapper.register({ selector: 'user-avatar', cls: UserAvatarComponent  });

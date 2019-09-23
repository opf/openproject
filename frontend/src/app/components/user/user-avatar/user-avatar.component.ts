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
import {
  AfterViewInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Input,
  OnChanges,
  SimpleChanges
} from "@angular/core";
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";

@Component({
  selector: 'user-avatar',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './user-avatar.component.html'
})
export class UserAvatarComponent implements AfterViewInit {
  /** If coming from angular, pass a user resource if availabe */
  @Input() public user?:UserResource;

  public userInitials:string;
  public userName:string;
  public colorCode:string;
  public userId:string;
  public classes:string;
  public userAvatarUrl:string;

  public useFallback:boolean;

  constructor(protected elementRef:ElementRef,
              protected ref:ChangeDetectorRef,
              protected pathHelper:PathHelperService) {
  }

  public ngAfterViewInit() {
    this.initialize();
  }

  public replaceWithDefault() {
    this.useFallback = true;
    this.ref.detectChanges();
  }

  private initialize() {
    const element = this.elementRef.nativeElement;

    if (this.user) {
      this.userId = this.user.id!;
      this.userName = this.user.name;
    } else {
      this.userId = element.dataset.userId!;
      this.userName = element.dataset.userName!;
    }

    this.classes = element.dataset.classList!;
    this.useFallback = element.dataset.useFallback!;
    this.userAvatarUrl = this.pathHelper.api.v3.users.id(this.userId).avatar.toString();
    this.userInitials = this.getInitials(this.userName);
    this.colorCode = this.computeColor(this.userName);
    this.ref.detectChanges();
  }

  private getInitials(name:string) {
    var names = name.split(' '),
      initials = names[0].substring(0, 1).toUpperCase();

    if (names.length > 1) {
      initials += names[names.length - 1].substring(0, 1).toUpperCase();
    }

    return initials;
  }

  private computeColor(name:string) {
    let hash = 0;
    for (var i = 0; i < name.length; i++) {
      hash = name.charCodeAt(i) + ((hash << 5) - hash);
    }

    let h = hash % 360;

    return 'hsl(' + h + ', 50%, 50%)';
  }
}

DynamicBootstrapper.register({ selector: 'user-avatar', cls: UserAvatarComponent  });

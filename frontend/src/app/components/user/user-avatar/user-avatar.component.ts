//-- copyright
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
//++

import {UserResource} from 'core-app/modules/hal/resources/user-resource';
import {AfterViewInit, ChangeDetectionStrategy, Component, ElementRef, Input} from "@angular/core";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {UserAvatarRendererService} from "core-components/user/user-avatar/user-avatar-renderer.service";

export const userAvatarSelector = 'user-avatar';

@Component({
  selector: userAvatarSelector,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: ''
})
export class UserAvatarComponent implements AfterViewInit {
  /** If coming from angular, pass a user resource if available */
  @Input() public user?:UserResource;

  constructor(protected elementRef:ElementRef,
              protected avatarRenderer:UserAvatarRendererService,
              protected pathHelper:PathHelperService) {
  }

  public ngAfterViewInit() {
    const element = this.elementRef.nativeElement;
    let user = this.user || { name: element.dataset.userName!, id: element.dataset.userId };
    this.avatarRenderer.render(element, user, false, element.dataset.classList);
  }
}


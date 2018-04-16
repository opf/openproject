//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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

import {Component, Inject, Input} from '@angular/core';
import {UserResource} from 'core-app/modules/hal/resources/user-resource';
import {I18nToken, PathHelperToken} from 'core-app/angular4-transition-utils';
import {PathHelperService} from 'core-components/common/path-helper/path-helper.service';

@Component({
  selector: 'user-link',
  template: `
    <a [attr.href]="href"
       [attr.title]="label"
       [textContent]="user.name">
    </a>
  `
})
export class UserLinkComponent {
  @Input() user:UserResource;

  public href:string;
  public label:string;
  public name:string;

  constructor(@Inject(PathHelperToken) readonly pathHelper:PathHelperService,
              @Inject(I18nToken) readonly I18n:op.I18n) {
  }

  ngOnInit() {
    this.href = this.pathHelper.userPath(this.user.idFromLink);
    this.name = this.user.name;
    this.label = this.I18n.t('js.label_author', { author: this.name });
  }
}

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

import { ChangeDetectionStrategy, Component, Input, inject } from '@angular/core';
import { UserResource } from 'core-app/features/hal/resources/user-resource';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

@Component({
  selector: 'op-user-link',
  template: `
    @if (href) {
      <a
        data-hover-card-trigger-target="trigger"
        [attr.data-hover-card-url]="hoverCardUrl"
        [attr.href]="href"
        [attr.title]="label"
        [textContent]="name">
      </a>
    }
    @else {
      {{ name }}
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class UserLinkComponent {
  readonly I18n = inject(I18nService);
  readonly pathHelperService = inject(PathHelperService);

  @Input() user:UserResource;

  public get href() {
    return this.user && this.user.showUserPath;
  }

  public get name() {
    return this.user && this.user.name;
  }

  public get label() {
    return this.I18n.t('js.label_author', { user: this.name });
  }

  public get hoverCardUrl() {
    return this.user && this.user.id && this.pathHelperService.userHoverCardPath(this.user.id);
  }
}

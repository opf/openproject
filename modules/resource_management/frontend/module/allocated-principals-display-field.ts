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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  MultipleLinesUserFieldModule,
} from 'core-app/shared/components/fields/display/field-types/multiple-lines-user-display-field.module';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { UserResource } from 'core-app/features/hal/resources/user-resource';
import { URN_UNDISCLOSED } from 'core-app/core/apiv3/api-v3-urns';
import { html, render } from 'lit-html';
import { buildShowAllocationsButton, showAllocationsLink } from './show-allocations-button';

export class AllocatedPrincipalsDisplayField extends MultipleLinesUserFieldModule {
  @LazyInject() turboRequests:TurboRequestsService;

  protected renderValues(values:UserResource[], element:HTMLElement) {
    const link = showAllocationsLink(this.resource);
    const container = link ? buildShowAllocationsButton(link, this.turboRequests) : element;
    const undisclosed = values.find((value) => value.href === URN_UNDISCLOSED);

    this.principalRenderer.renderMultiple(
      container,
      values.filter((value) => value !== undisclosed),
      { hide: false, link: false },
      { hide: false, size: 'medium' },
      { isActivated: !link },
      true,
    );

    if (undisclosed) {
      container.appendChild(this.buildUndisclosedPrincipal(undisclosed.name));
    }

    if (link) {
      element.appendChild(container);
    }
  }

  private buildUndisclosedPrincipal(title:string):HTMLElement {
    const label = this.I18n.t('js.resource_management.hidden_user');
    const initials = label.split(' ').map((word) => word[0]).join('').slice(0, 2).toUpperCase();
    const host = document.createElement('div');

    render(html`
      <span class="op-principal op-principal--multi-line" title=${title}>
        <span class="op-principal--avatar op-avatar op-avatar_medium color-bg-emphasis" aria-hidden="true">${initials}</span>
        <span class="op-principal--name">${label}</span>
      </span>
    `, host);

    return host.firstElementChild as HTMLElement;
  }
}

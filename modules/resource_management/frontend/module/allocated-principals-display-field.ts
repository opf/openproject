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
import { buildShowAllocationsButton, showAllocationsLink } from './show-allocations-button';

export class AllocatedPrincipalsDisplayField extends MultipleLinesUserFieldModule {
  @LazyInject() turboRequests:TurboRequestsService;

  protected renderValues(values:UserResource[], element:HTMLElement) {
    const link = showAllocationsLink(this.resource);

    if (!link) {
      super.renderValues(values, element);
      return;
    }

    const button = buildShowAllocationsButton(link, this.turboRequests);
    this.principalRenderer.renderMultiple(
      button,
      values,
      { hide: false, link: false },
      { hide: false, size: 'medium' },
      { isActivated: false },
      true,
    );

    element.appendChild(button);
  }
}

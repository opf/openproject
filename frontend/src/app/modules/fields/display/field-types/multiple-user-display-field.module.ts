//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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

import { ResourcesDisplayField } from "./resources-display-field.module";
import { UserResource } from "core-app/modules/hal/resources/user-resource";
import { InjectField } from "core-app/helpers/angular/inject-field.decorator";
import { UserAvatarRendererService } from "core-components/user/user-avatar/user-avatar-renderer.service";
import { cssClassCustomOption } from "core-app/modules/fields/display/display-field.module";

export class MultipleUserFieldModule extends ResourcesDisplayField {
  @InjectField() avatarRenderer:UserAvatarRendererService;

  public render(element:HTMLElement, displayText:string):void {
    const names = this.value;
    element.innerHTML = '';
    element.setAttribute('title', names.join(', '));

    if (names.length === 0) {
      this.renderEmpty(element);
    } else {
      this.renderValues(this.attribute, element);
    }
  }

  /**
   * Renders at most the first two values, followed by a badge indicating
   * the total count.
   */
  protected renderValues(values:UserResource[], element:HTMLElement) {
    const content = document.createDocumentFragment();
    const divContainer = document.createElement('div');
    divContainer.classList.add(cssClassCustomOption);
    content.appendChild(divContainer);

    this.renderAbridgedValues(divContainer, values);

    if (values.length > 2) {
      const dots = document.createElement('span');
      dots.innerHTML = '... ';
      divContainer.appendChild(dots);

      const badge = this.optionDiv(values.length.toString(), 'badge', '-secondary');
      content.appendChild(badge);
    }

    element.appendChild(content);

  }

  public renderAbridgedValues(element:HTMLElement, values:UserResource[]) {
    const valueForDisplay = _.take(values, 2);
    this.avatarRenderer.renderMultiple(element, valueForDisplay);
  }
}

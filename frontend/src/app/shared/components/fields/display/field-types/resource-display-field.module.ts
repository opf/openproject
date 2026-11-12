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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { DisplayField } from 'core-app/shared/components/fields/display/display-field.module';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import {
  isUndisclosed,
  undisclosedValueNode,
} from 'core-app/shared/components/fields/display/field-types/undisclosed-value';

export class ResourceDisplayField extends DisplayField {
  public get value() {
    if (this.schema) {
      return (this.attribute as HalResource|null|undefined)?.name;
    }
    return null;
  }

  public render(element:HTMLElement, displayText:string, options:Record<string, unknown> = {}):void {
    if (isUndisclosed(this.attribute as HalResource|null|undefined)) {
      element.innerHTML = '';
      element.appendChild(undisclosedValueNode(displayText));
      return;
    }

    super.render(element, displayText, options);
  }
}

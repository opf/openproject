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

import { DisplayField } from 'core-app/shared/components/fields/display/display-field.module';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { displayTriggerLink } from 'core-app/shared/components/fields/display/display-field-renderer';

export class LinkDisplayField extends DisplayField {
  public render(element:HTMLElement, displayText:string):void {
    if (this.value === null || this.value === undefined || this.value === '') {
      element.textContent = this.placeholder;
      return;
    }

    const link = document.createElement('a');
    link.textContent = displayText;
    link.href = this.value as string;
    link.rel = 'noopener noreferrer';
    link.target = this.target;

    element.appendChild(link);

    this.appendEditLink(element);
  }

  private appendEditLink(element:HTMLElement) {
    if (this.resource.updateImmediately) {
      const editLink = document.createElement('a');
      editLink.classList.add('icon', 'icon-edit', displayTriggerLink);
      editLink.setAttribute('href', '#');

      element.appendChild(editLink);
    }
  }

  private get target():string {
    const origin = window.location.origin;

    try {
      const url = new URL(this.value as string, window.location.origin);
      if (origin !== url.origin) {
        return '_blank';
      }
    } catch (e) {
      debugLog('Failed to parse origin for URL %O: %O', this.value, e);
    }

    return '';
  }
}

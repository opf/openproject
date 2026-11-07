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
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { displayTriggerLink } from 'core-app/shared/components/fields/display/display-field-renderer';

export interface LinkDisplayPresentation {
  readonly href:string;
  readonly target:string;
  readonly editLabel:string|null;
}

export class LinkDisplayField extends DisplayField {
  public get linkPresentation():LinkDisplayPresentation|null {
    const href = this.value as string|null|undefined;
    if (href === null || href === undefined || href === '') return null;

    return {
      href,
      target: this.targetFor(href),
      editLabel: this.resource.updateImmediately ? this.I18n.t('js.button_edit') : null,
    };
  }

  public render(element:HTMLElement, displayText:string):void {
    const presentation = this.linkPresentation;
    if (presentation === null) {
      element.textContent = this.placeholder;
      return;
    }

    const link = document.createElement('a');
    link.textContent = displayText;
    link.href = presentation.href;
    link.rel = 'noopener noreferrer';
    link.target = presentation.target;

    element.appendChild(link);

    if (presentation.editLabel !== null) this.appendEditLink(element, presentation.editLabel);
  }

  private appendEditLink(element:HTMLElement, label:string) {
    const editLink = document.createElement('a');
    editLink.classList.add('icon', 'icon-edit', displayTriggerLink);
    editLink.setAttribute('href', '#');
    editLink.setAttribute('aria-label', label);

    element.appendChild(editLink);
  }

  private targetFor(href:string):string {
    const origin = window.location.origin;

    try {
      const url = new URL(href, origin);
      if (origin !== url.origin) {
        return '_blank';
      }
    } catch (e) {
      debugLog('Failed to parse origin for URL %O: %O', href, e);
    }

    return '';
  }
}

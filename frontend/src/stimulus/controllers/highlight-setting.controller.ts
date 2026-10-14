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

import { ApplicationController } from 'stimulus-use';

// The highlight parameter names a setting, a form field like `type[color_id]`
// or one of several inputs of a field like `role[permissions][]=edit_project`.
const HIGHLIGHT_PATTERN = /^([\w[\]]+)(?:=([\w-]+))?$/;

export default class HighlightSettingController extends ApplicationController {
  connect() {
    const url = new URL(window.location.href);
    const match = HIGHLIGHT_PATTERN.exec(url.searchParams.get('highlight') ?? '');
    if (!match) return;

    const containers = this.findContainers(match[1], match[2]);
    if (containers.length === 0) return;

    containers.forEach((container) => container.classList.add('op-setting--highlighted'));
    // Wait for controllers revealing parts of the page, e.g. the permissions of a role's type.
    setTimeout(() => {
      const visible = containers.find((container) => container.offsetParent !== null) ?? containers[0];
      visible.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }, 100);

    url.searchParams.delete('highlight');
    window.history.replaceState(window.history.state, '', url);
  }

  private findContainers(name:string, value:string|undefined):HTMLElement[] {
    const marked = document.querySelector<HTMLElement>(`[data-setting-name="${name}"]`);
    if (marked && !value) {
      return [marked.closest<HTMLElement>('.FormControl-checkbox-wrap, .FormControl') ?? marked];
    }

    const fields = this.findFields(name, value);
    if (fields.length > 1 && !value) {
      return [fields[0].closest<HTMLElement>('fieldset, .form--field') ?? fields[0]];
    }

    return fields.map((field) => field.closest<HTMLElement>('.FormControl-checkbox-wrap, .FormControl, .form--field') ?? field);
  }

  private findFields(name:string, value:string|undefined):HTMLElement[] {
    const valueSelector = value ? `[value="${value}"]` : '';
    const selectors = name.includes('[')
      ? [`[name="${name}"]`]
      : [`[name="settings[${name}]"]`, `[name^="settings[${name}]["]`];

    const fields = Array.from(document.querySelectorAll<HTMLElement>(
      selectors.map((selector) => `${selector}${valueSelector}`).join(', '),
    ));
    const visibleFields = fields.filter((field) => field.getAttribute('type') !== 'hidden');

    // Custom inputs like the color select keep their value in a hidden field.
    return visibleFields.length > 0 ? visibleFields : fields;
  }
}

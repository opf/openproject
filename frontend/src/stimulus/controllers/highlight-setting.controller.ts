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

import { ApplicationController } from 'stimulus-use';

export default class HighlightSettingController extends ApplicationController {
  connect() {
    const url = new URL(window.location.href);
    const name = url.searchParams.get('highlight');
    if (!name || !/^\w+$/.test(name)) return;

    const container = this.findContainer(name);
    if (!container) return;

    container.classList.add('op-setting--highlighted');
    setTimeout(() => container.scrollIntoView({ behavior: 'smooth', block: 'center' }), 25);

    url.searchParams.delete('highlight');
    window.history.replaceState(window.history.state, '', url);
  }

  private findContainer(name:string):HTMLElement|null {
    const marked = document.querySelector<HTMLElement>(`[data-setting-name="${name}"]`);
    if (marked) {
      return marked.closest<HTMLElement>('.FormControl-checkbox-wrap, .FormControl') ?? marked;
    }

    const fields = Array.from(document.querySelectorAll<HTMLElement>(
      `[name="settings[${name}]"]:not([type="hidden"]), [name^="settings[${name}]["]:not([type="hidden"])`,
    ));
    if (fields.length === 0) return null;

    if (fields.length > 1) {
      return fields[0].closest<HTMLElement>('fieldset, .form--field') ?? fields[0];
    }

    return fields[0].closest<HTMLElement>('.FormControl-checkbox-wrap, .FormControl, .form--field') ?? fields[0];
  }
}

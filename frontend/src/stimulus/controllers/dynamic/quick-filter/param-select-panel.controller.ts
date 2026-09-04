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

import { Controller } from '@hotwired/stimulus';
import { visit } from '@hotwired/turbo';
import type { SelectPanelElement } from '@primer/view-components/app/components/primer/alpha/select_panel_element';

/**
 * Drives a multi-select quick filter that lives in a plain array query parameter
 * rather than in the serialized filters of a Queries object.
 */
export default class ParamSelectPanelController extends Controller {
  static values = { param: String };

  declare paramValue:string;

  apply(event:Event) {
    // Stop the panel from updating its own label, since the page navigates anyway
    event.stopPropagation();

    const panel = this.element as HTMLElement as SelectPanelElement;
    const selectedIds = panel.items
      .filter((item) => panel.isItemChecked(item))
      .map((item) => item.getAttribute('data-item-id'))
      .filter((id):id is string => id !== null);

    visit(this.urlWith(selectedIds));
  }

  private urlWith(ids:string[]):string {
    const url = new URL(window.location.href);
    url.searchParams.delete(`${this.paramValue}[]`);
    ids.forEach((id) => url.searchParams.append(`${this.paramValue}[]`, id));

    return url.toString();
  }
}

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
import { useMutation } from 'stimulus-use';

export default class BorderBoxListController extends Controller<HTMLElement> {
  static targets = ['list', 'emptyStateTemplate'];

  declare readonly listTarget:HTMLElement;

  declare readonly emptyStateTemplateTarget:HTMLTemplateElement;

  connect():void {
    this.sync();
    useMutation(this, {
      element: this.listTarget,
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ['class', 'hidden'],
      dispatchEvent: false,
    });
  }

  mutate():void {
    this.sync();
  }

  sync():void {
    const rows = Array.from(this.listTarget.children) as HTMLElement[];
    // legacy generic-drag-and-drop contract: the marker value is exactly "true"
    const placeholder = rows.find((row) => row.getAttribute('data-empty-list-item') === 'true');
    // 'd-none'/[hidden] are this codebase's existing filtering idioms (e.g. quick-filter,
    // sortable-lists row hiding) — intentionally scoped to those, not a general visibility check.
    const visibleContent = rows.some((row) => row.getAttribute('data-empty-list-item') !== 'true'
      && !row.classList.contains('d-none') && !row.hidden);

    if (visibleContent) {
      placeholder?.remove();
    } else if (!placeholder) {
      const prototype = this.emptyStateTemplateTarget.content.firstElementChild;
      if (prototype) { this.listTarget.append(prototype.cloneNode(true)); }
    }
  }
}

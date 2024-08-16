/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { ApplicationController } from 'stimulus-use';

export default class TableHighlightingController extends ApplicationController {
  private thead:HTMLElement;
  private colgroup:HTMLElement;

  connect() {
    const thead = this.element.querySelector('thead');
    const colgroup = this.element.querySelector('colgroup');

    if (thead && colgroup) {
      this.thead = thead;
      this.colgroup = colgroup;

      this.thead.addEventListener('mouseover', this.hover);
      this.thead.addEventListener('mouseout', this.unhover);
    }
  }

  disconnect() {
    super.disconnect();

    if (this.thead && this.colgroup) {
      this.thead.removeEventListener('mouseover', this.hover);
      this.thead.removeEventListener('mouseout', this.unhover);
    }
  }

  private hover = (evt:MouseEvent) => {
    const col = this.getColumn(evt.target as HTMLElement);
    col?.classList.add('hover');
  };

  private unhover = (evt:MouseEvent) => {
    const col = this.getColumn(evt.target as HTMLElement);
    col?.classList.remove('hover');
  };

  private getColumn(target:HTMLElement):HTMLElement|null {
    const th = target.closest('th') as HTMLElement;
    const index = this.parentIndex(th);

    if (index === null) {
      return null;
    }
    const col = this.colgroup.children.item(index) as HTMLElement|null;

    if (!col || col.dataset.highlight === 'false') {
      return null;
    }

    return col;
  }

  private parentIndex(element:HTMLElement):number|null {
    if (element.parentElement) {
      return Array.from(element.parentElement.children).indexOf(element);
    }

    return null;
  }
}

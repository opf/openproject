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

import { html } from 'lit-html';
import type { TemplateResult } from 'lit-html';
import { popoverMessage } from 'core-app/shared/components/anchored-popover/popover-message';
import type { CaretPlacement } from 'core-app/shared/components/anchored-popover/caret-placement';

export interface PopoverRow {
  label:string;
  value:string;
}

export function timeEntryPopoverHtml(
  popoverId:string,
  anchorId:string,
  rows:PopoverRow[],
  caret:CaretPlacement|null,
):TemplateResult {
  const list = html`
    <ul class="list-style-none ml-0">
      ${rows.map((row) => html`
        <li class="te-calendar--popover-entry">
          <span class="text-bold">${row.label}:</span>
          <span>${row.value}</span>
        </li>
      `)}
    </ul>
  `;

  return html`
    <anchored-position
      id=${popoverId}
      class="op-anchored-popover--host te-calendar--popover"
      role="dialog"
      align="start"
      anchor=${anchorId}
      anchor-offset="spacious"
      popover="hint"
      side="outside-right">
      ${popoverMessage(list, caret)}
    </anchored-position>
  `;
}

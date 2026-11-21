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

import { resolveItemId, sortableScopeCountAttribute, sortableScopeIdsAttribute } from './list-dom';

const SINGULAR_COUNT = 1;

function parseIds(raw:string|null):string[]|null {
  if (!raw) return null;

  try {
    const parsed:unknown = JSON.parse(raw);
    return Array.isArray(parsed) && parsed.every((entry):entry is string => typeof entry === 'string') ? parsed : null;
  } catch {
    return null;
  }
}

/**
 * The scope a menu was rendered for. The server decides between the batch
 * and the singular menu, so the markup it renders carries the count and the
 * ids the menu's actions were built for.
 */
export class RenderedMenuScope {
  /** The scope of the nearest element, itself included, that carries one. */
  static of(element:Element|null):RenderedMenuScope|null {
    const owner = element?.closest(`[${sortableScopeCountAttribute}]`);
    return owner ? new RenderedMenuScope(owner) : null;
  }

  readonly count:number;
  private readonly ids:readonly string[]|null;

  private constructor(owner:Element) {
    const count = Number.parseInt(owner.getAttribute(sortableScopeCountAttribute) ?? '', 10);
    this.count = Number.isNaN(count) ? SINGULAR_COUNT : count;
    this.ids = parseIds(owner.getAttribute(sortableScopeIdsAttribute));
  }

  /** Whether the rendered ids are exactly the live items', in document order. */
  matches(liveItems:readonly HTMLElement[]):boolean {
    const rendered = this.ids;
    if (!rendered || rendered.length === 0 || new Set(rendered).size !== rendered.length) return false;

    const live = [...liveItems]
      .sort((left, right) => (left.compareDocumentPosition(right) & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1))
      .map((item) => resolveItemId(item));
    return rendered.length === live.length && rendered.every((id, index) => id !== '' && id === live[index]);
  }
}

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

import { caretPlacement } from './caret-placement';
import type { CaretPlacement } from './caret-placement';

// Primer's anchored-position repositions by writing `top`/`left` inline and
// does not announce which side it settled on, so the caret is re-derived from
// the resulting geometry after every such write.
export function syncCaret(
  popover:HTMLElement,
  anchorRect:() => DOMRect | null,
  apply:(caret:CaretPlacement) => void,
):() => void {
  let last:CaretPlacement | null = null;

  const observer = new MutationObserver(() => {
    if (!popover.matches(':popover-open')) return;
    const rect = anchorRect();
    if (!rect) return;

    const caret = caretPlacement(popover.getBoundingClientRect(), rect);
    if (caret.side === last?.side && caret.offset === last.offset) return;

    last = caret;
    apply(caret);
  });
  observer.observe(popover, { attributes: true, attributeFilter: ['style'] });

  return () => observer.disconnect();
}

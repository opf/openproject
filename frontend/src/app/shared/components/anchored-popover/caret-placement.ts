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

export type CaretSide = 'top' | 'bottom' | 'left' | 'right';

export interface CaretPlacement {
  side:CaretSide;
  offset:number;
}

const CARET_INSET_IN_PX = 12;

// The caret sits on the popover edge that faces the anchor, centred on the
// anchor along that edge and kept clear of the popover's rounded corners.
export function caretPlacement(popover:DOMRect, anchor:DOMRect):CaretPlacement {
  const side = caretSide(popover, anchor);
  const horizontal = side === 'top' || side === 'bottom';
  const center = horizontal
    ? anchor.left + anchor.width / 2 - popover.left
    : anchor.top + anchor.height / 2 - popover.top;
  const extent = horizontal ? popover.width : popover.height;

  return { side, offset: clamp(center, CARET_INSET_IN_PX, extent - CARET_INSET_IN_PX) };
}

function caretSide(popover:DOMRect, anchor:DOMRect):CaretSide {
  if (popover.bottom <= anchor.top) return 'bottom';
  if (popover.top >= anchor.bottom) return 'top';
  if (popover.left >= anchor.right) return 'left';
  return 'right';
}

function clamp(value:number, min:number, max:number):number {
  return Math.min(Math.max(value, min), Math.max(min, max));
}

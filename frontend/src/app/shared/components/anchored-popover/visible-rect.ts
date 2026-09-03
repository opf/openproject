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

// Clips by the padding boxes of overflow ancestors only; transforms,
// clip-path, containing-block escapes and shadow boundaries are not handled.
export function visibleRect(element:Element):DOMRect {
  const rect = element.getBoundingClientRect();
  let { left, top, right, bottom } = rect;

  for (let ancestor = element.parentElement; ancestor; ancestor = ancestor.parentElement) {
    const { overflowX, overflowY } = getComputedStyle(ancestor);
    if (overflowX === 'visible' && overflowY === 'visible') continue;

    const box = ancestor.getBoundingClientRect();
    if (overflowX !== 'visible') {
      left = Math.max(left, box.left + ancestor.clientLeft);
      right = Math.min(right, box.left + ancestor.clientLeft + ancestor.clientWidth);
    }
    if (overflowY !== 'visible') {
      top = Math.max(top, box.top + ancestor.clientTop);
      bottom = Math.min(bottom, box.top + ancestor.clientTop + ancestor.clientHeight);
    }
  }

  return new DOMRect(left, top, Math.max(0, right - left), Math.max(0, bottom - top));
}

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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { reorderById } from './reorder';

describe('reorderById', () => {
  interface Item { id:string }

  const a:Item = { id: 'a' };
  const b:Item = { id: 'b' };
  const c:Item = { id: 'c' };

  function reorder(list:Item[], sourceId:string, targetId:string, closestEdge:'left'|'right'|null) {
    return reorderById({
      list,
      getId: (item) => item.id,
      sourceId,
      targetId,
      closestEdge,
      axis: 'horizontal',
    });
  }

  it('moves the source before the target on a leading-edge drop', () => {
    expect(reorder([a, b, c], 'c', 'a', 'left')).toEqual([c, a, b]);
  });

  it('moves the source after the target on a trailing-edge drop', () => {
    expect(reorder([a, b, c], 'a', 'c', 'right')).toEqual([b, c, a]);
  });

  it('returns the original reference when the source id is unknown', () => {
    const list = [a, b, c];

    expect(reorder(list, 'missing', 'a', 'left')).toBe(list);
  });

  it('returns the original reference when the target id is unknown', () => {
    const list = [a, b, c];

    expect(reorder(list, 'a', 'missing', 'left')).toBe(list);
  });

  it('returns the original reference for a self-drop', () => {
    const list = [a, b, c];

    expect(reorder(list, 'b', 'b', 'left')).toBe(list);
  });

  it('returns the original reference when dropped on the leading edge of the next item', () => {
    const list = [a, b, c];

    expect(reorder(list, 'a', 'b', 'left')).toBe(list);
  });

  it('returns the original reference when dropped on the trailing edge of the previous item', () => {
    const list = [a, b, c];

    expect(reorder(list, 'b', 'a', 'right')).toBe(list);
  });
});

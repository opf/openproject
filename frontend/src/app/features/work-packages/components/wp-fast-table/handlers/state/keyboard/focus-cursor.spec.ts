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

import { FocusCursor } from './focus-cursor';
import { samePosition, type FocusPosition } from './focus-position';

const at = (key:string, cell:number|null = null, desiredColumn:number|null = cell):FocusPosition => ({ key, cell, desiredColumn });

describe('FocusCursor', () => {
  const build = () => {
    const paint = vi.fn<(position:FocusPosition|null) => void>();
    return { cursor: new FocusCursor(paint), paint };
  };

  it('clears the walk when landing', () => {
    const { cursor } = build();
    cursor.startWalk(at('A', 1));

    cursor.land(at('B'), { user: true, paint: false });

    expect(cursor.walkOrigin).toBeNull();
    expect(cursor.position).toEqual(at('B'));
    expect(cursor.userPosition).toEqual(at('B'));
  });

  it('keeps the user position when landing without user', () => {
    const { cursor } = build();
    cursor.land(at('A'), { user: true, paint: false });

    cursor.land(at('B'), { user: false, paint: false });

    expect(cursor.position).toEqual(at('B'));
    expect(cursor.userPosition).toEqual(at('A'));
  });

  it('paints only when asked', () => {
    const { cursor, paint } = build();

    cursor.land(at('A'), { user: true, paint: false });
    expect(paint).not.toHaveBeenCalled();

    cursor.land(at('B'), { user: true, paint: true });
    expect(paint).toHaveBeenCalledExactlyOnceWith(at('B'));
  });

  it('keeps the walk when following a walked control', () => {
    const { cursor, paint } = build();
    cursor.startWalk(at('A', 1));

    cursor.follow(at('A', 1));

    expect(cursor.walkOrigin).toEqual(at('A', 1));
    expect(cursor.position).toEqual(at('A', 1));
    expect(cursor.userPosition).toEqual(at('A', 1));
    expect(paint).not.toHaveBeenCalled();
  });

  it('keeps the walk and user position when reconciling', () => {
    const { cursor } = build();
    cursor.land(at('A'), { user: true, paint: false });
    cursor.startWalk(at('A', 1));

    cursor.reconcile(at('B'));

    expect(cursor.position).toEqual(at('B'));
    expect(cursor.userPosition).toEqual(at('A'));
    expect(cursor.walkOrigin).toEqual(at('A', 1));
  });

  it('notes a user move without moving the position', () => {
    const { cursor } = build();
    cursor.land(at('A'), { user: true, paint: false });

    cursor.noteUserMove(at('B'));

    expect(cursor.position).toEqual(at('A'));
    expect(cursor.userPosition).toEqual(at('B'));
  });

  it('reports the user moved only when the user position changed', () => {
    const { cursor } = build();
    cursor.land(at('A', 1, 1), { user: true, paint: false });

    expect(cursor.userMovedSince(at('A', 1, 3))).toBe(false);
    expect(cursor.userMovedSince(at('A', 2))).toBe(true);
    expect(cursor.userMovedSince(null)).toBe(true);
  });

  it('reports no move from no position to no position', () => {
    const { cursor } = build();

    expect(cursor.userMovedSince(null)).toBe(false);
  });
});

describe('samePosition', () => {
  it('compares row key and cell, not the desired column', () => {
    expect(samePosition(at('A', 1, 1), at('A', 1, 4))).toBe(true);
    expect(samePosition(at('A', 1), at('A', 2))).toBe(false);
    expect(samePosition(at('A'), at('B'))).toBe(false);
    expect(samePosition(null, null)).toBe(true);
    expect(samePosition(at('A'), null)).toBe(false);
  });
});

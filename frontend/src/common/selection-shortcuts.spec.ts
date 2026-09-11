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

import { isSelectAllShortcut } from './selection-shortcuts';

describe('isSelectAllShortcut', () => {
  it.each([
    [false, { key: 'a', ctrlKey: true }, true],
    [true, { key: 'a', metaKey: true }, true],
    [true, { key: 'a', ctrlKey: true }, false],
    [false, { key: 'a', metaKey: true }, false],
    [false, { key: 'a', code: 'KeyQ', ctrlKey: true }, true],
    [false, { key: 'q', code: 'KeyA', ctrlKey: true }, false],
    [false, { key: 'ф', code: 'KeyA', ctrlKey: true }, true],
    [false, { key: 'Dead', code: 'KeyA', ctrlKey: true }, false],
    [false, { key: 'a', ctrlKey: true, isComposing: true }, false],
    [false, { key: 'a', ctrlKey: true, altKey: true }, false],
  ] as [boolean, KeyboardEventInit, boolean][])(
    'recognizes Select All on Apple=%s with %j', (apple, init, expected) => {
      expect(isSelectAllShortcut(new KeyboardEvent('keydown', init), apple)).toBe(expected);
    },
  );

  it('rejects AltGraph', () => {
    const event = new KeyboardEvent('keydown', { key: 'a', ctrlKey: true });
    vi.spyOn(event, 'getModifierState').mockImplementation((key) => key === 'AltGraph');
    expect(isSelectAllShortcut(event, false)).toBe(false);
  });
});

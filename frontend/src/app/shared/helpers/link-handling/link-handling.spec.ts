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

import { isClickedWithModifier } from './link-handling';

describe('modified link interactions', () => {
  it.each(['ctrlKey', 'shiftKey', 'metaKey'])('preserves %s for pointer and keyboard events', (modifier) => {
    expect(isClickedWithModifier(new MouseEvent('click', { [modifier]: true }))).toBe(true);
    expect(isClickedWithModifier(new KeyboardEvent('keydown', { key: 'Enter', [modifier]: true }))).toBe(true);
  });

  it('recognizes middle clicks and ordinary keyboard activation', () => {
    expect(isClickedWithModifier(new MouseEvent('click', { button: 1 }))).toBe(true);
    expect(isClickedWithModifier(new MouseEvent('click'))).toBe(false);
    expect(isClickedWithModifier(new KeyboardEvent('keydown', { key: 'Enter' }))).toBe(false);
  });
});

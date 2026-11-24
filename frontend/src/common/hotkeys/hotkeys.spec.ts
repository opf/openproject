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

import { normalizeSequence } from '@github/hotkey';
import { HOTKEYS, KNOWN_SEQUENCES } from './hotkeys';

describe('hotkeys', () => {
  it('reads the action hotkeys from the shared definitions', () => {
    expect(HOTKEYS.toggle_details).toBe('d w p');
    expect(HOTKEYS.global_search).toBe('s');
  });

  it('knows every multi-key sequence of every group, and no single keys', () => {
    expect(KNOWN_SEQUENCES).toEqual(new Set(
      ['g m', 'g o', 'g w p', 'g w i', 'g a', 'g c', 'g n', 'g e', 'n w p', 'd w p'].map((sequence) => normalizeSequence(sequence)),
    ));
  });
});

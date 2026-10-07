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

import { vi, type Mock } from 'vitest';
import { ContextualActionMenu } from 'core-common/contextual-action-menu';
import { EntryMenus } from './my-work-entry-menus';

describe('EntryMenus', () => {
  let root:HTMLElement;
  let card:HTMLElement;
  let openAtPoint:Mock<ContextualActionMenu['openAtPoint']>;

  beforeEach(() => {
    openAtPoint = vi.spyOn(ContextualActionMenu.prototype, 'openAtPoint').mockImplementation(() => undefined);
    document.body.innerHTML = `
      <div id="root">
        <div class="fc-event" id="card"></div>
        <div data-my-work-menus>
          <div data-my-work-menu-for="42"><action-menu><div popover></div></action-menu></div>
        </div>
      </div>`;

    root = document.getElementById('root')!;
    card = document.getElementById('card')!;
  });

  afterEach(() => vi.restoreAllMocks());

  it('opens the menu of the clicked event at the pointer', () => {
    new EntryMenus(root).open('42', new MouseEvent('click', { clientX: 10, clientY: 20 }), card);

    expect(openAtPoint).toHaveBeenCalledWith(10, 20, card);
  });

  it('focuses the clicked event first, so that the menu does not open as if reached by keyboard', () => {
    new EntryMenus(root).open('42', new MouseEvent('click'), card);

    expect(document.activeElement).toBe(card);
    expect(card.matches(':focus-visible')).toBe(false);
  });

  it('opens nothing for an event without a menu', () => {
    new EntryMenus(root).open('43', new MouseEvent('click'), card);

    expect(openAtPoint).not.toHaveBeenCalled();
  });
});

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

import { refreshMenuAvailability } from './menu-availability';

function fixture(hideUnavailable = true) {
  const list = document.createElement('ul');
  list.innerHTML = '<li role="separator"></li><li data-sortable-lists-destinations=\'[ { "type": "inbox", "id": null } ]\'></li><li></li><anchored-position popover="auto"></anchored-position>';
  const [divider, destination, moveMenu] = Array.from(list.querySelectorAll('li'));
  const moveItem = document.createElement('li');
  moveItem.setAttribute('data-sortable-lists-item-direction-param', 'top');
  moveMenu.append(moveItem);
  const menu = {
    showItem: (item:HTMLElement) => item.removeAttribute('hidden'),
    hideItem: (item:HTMLElement) => item.setAttribute('hidden', ''),
    enableItem: (item:HTMLElement) => item.removeAttribute('aria-disabled'),
    disableItem: (item:HTMLElement) => item.setAttribute('aria-disabled', 'true'),
  };
  const input:Parameters<typeof refreshMenuAvailability>[0] = {
    menu,
    scope: { kind: 'batch', items: [document.createElement('div'), document.createElement('div')] },
    destinationItems: [destination],
    moveItems: [moveItem],
    moveMenu,
    divider,
    hideUnavailable,
    identifier: 'sortable-lists-item',
    availableDestinations: vi.fn(() => []),
    moveAvailability: vi.fn(() => ({ top: false, up: false, down: false, bottom: false })),
  };
  return { input, divider, destination, moveMenu, moveItem };
}

describe('menu availability projection', () => {
  it('ignores the trailing overlay when every real action is hidden', () => {
    const { input, divider, destination, moveMenu, moveItem } = fixture();
    refreshMenuAvailability(input);
    for (const element of [divider, destination, moveMenu, moveItem]) {
      expect(element.hasAttribute('hidden')).toBe(true);
    }
    expect(input.moveAvailability).toHaveBeenCalled();
  });

  it('restores the position group when the batch becomes positionable', () => {
    const { input, divider, moveMenu, moveItem } = fixture();
    refreshMenuAvailability(input);
    input.moveAvailability = vi.fn(() => ({ top: true, up: true, down: false, bottom: false }));
    refreshMenuAvailability(input);
    for (const element of [divider, moveMenu, moveItem]) {
      expect(element.hasAttribute('hidden')).toBe(false);
    }
  });

  it('disables unavailable actions without hiding the group separator', () => {
    const { input, divider, destination, moveMenu, moveItem } = fixture(false);
    refreshMenuAvailability(input);
    expect(divider.hasAttribute('hidden')).toBe(false);
    for (const element of [destination, moveMenu, moveItem]) {
      expect(element.getAttribute('aria-disabled')).toBe('true');
      expect(element.hasAttribute('hidden')).toBe(false);
    }
  });
});

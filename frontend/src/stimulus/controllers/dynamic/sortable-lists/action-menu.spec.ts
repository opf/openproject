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

import type { ActionMenuElement } from '@openproject/primer-view-components/app/components/primer/alpha/action_menu/action_menu_element';
import { SortableActionMenu } from './action-menu';

function fixture(hideUnavailable = true) {
  const list = document.createElement('ul');
  list.innerHTML = '<li role="separator"></li><li></li><li></li><anchored-position popover="auto"></anchored-position>';
  const [groupDivider, destination, moveSubmenu] = Array.from(list.querySelectorAll('li'));
  const moveItem = document.createElement('li');
  moveSubmenu.append(moveItem);
  const menu = {
    showItem: (item:HTMLElement) => item.removeAttribute('hidden'),
    hideItem: (item:HTMLElement) => item.setAttribute('hidden', ''),
    enableItem: (item:HTMLElement) => item.removeAttribute('aria-disabled'),
    disableItem: (item:HTMLElement) => item.setAttribute('aria-disabled', 'true'),
  } as ActionMenuElement;
  const projection = new SortableActionMenu(menu, hideUnavailable, null);
  const elements = {
    destinationItems: [destination],
    moveItems: [moveItem],
    moveSubmenu,
    groupDivider,
    invokerGroup: null,
    batchGroup: null,
  };
  const scope = { batch: false, count: 1 };
  const availability = { destinationItem: () => false, moveItem: () => false };
  return { projection, elements, scope, availability, destination, moveSubmenu, moveItem, groupDivider };
}

describe('menu availability projection', () => {
  it('ignores the trailing overlay when every real action is hidden', () => {
    const { projection, elements, scope, availability, groupDivider, destination, moveSubmenu, moveItem } = fixture();
    projection.project(elements, scope, availability);
    for (const element of [groupDivider, destination, moveSubmenu, moveItem]) {
      expect(element.hasAttribute('hidden')).toBe(true);
    }
  });

  it('restores the position group when the batch becomes positionable', () => {
    const { projection, elements, scope, availability, groupDivider, moveSubmenu, moveItem } = fixture();
    projection.project(elements, scope, availability);
    projection.project(elements, scope, { ...availability, moveItem: () => true });
    for (const element of [groupDivider, moveSubmenu, moveItem]) {
      expect(element.hasAttribute('hidden')).toBe(false);
    }
  });

  it('disables unavailable actions without hiding the group separator', () => {
    const { projection, elements, scope, availability, groupDivider, destination, moveSubmenu, moveItem } = fixture(false);
    projection.project(elements, scope, availability);
    expect(groupDivider.hasAttribute('hidden')).toBe(false);
    for (const element of [destination, moveSubmenu, moveItem]) {
      expect(element.getAttribute('aria-disabled')).toBe('true');
      expect(element.hasAttribute('hidden')).toBe(false);
    }
  });
});

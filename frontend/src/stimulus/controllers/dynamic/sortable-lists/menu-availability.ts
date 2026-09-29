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
import type { ActionScope } from './action-scope';
import type { SortableListsRoot } from './drag-and-drop';
import { isMoveDirection, parseDestinationCandidates, type DestinationIdentity } from './list-dom';

interface MenuAvailabilityInput {
  menu:Pick<ActionMenuElement, 'showItem'|'hideItem'|'enableItem'|'disableItem'>;
  scope:ActionScope;
  destinationItems:HTMLElement[];
  moveItems:HTMLElement[];
  moveMenu:HTMLElement|null;
  divider:HTMLElement|null;
  hideUnavailable:boolean;
  identifier:string;
  availableDestinations:(scope:ActionScope, candidates:DestinationIdentity[]) => DestinationIdentity[];
  moveAvailability:() => ReturnType<SortableListsRoot['moveAvailability']>;
}

export function refreshMenuAvailability(input:MenuAvailabilityInput):void {
  const setAvailability = (item:HTMLElement, available:boolean):void => {
    if (input.hideUnavailable) {
      input.menu[available ? 'showItem' : 'hideItem'](item);
    } else {
      input.menu[available ? 'enableItem' : 'disableItem'](item);
    }
  };

  for (const item of input.destinationItems) {
    const candidates = parseDestinationCandidates(item.dataset.sortableListsDestinations);
    setAvailability(item, candidates.length > 0 && input.availableDestinations(input.scope, candidates).length > 0);
  }

  const multiItem = input.scope.kind === 'batch' && input.scope.items.length > 1;
  const availability = multiItem ? null : input.moveAvailability();
  if (multiItem || availability) {
    let available = 0;
    for (const item of input.moveItems) {
      const direction = item.getAttribute(`data-${input.identifier}-direction-param`);
      const enabled = !multiItem && isMoveDirection(direction) && !!availability?.[direction];
      setAvailability(item, enabled);
      if (enabled) available += 1;
    }
    if (input.moveMenu) setAvailability(input.moveMenu, available > 0);
  }

  if (input.divider && input.hideUnavailable) {
    let sibling = input.divider.nextElementSibling;
    while (sibling) {
      if (sibling instanceof HTMLLIElement && !sibling.hasAttribute('hidden')) {
        input.divider.removeAttribute('hidden');
        return;
      }
      sibling = sibling.nextElementSibling;
    }
    input.divider.setAttribute('hidden', 'hidden');
  }
}

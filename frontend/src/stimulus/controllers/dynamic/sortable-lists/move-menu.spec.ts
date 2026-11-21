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

import { within } from '@testing-library/dom';
import '@openproject/primer-view-components/app/components/primer/alpha/action_menu/action_menu_element';
import type { ActionMenuElement } from '@openproject/primer-view-components/app/components/primer/alpha/action_menu/action_menu_element';
import type { MoveAvailability } from './list-dom';
import { MoveMenu } from './move-menu';

describe('MoveMenu', () => {
  const directionAttribute = 'data-sortable-lists--item-direction-param';
  const directions = ['top', 'up', 'down', 'bottom'] as const;
  const everywhere:MoveAvailability = { top: true, up: true, down: true, bottom: true };
  const nowhere:MoveAvailability = { top: false, up: false, down: false, bottom: false };
  const notUpwards:MoveAvailability = { top: false, up: false, down: true, bottom: true };
  const single = () => 1;
  const batch = () => 2;
  const explanationText = 'No actions available for the selected work packages.';

  let menu:ActionMenuElement;

  afterEach(() => {
    menu.remove();
  });

  // Primer's own markup for the parts the move menu touches: its item API
  // writes aria-disabled to an item's `.ActionListContent` and throws on an
  // item without one. The divider opens the move group, so everything below
  // it decides whether it still separates anything.
  function renderMenu({ withDivider = false, withExplanation = false } = {}):void {
    const host = document.createElement('div');
    host.innerHTML = `
      <action-menu>
        <button type="button" popovertarget="move-menu-overlay">More</button>
        <anchored-position id="move-menu-overlay" popover="auto" data-target="action-menu.overlay">
          <div class="Overlay-body" data-target="action-menu.overlayBody">
            <ul role="menu">
              ${withExplanation ? `<li class="ActionListItem" data-sortable-lists--item-target="moveUnavailable" hidden>
                <button class="ActionListContent" role="menuitem" aria-disabled="true">${explanationText}</button>
              </li>` : ''}
              ${withDivider ? '<li data-sortable-lists--item-target="moveDivider" role="presentation"></li>' : ''}
              ${directions.map((direction) => `
                <li class="ActionListItem" data-sortable-lists--item-target="moveItem" ${directionAttribute}="${direction}">
                  <button class="ActionListContent" type="button">${direction}</button>
                </li>`).join('')}
              <li class="ActionListItem" data-sortable-lists--item-target="moveMenu">
                <button class="ActionListContent" role="menuitem" type="button">Move to position</button>
              </li>
            </ul>
          </div>
        </anchored-position>
      </action-menu>
    `;
    const rendered = host.querySelector<ActionMenuElement>('action-menu');
    if (!rendered) throw new Error('No action menu rendered');
    menu = rendered;
    document.body.appendChild(menu);
  }

  const targets = (name:string) => Array.from(menu.querySelectorAll<HTMLElement>(`[data-sortable-lists--item-target="${name}"]`));
  const target = (name:string):HTMLElement => {
    const [element] = targets(name);
    if (!element) throw new Error(`No ${name} target`);
    return element;
  };
  const itemFor = (direction:string):HTMLElement => {
    const element = menu.querySelector<HTMLElement>(`li[${directionAttribute}="${direction}"]`);
    if (!element) throw new Error(`No ${direction} item`);
    return element;
  };
  const submenu = () => target('moveMenu');
  const divider = () => target('moveDivider');
  const explanation = () => target('moveUnavailable');
  const list = () => within(menu).getByRole('menu', { hidden: true });
  const contentOf = (item:HTMLElement):HTMLElement => {
    const content = item.querySelector<HTMLElement>(':scope > .ActionListContent');
    if (!content) throw new Error('Item has no content');
    return content;
  };

  // Built from the markup as it stands, the way the item controller builds
  // one from its current targets for every refresh.
  function moveMenu({ hideUnavailable = true } = {}):MoveMenu {
    return new MoveMenu(
      menu,
      {
        items: targets('moveItem'),
        submenu: targets('moveMenu')[0] ?? null,
        divider: targets('moveDivider')[0] ?? null,
        explanations: targets('moveUnavailable'),
      },
      { hideUnavailable, directionAttribute },
    );
  }

  // Primer renders the directions inside the submenu, so the submenu is the
  // divider's only sibling once no destination is offered.
  function nestDirectionsInSubmenu():void {
    const nested = document.createElement('ul');
    nested.append(...targets('moveItem'));
    submenu().appendChild(nested);
  }

  function expectDisabled(item:HTMLElement, disabled:boolean):void {
    if (disabled) {
      expect(item).toHaveClass('ActionListItem--disabled');
      expect(contentOf(item)).toHaveAttribute('aria-disabled', 'true');
    } else {
      expect(item).not.toHaveClass('ActionListItem--disabled');
      expect(contentOf(item)).not.toHaveAttribute('aria-disabled');
    }
  }

  it('hides up/top for a first item and shows the rest', () => {
    renderMenu();
    itemFor('down').setAttribute('hidden', 'hidden');

    moveMenu().gate(notUpwards, single);

    expect(itemFor('top')).toHaveAttribute('hidden');
    expect(itemFor('up')).toHaveAttribute('hidden');
    expect(itemFor('down')).not.toHaveAttribute('hidden');
    expect(itemFor('bottom')).not.toHaveAttribute('hidden');
  });

  it('hides a mid-list direction reported unavailable (truncation gap)', () => {
    renderMenu();

    moveMenu().gate({ ...everywhere, down: false }, single);

    expect(itemFor('down')).toHaveAttribute('hidden');
    expect(itemFor('up')).not.toHaveAttribute('hidden');
  });

  it('leaves an item without a known direction unavailable', () => {
    renderMenu();
    const item = itemFor('down');
    item.setAttribute(directionAttribute, 'sideways');

    moveMenu().gate(everywhere, single);

    expect(item).toHaveAttribute('hidden');
  });

  it('disables unavailable items instead of hiding them when hideUnavailable is off', () => {
    renderMenu();

    moveMenu({ hideUnavailable: false }).gate(notUpwards, single);

    expectDisabled(itemFor('top'), true);
    expectDisabled(itemFor('up'), true);
    expectDisabled(itemFor('down'), false);
    expectDisabled(itemFor('bottom'), false);
    directions.forEach((direction) => expect(itemFor(direction)).not.toHaveAttribute('hidden'));
  });

  it('enables an item again once its direction is available', () => {
    renderMenu();
    moveMenu({ hideUnavailable: false }).gate(nowhere, single);

    moveMenu({ hideUnavailable: false }).gate(everywhere, single);

    directions.forEach((direction) => {
      expect(itemFor(direction)).not.toHaveClass('ActionListItem--disabled');
      expect(contentOf(itemFor(direction))).not.toHaveAttribute('aria-disabled');
    });
  });

  it('hides the parent submenu when nothing is available (single item)', () => {
    renderMenu();

    moveMenu().gate(nowhere, single);

    expect(submenu()).toHaveAttribute('hidden');
  });

  it('gates the items without a submenu, divider or explanation', () => {
    renderMenu();
    submenu().remove();

    moveMenu().gate(notUpwards, single);

    expect(itemFor('top')).toHaveAttribute('hidden');
    expect(itemFor('down')).not.toHaveAttribute('hidden');
  });

  it('asks for the scope size only when no direction is available', () => {
    renderMenu();
    const scopeSize = vi.fn(() => 2);

    moveMenu().gate(notUpwards, scopeSize);
    expect(scopeSize).not.toHaveBeenCalled();

    moveMenu().gate(nowhere, scopeSize);
    expect(scopeSize).toHaveBeenCalledOnce();
  });

  describe('divider', () => {
    // Regression: the divider is rendered server-side from a permission check
    // alone, so an item with nowhere to move used to be left with a separator
    // and nothing below it.
    it('hides the divider when nothing below it is left visible', () => {
      renderMenu({ withDivider: true });

      moveMenu().gate(nowhere, single);

      expect(divider()).toHaveAttribute('hidden');
    });

    it('hides the singular divider with a trailing submenu overlay but no visible ActionList item', () => {
      renderMenu({ withDivider: true });
      list().append(document.createElement('anchored-position'));

      moveMenu().gate(nowhere, single);

      expect(divider()).toHaveAttribute('hidden');
    });

    it('keeps the divider while something below it is still visible', () => {
      renderMenu({ withDivider: true });

      moveMenu().gate(notUpwards, single);

      expect(divider()).not.toHaveAttribute('hidden');
    });

    it('shows the divider again once something below it is visible', () => {
      renderMenu({ withDivider: true });
      moveMenu().gate(nowhere, single);

      moveMenu().gate(notUpwards, single);

      expect(divider()).not.toHaveAttribute('hidden');
    });

    // A divider has no `.ActionListContent`, so routing it through
    // `disableItem` would throw — and in this mode the group stays visible
    // anyway, only disabled.
    it('leaves the divider alone when hideUnavailable is off', () => {
      renderMenu({ withDivider: true });

      expect(() => moveMenu({ hideUnavailable: false }).gate(nowhere, single)).not.toThrow();

      expect(divider()).not.toHaveAttribute('hidden');
      expect(divider()).not.toHaveClass('ActionListItem--disabled');
    });
  });

  describe('for a multi-card block', () => {
    function renderDisablingBatchMenu():MoveMenu {
      renderMenu({ withDivider: true });
      nestDirectionsInSubmenu();
      return moveMenu({ hideUnavailable: false });
    }

    it('hides Move to position for a blocked same-list batch', () => {
      renderDisablingBatchMenu().gate(nowhere, batch);

      expect(submenu()).toHaveAttribute('hidden');
      expect(submenu()).not.toHaveClass('ActionListItem--disabled');
      expect(divider()).toHaveAttribute('hidden');
    });

    it('shows Move to position again once the block can move', () => {
      renderDisablingBatchMenu().gate(nowhere, batch);

      moveMenu({ hideUnavailable: false }).gate({ ...nowhere, up: true }, batch);

      expect(submenu()).not.toHaveAttribute('hidden');
      expectDisabled(submenu(), false);
      expectDisabled(itemFor('up'), false);
      expectDisabled(itemFor('down'), true);
      expect(divider()).not.toHaveAttribute('hidden');
    });

    it('keeps single-card availability unchanged', () => {
      renderDisablingBatchMenu().gate(nowhere, single);

      expectDisabled(submenu(), true);
      expect(submenu()).not.toHaveAttribute('hidden');
      expect(divider()).not.toHaveAttribute('hidden');
    });

    // A batch menu whose only action is Move to position carries the
    // explanation hidden, so it never opens empty.
    describe('with an explanation item', () => {
      function renderBatchMenuWithExplanation():void {
        renderMenu({ withExplanation: true });
        nestDirectionsInSubmenu();
      }

      const moveToPosition = () => within(list()).getByRole('menuitem', { name: 'Move to position', hidden: true });

      it('swaps Move to position for the explanation when a batch block cannot move', () => {
        renderBatchMenuWithExplanation();

        moveMenu().gate(nowhere, batch);

        expect(submenu()).toHaveAttribute('hidden');
        expect(explanation()).not.toHaveAttribute('hidden');
      });

      it('moves focus to the explanation when the focused submenu is hidden', () => {
        renderBatchMenuWithExplanation();
        menu.popoverElement?.showPopover();
        moveToPosition().focus();

        moveMenu().gate(nowhere, batch);

        expect(submenu()).toHaveAttribute('hidden');
        expect(within(explanation()).getByRole('menuitem')).toHaveFocus();
      });

      it('moves focus to Move to position before hiding the focused explanation', () => {
        renderBatchMenuWithExplanation();
        menu.popoverElement?.showPopover();
        moveMenu().gate(nowhere, batch);
        within(explanation()).getByRole('menuitem').focus();

        moveMenu().gate({ ...nowhere, down: true }, batch);

        expect(explanation()).toHaveAttribute('hidden');
        expect(moveToPosition()).toHaveFocus();
      });

      it('moves focus to another action when the focused submenu is hidden and nothing explains it', () => {
        renderBatchMenuWithExplanation();
        explanation().remove();
        list().insertAdjacentHTML('afterbegin', '<li class="ActionListItem"><form><button class="ActionListContent" role="menuitem">Move to sprint</button></form></li>');
        menu.popoverElement?.showPopover();
        moveToPosition().focus();

        moveMenu().gate(nowhere, batch);

        expect(submenu()).toHaveAttribute('hidden');
        expect(within(list()).getByRole('menuitem', { name: 'Move to sprint' })).toHaveFocus();
      });

      it('hides the explanation again once the block can move', () => {
        renderBatchMenuWithExplanation();
        moveMenu().gate(nowhere, batch);

        moveMenu().gate({ ...nowhere, down: true }, batch);

        expect(submenu()).not.toHaveAttribute('hidden');
        expect(explanation()).toHaveAttribute('hidden');
      });

      it('keeps the explanation hidden for a contiguous block', () => {
        renderBatchMenuWithExplanation();

        moveMenu().gate(everywhere, batch);

        expect(submenu()).not.toHaveAttribute('hidden');
        expect(explanation()).toHaveAttribute('hidden');
      });

      it('hides Move to position for a blocked batch without an explanation item', () => {
        renderMenu();
        nestDirectionsInSubmenu();

        moveMenu().gate(nowhere, batch);

        expect(submenu()).toHaveAttribute('hidden');
      });
    });

    // Above the batch cap the server renders every position item disabled
    // and marks it locked; direction gating must not revive it.
    describe('above the batch cap', () => {
      function lockAsServerDisabled():void {
        [submenu(), ...targets('moveItem')].forEach((li) => {
          li.classList.add('ActionListItem--disabled');
          li.setAttribute('data-sortable-lists-locked', '');
        });
      }

      it.each([
        { mode: 'hiding', hideUnavailable: true },
        { mode: 'disabling', hideUnavailable: false },
      ])('keeps server-disabled position items disabled and visible when $mode', ({ hideUnavailable }) => {
        renderMenu();
        nestDirectionsInSubmenu();
        lockAsServerDisabled();
        const subject = moveMenu({ hideUnavailable });

        subject.gate(notUpwards, batch);

        for (const li of [submenu(), ...directions.map(itemFor)]) {
          expect(li).toHaveClass('ActionListItem--disabled');
          expect(li).not.toHaveAttribute('hidden');
        }
        expect(subject.activatable(itemFor('down'))).toBeNull();
      });
    });
  });

  describe('activation', () => {
    it('answers the item for an enabled, visible item', () => {
      renderMenu();

      expect(moveMenu().activatable(itemFor('down'))).toBe(itemFor('down'));
    });

    it('refuses a hidden item', () => {
      renderMenu();
      itemFor('down').hidden = true;

      expect(moveMenu().activatable(itemFor('down'))).toBeNull();
    });

    it('refuses a disabled item', () => {
      renderMenu();
      menu.disableItem(itemFor('down'));

      expect(moveMenu().activatable(itemFor('down'))).toBeNull();
    });

    it('refuses a target that is not an element', () => {
      renderMenu();

      expect(moveMenu().activatable(document)).toBeNull();
      expect(moveMenu().activatable(null)).toBeNull();
    });
  });
});

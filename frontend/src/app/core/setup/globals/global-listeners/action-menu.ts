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
import { ANIMATION_RATE_MS } from 'core-app/core/top-menu/top-menu.service';
import { slideDown, slideUp } from 'es6-slide-up-down';

/*
  The action menu is a menu that usually belongs to an OpenProject entity (like an Issue, WikiPage, Meeting, ..).
  Most likely it looks like this:
    <ul class="action_menu_main">
      <li><a>Menu item text</a></li>
      <li><a>Menu item text</a></li>
      <li class="drop-down">
        <a class="icon icon-more" href="#">More functions</a>
        <ul style="display:none;" class="menu-drop-down-container">
          <li><a>Menu item text</a></li>
        </ul>
      </li>
    </ul>
  The following code is responsible to open and close the "more functions" submenu.
*/
function closeMenu(menu:HTMLElement, event:MouseEvent, cleanup:() => void) {
  // do not close the menu, if the user accidentally clicked next to a menu item (but still within the menu)
  if (event.target !== menu.querySelector(':scope > li.drop-down.open > ul')) {
    const li = menu.querySelector(':scope > li.drop-down.open')!;
    li.classList.remove('open');
    const ul = li.querySelector<HTMLUListElement>(':scope > ul');
    slideUp(ul!, ANIMATION_RATE_MS);
    // no need to watch for clicks, when the menu is already closed
    cleanup();
  }
}

function openMenu(menu:HTMLElement) {
  const dropDown = menu.querySelector(':scope > li.drop-down')!;
  // do not open a menu, which is already open
  if (!dropDown.classList.contains('open')) {
    const ul = dropDown.querySelector<HTMLUListElement>(':scope > ul')!;
    slideDown(ul, ANIMATION_RATE_MS);
    window.requestAnimationFrame(() => {
      dropDown.querySelector<HTMLAnchorElement>('li > a:first-child')?.focus();
      // when clicking on something, which is not the menu, close the menu
      const clickHandler = (evt:MouseEvent) => closeMenu(menu, evt, () => document.removeEventListener('click', clickHandler));
      document.addEventListener('click', clickHandler);
    });
    dropDown.classList.add('open');
  }
}

// open the given submenu when clicking on it
export function installMenuLogic(menu:HTMLElement) {
  menu.querySelector(':scope > li.drop-down')?.addEventListener('click', (event) => {
    openMenu(menu);
    // and prevent default action (href) for that element
    // but not for the menu items.
    const target = event.target;
    if (target instanceof HTMLElement && (target.matches('.drop-down') || target.closest('li, ul')?.matches('.drop-down'))) {
      event.preventDefault();
    }
  });
}

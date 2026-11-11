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

import '@openproject/primer-view-components/app/components/primer/alpha/action_menu/action_menu_element';
import type { ActionMenuElement } from '@openproject/primer-view-components/app/components/primer/alpha/action_menu/action_menu_element';
import { MenuEvents, type MenuEventHandlers } from './menu-events';

describe('MenuEvents', () => {
  let host:HTMLElement;
  let calls:string[];
  let events:MenuEvents|undefined;

  beforeEach(() => {
    calls = [];
    host = document.createElement('div');
    host.innerHTML = [menuMarkup('1'), menuMarkup('2')].join('');
    document.body.appendChild(host);
  });

  afterEach(() => {
    events?.stop();
    events = undefined;
    host.remove();
  });

  function menuMarkup(id:string):string {
    return `
      <action-menu id="menu-${id}">
        <button type="button" popovertarget="menu-${id}-overlay" aria-labelledby="menu-${id}-tooltip">More</button>
        <anchored-position id="menu-${id}-overlay" popover="auto" data-target="action-menu.overlay">
          <div class="Overlay-body" data-target="action-menu.overlayBody">
            <anchored-position id="menu-${id}-submenu" popover="auto"></anchored-position>
          </div>
        </anchored-position>
        <tool-tip id="menu-${id}-tooltip" popover="manual">More</tool-tip>
      </action-menu>
    `;
  }

  const menu = (id:string):ActionMenuElement => {
    const element = host.querySelector<ActionMenuElement>(`#menu-${id}`);
    if (!element) throw new Error(`No menu ${id}`);
    return element;
  };
  const part = (id:string):HTMLElement => {
    const element = host.querySelector<HTMLElement>(`#${id}`);
    if (!element) throw new Error(`No element ${id}`);
    return element;
  };
  const overlay = (id:string) => part(`menu-${id}-overlay`);

  function recording():MenuEventHandlers {
    return {
      opening: (opening) => { calls.push(`opening ${opening.id}`); },
      opened: (opened) => { calls.push(`opened ${opened.id}`); },
      closed: (closed) => { calls.push(`closed ${closed.id}`); },
    };
  }

  function started(handlers = recording(), accepts?:(candidate:ActionMenuElement) => boolean):MenuEvents {
    events = new MenuEvents(host, handlers, accepts);
    events.start();
    return events;
  }

  function toggle(target:Element, type:'beforetoggle'|'toggle', newState:'open'|'closed'):void {
    target.dispatchEvent(new ToggleEvent(type, { newState, oldState: newState === 'open' ? 'closed' : 'open' }));
  }

  function openAndClose(target:Element):void {
    toggle(target, 'beforetoggle', 'open');
    toggle(target, 'toggle', 'open');
    toggle(target, 'toggle', 'closed');
  }

  it("reports a menu's own popover opening, opened and closed, in that order", () => {
    started();

    openAndClose(overlay('1'));

    expect(calls).toEqual(['opening menu-1', 'opened menu-1', 'closed menu-1']);
  });

  it('ignores tooltip and submenu popovers inside the menu', () => {
    started();

    openAndClose(part('menu-1-tooltip'));
    openAndClose(part('menu-1-submenu'));

    expect(calls).toEqual([]);
  });

  it('ignores beforetoggle towards closed', () => {
    started();

    toggle(overlay('1'), 'beforetoggle', 'closed');

    expect(calls).toEqual([]);
  });

  it('accepts duck-typed toggle events', () => {
    started();

    overlay('1').dispatchEvent(Object.assign(new Event('beforetoggle'), { newState: 'open' }));
    overlay('1').dispatchEvent(Object.assign(new Event('toggle'), { newState: 'open' }));
    overlay('1').dispatchEvent(Object.assign(new Event('toggle'), { newState: 'closed' }));

    expect(calls).toEqual(['opening menu-1', 'opened menu-1', 'closed menu-1']);
  });

  it('ignores events without a newState', () => {
    started();

    overlay('1').dispatchEvent(new Event('toggle'));

    expect(calls).toEqual([]);
  });

  it('reports only the handlers it was given', () => {
    started({ opened: (opened) => { calls.push(`opened ${opened.id}`); } });

    openAndClose(overlay('1'));

    expect(calls).toEqual(['opened menu-1']);
  });

  it('skips menus the accepts predicate rejects', () => {
    started(recording(), (candidate) => candidate === menu('2'));

    openAndClose(overlay('1'));
    openAndClose(overlay('2'));

    expect(calls).toEqual(['opening menu-2', 'opened menu-2', 'closed menu-2']);
  });

  it('ignores popovers outside any menu', () => {
    host.insertAdjacentHTML('beforeend', '<div id="loose-popover" popover="auto"></div>');
    started();

    openAndClose(part('loose-popover'));

    expect(calls).toEqual([]);
  });

  it('reports nothing after stop', () => {
    const subject = started();

    subject.stop();
    openAndClose(overlay('1'));

    expect(calls).toEqual([]);
  });

  it('reports each event once after stop and start, and when started twice', () => {
    const subject = started();
    subject.stop();
    subject.start();
    subject.start();

    openAndClose(overlay('1'));

    expect(calls).toEqual(['opening menu-1', 'opened menu-1', 'closed menu-1']);
  });
});

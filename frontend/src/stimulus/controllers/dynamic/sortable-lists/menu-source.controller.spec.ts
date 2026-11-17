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

// vi.doMock is not hoisted above imports, unlike vi.mock, so the
// controllers below are imported dynamically, after these calls run.
vi.doMock('@atlaskit/pragmatic-drag-and-drop/element/adapter', () => ({
  draggable: vi.fn(() => vi.fn()),
  dropTargetForElements: vi.fn(() => vi.fn()),
  monitorForElements: vi.fn(() => vi.fn()),
}));

vi.doMock('@atlaskit/pragmatic-drag-and-drop-auto-scroll/element', () => ({
  autoScrollForElements: vi.fn(() => vi.fn()),
}));

vi.doMock('@atlaskit/pragmatic-drag-and-drop/combine', () => ({
  combine: vi.fn((...cleanups:(() => void)[]) => vi.fn(() => {
    cleanups.forEach((cleanup) => cleanup());
  })),
}));

vi.doMock('@atlaskit/pragmatic-drag-and-drop/prevent-unhandled', () => ({
  preventUnhandled: { start: vi.fn(), stop: vi.fn() },
}));

vi.doMock('@atlaskit/pragmatic-drag-and-drop/element/set-custom-native-drag-preview', () => ({
  setCustomNativeDragPreview: vi.fn(),
}));

import { fireEvent, waitFor, within } from '@testing-library/dom';
import { LiveRegionElement } from '@primer/live-region-element';
import { usePlatform } from 'core-common/testing/platform';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type { MockInstance } from 'vitest';
import type MenuSourceController from './menu-source.controller';
import type SortableListsController from '../sortable-lists.controller';
import { selectionTranslations } from './testing/selection-translations';

const menuUrl = '/projects/demo/backlogs/work_packages/menu';

describe('Sortable lists menu source controller', () => {
  let ctx:StimulusTestContext;

  usePlatform();

  beforeEach(async () => {
    document.body.appendChild(document.createElement('live-region'));
    vi.spyOn(LiveRegionElement.prototype, 'announce').mockResolvedValue(undefined);
    window.I18n.store({ en: { js: { sortable_lists: { selection: selectionTranslations } } } });

    ctx = await setupStimulusTest({
      controllers: {
        'sortable-lists': (await import('../sortable-lists.controller')).default,
        'sortable-lists--list': (await import('./list.controller')).default,
        'sortable-lists--item': (await import('./item.controller')).default,
        'sortable-lists--menu-source': (await import('./menu-source.controller')).default,
        'contextual-action-menu': (await import('../contextual-action-menu.controller')).default,
      },
    });
  });

  afterEach(() => {
    ctx.dispose();
    document.body.querySelector('live-region')?.remove();
    vi.restoreAllMocks();
  });

  // Primer's deferred card menu: the popover is an <anchored-position>
  // directly inside <action-menu>, a sub-menu one nested inside it.
  function card(id:string, { mobility = null }:{ mobility?:string|null } = {}):string {
    return `
      <li data-controller="sortable-lists--item"
          data-sortable-lists--item-id-value="${id}"
          data-sortable-lists--item-type-value="work_package"
          ${mobility ? `data-sortable-lists--item-mobility-value="${mobility}"` : ''}
          tabindex="0">
        <action-menu src="${menuUrl}?ids%5B%5D=${id}&amp;invoker_id=${id}">
          <button type="button" popovertarget="menu-${id}-overlay">More</button>
          <anchored-position id="menu-${id}-overlay" popover="auto">
            <anchored-position id="menu-${id}-submenu" popover="auto"></anchored-position>
          </anchored-position>
          <tool-tip id="menu-${id}-tooltip" popover="manual">More</tool-tip>
        </action-menu>
      </li>
    `;
  }

  async function renderRoot(cards:string[] = [card('1'), card('2'), card('3')], rootAttributes = '') {
    await ctx.mount(`
      <div id="sortable-root"
           data-controller="sortable-lists sortable-lists--menu-source"
           data-sortable-lists-sortable-lists--menu-source-outlet="#sortable-root"
           ${rootAttributes}
           data-sortable-lists-selection-enabled-value="true"
           data-sortable-lists--menu-source-url-value="${menuUrl}"
           data-sortable-lists-sortable-lists--list-outlet="#sortable-root [data-controller~='sortable-lists--list']"
           data-sortable-lists-sortable-lists--item-outlet="#sortable-root [data-controller~='sortable-lists--item']">
        <ul data-controller="sortable-lists--list"
            data-sortable-lists--list-type-value="sprint"
            data-sortable-lists--list-id-value="1"
            data-sortable-lists--list-accepted-type-value="work_package">
          ${cards.join('')}
        </ul>
      </div>
    `);

    const root = ctx.container.querySelector<HTMLElement>('#sortable-root')!;
    const items = Array.from(root.querySelectorAll<HTMLElement>('[data-sortable-lists--item-id-value]'));
    fakePrimerMenus(items);
    return { root, items };
  }

  // The real <action-menu> is not registered here; the controller reads
  // Primer's popoverElement, so the fake exposes the primary overlay as it.
  function fakePrimerMenus(items:HTMLElement[]):void {
    items.forEach((item) => {
      const menu = item.querySelector('action-menu')!;
      Object.assign(menu, { popoverElement: menu.querySelector(':scope > anchored-position') });
    });
  }

  const menuOf = (item:HTMLElement) => item.querySelector('action-menu')!;
  const isSelected = (item:HTMLElement) => item.hasAttribute('data-batch-selected');
  const click = (item:HTMLElement, init:MouseEventInit = {}) => fireEvent.click(item, init);

  function toggle(popover:Element, newState:'open'|'closed' = 'open') {
    popover.dispatchEvent(new ToggleEvent('beforetoggle', {
      newState,
      oldState: newState === 'open' ? 'closed' : 'open',
    }));
  }

  const openMenu = (item:HTMLElement, newState:'open'|'closed' = 'open') => {
    toggle(item.querySelector(':scope action-menu > anchored-position')!, newState);
  };

  it('stops settling menu scope when the root revokes its outlet', async () => {
    const { root, items } = await renderRoot();
    root.removeAttribute('data-sortable-lists-sortable-lists--menu-source-outlet');
    await ctx.nextFrame();

    openMenu(items[1]);

    expect(items[1]).not.toHaveAttribute('data-batch-selected');
    root.setAttribute('data-sortable-lists-sortable-lists--menu-source-outlet', '#sortable-root');
    await ctx.nextFrame();
    openMenu(items[1]);
    expect(items[1]).toHaveAttribute('data-batch-selected');
  });

  it('repairs the menu source reference after a morph', async () => {
    const { root, items } = await renderRoot();
    const menuSource = ctx.getController<MenuSourceController>('sortable-lists--menu-source', root);
    menuSource.disconnectRoot();
    openMenu(items[1]);
    expect(items[1]).not.toHaveAttribute('data-batch-selected');

    fireEvent(root, new CustomEvent('turbo:morph-element', { bubbles: true }));
    await ctx.nextFrame();
    openMenu(items[1]);

    expect(items[1]).toHaveAttribute('data-batch-selected');
  });

  it('does not settle scope without a root controller and recovers when it connects', async () => {
    const { root, items } = await renderRoot();
    root.setAttribute('data-controller', 'sortable-lists--menu-source');
    await ctx.nextFrame();
    openMenu(items[1]);
    expect(items[1]).not.toHaveAttribute('data-batch-selected');

    root.setAttribute('data-controller', 'sortable-lists sortable-lists--menu-source');
    await ctx.nextFrame();
    openMenu(items[1]);

    expect(items[1]).toHaveAttribute('data-batch-selected');
  });

  it('removes disconnected listeners and handles each open once after reconnect', async () => {
    const { root, items } = await renderRoot();
    const controller = ctx.getController<SortableListsController>('sortable-lists', root);
    const selectForAction = vi.spyOn(controller, 'selectForAction');
    root.setAttribute('data-controller', 'sortable-lists');
    await ctx.nextFrame();
    openMenu(items[1]);
    expect(selectForAction).not.toHaveBeenCalled();

    root.setAttribute('data-controller', 'sortable-lists sortable-lists--menu-source');
    await ctx.nextFrame();
    openMenu(items[1]);

    expect(selectForAction).toHaveBeenCalledExactlyOnceWith(items[1]);
    expect(items[1]).toHaveAttribute('data-batch-selected');
  });

  it('keeps menu scopes and endpoints local to each root across reconnect', async () => {
    const { root, items } = await renderRoot();
    const other = root.cloneNode(true) as HTMLElement;
    other.id = 'other-root';
    for (const attribute of Array.from(other.attributes)) {
      if (attribute.name.endsWith('-outlet')) other.setAttribute(attribute.name, attribute.value.replaceAll('#sortable-root', '#other-root'));
    }
    other.setAttribute('data-sortable-lists--menu-source-url-value', '/other/menu');
    other.querySelector('ul')!.innerHTML = [card('4'), card('5')].join('');
    ctx.container.append(other);
    await ctx.nextFrame();
    const otherItems = Array.from(other.querySelectorAll<HTMLElement>('[data-sortable-lists--item-id-value]'));
    fakePrimerMenus(otherItems);
    click(items[0]);
    click(items[1], { ctrlKey: true });
    click(otherItems[0]);
    click(otherItems[1], { ctrlKey: true });
    other.setAttribute('data-controller', 'sortable-lists');
    await ctx.nextFrame();
    other.setAttribute('data-controller', 'sortable-lists sortable-lists--menu-source');
    await ctx.nextFrame();

    openMenu(items[1]);
    openMenu(otherItems[1]);

    expect(menuOf(items[1])).toHaveAttribute('src', `${menuUrl}?ids%5B%5D=1&ids%5B%5D=2&invoker_id=2`);
    expect(menuOf(otherItems[1])).toHaveAttribute('src', '/other/menu?ids%5B%5D=4&ids%5B%5D=5&invoker_id=5');
  });

  it('preserves existing endpoint parameters and encodes the settled IDs', async () => {
    const { root, items } = await renderRoot([card('A&B'), card('C/D')]);
    root.setAttribute('data-sortable-lists--menu-source-url-value', `${menuUrl}?existing=1`);
    click(items[0]);
    click(items[1], { ctrlKey: true });

    openMenu(items[1]);

    const src = new URL(menuOf(items[1]).getAttribute('src')!, window.location.href);
    expect(src.searchParams.get('existing')).toBe('1');
    expect(src.searchParams.getAll('ids[]')).toEqual(['A&B', 'C/D']);
    expect(src.searchParams.get('invoker_id')).toBe('C/D');
    expect(src.pathname).toBe(menuUrl);
  });

  it('accepts a duck-typed primary open event', async () => {
    const { items } = await renderRoot();
    click(items[0]);
    click(items[1], { ctrlKey: true });
    const event = Object.assign(new Event('beforetoggle'), { newState: 'open' });
    items[1].querySelector(':scope action-menu > anchored-position')!.dispatchEvent(event);

    const src = new URL(menuOf(items[1]).getAttribute('src')!, window.location.href);
    expect(src.searchParams.getAll('ids[]')).toEqual(['1', '2']);
  });

  describe('scope settled by each menu entry point', () => {
    // The Backlogs card row: the item is the row, the card inside it hosts
    // the contextual presentation and the tab stop.
    function contextualCard(id:string, { mobility = null }:{ mobility?:string|null } = {}):string {
      return `
        <li data-controller="sortable-lists--item"
            data-sortable-lists--item-id-value="${id}"
            data-sortable-lists--item-type-value="work_package"
            ${mobility ? `data-sortable-lists--item-mobility-value="${mobility}"` : ''}>
          <div data-controller="contextual-action-menu"
               data-sortable-lists--item-target="focus"
               tabindex="0">
            <span>Story ${id}</span>
            <action-menu src="${menuUrl}?ids%5B%5D=${id}&amp;invoker_id=${id}">
              <button id="menu-${id}-button" type="button" popovertarget="menu-${id}-overlay">More</button>
              <anchored-position id="menu-${id}-overlay" popover="auto" anchor="menu-${id}-button"></anchored-position>
            </action-menu>
          </div>
        </li>
      `;
    }

    // The real <action-menu> and <anchored-position> are not registered
    // here; the presenter reads only these members.
    async function renderContextualRoot(cards:string[]) {
      const rendered = await renderRoot(cards);
      rendered.items.forEach((item) => {
        const menu = menuOf(item);
        const overlay = menu.querySelector('anchored-position')!;
        Object.assign(menu, {
          overlay,
          popoverElement: overlay,
          invokerElement: within(item).getByRole('button', { name: 'More' }),
        });
        Object.assign(overlay, { anchorElement: null, update: vi.fn() });
      });
      return rendered;
    }

    const cardOf = (item:HTMLElement) => item.querySelector<HTMLElement>('[data-controller~="contextual-action-menu"]')!;

    const entryPoints:[string, (item:HTMLElement) => void][] = [
      ['the More button', (item) => {
        fireEvent.click(within(item).getByRole('button', { name: 'More' }));
      }],
      ['a right-click', (item) => {
        const subject = within(item).getByText(/^Story/);
        fireEvent.pointerDown(subject, { button: 2, pointerType: 'mouse' });
        fireEvent.mouseDown(subject, { button: 2 });
        fireEvent.contextMenu(subject, { button: 2 });
        fireEvent.pointerUp(document.body, { button: 2, pointerType: 'mouse' });
        fireEvent.mouseUp(document.body, { button: 2 });
      }],
      ['the Context Menu key', (item) => {
        fireEvent.keyDown(cardOf(item), { key: 'ContextMenu' });
      }],
      ['Shift+F10', (item) => {
        fireEvent.keyDown(cardOf(item), { key: 'F10', shiftKey: true });
      }],
    ];

    let trace:string[];
    let srcWrites:string[];
    let announce:MockInstance;

    const recordTrace = (event:Event) => {
      if ((event as ToggleEvent).newState === 'open') {
        trace.push(event.type);
      }
    };
    const recordBeforeOpen = () => trace.push('beforeOpen');

    beforeEach(() => {
      trace = [];
      srcWrites = [];
      document.addEventListener('beforetoggle', recordTrace, true);
      ctx.container.addEventListener('contextual-action-menu:beforeOpen', recordBeforeOpen);
    });

    afterEach(() => {
      document.removeEventListener('beforetoggle', recordTrace, true);
    });

    function watchInvocation(root:HTMLElement, items:HTMLElement[]) {
      const controller = ctx.getController<SortableListsController>('sortable-lists', root);
      const selectForAction = controller.selectForAction.bind(controller);
      vi.spyOn(controller, 'selectForAction').mockImplementation((itemElement) => {
        trace.push('selectForAction');
        return selectForAction(itemElement);
      });
      items.forEach((item) => {
        const menu = menuOf(item);
        const setAttribute = menu.setAttribute.bind(menu);
        vi.spyOn(menu, 'setAttribute').mockImplementation((name, value) => {
          if (name === 'src') {
            srcWrites.push(value);
          }
          setAttribute(name, value);
        });
      });
      announce = vi.spyOn(LiveRegionElement.prototype, 'announce').mockResolvedValue(undefined);
      announce.mockClear();
    }

    const expectedTrace = (label:string) => (label === 'the More button'
      ? ['beforetoggle', 'selectForAction']
      : ['beforeOpen', 'beforetoggle', 'selectForAction']);

    describe.each(entryPoints)('opened from %s', (label, invoke) => {
      it('acts on the whole selection from a selected card and keeps the anchor', async () => {
        const { root, items } = await renderContextualRoot(['1', '2', '3', '4'].map((id) => contextualCard(id)));
        click(items[0], { ctrlKey: true });
        click(items[2], { ctrlKey: true });
        watchInvocation(root, items);

        invoke(items[0]);

        const src = `${menuUrl}?ids%5B%5D=1&ids%5B%5D=3&invoker_id=1`;
        expect(menuOf(items[0])).toHaveAttribute('src', src);
        expect(srcWrites).toEqual([src]);
        expect(trace).toEqual(expectedTrace(label));
        expect(items.filter(isSelected)).toEqual([items[0], items[2]]);

        click(items[3], { shiftKey: true });
        expect(items.filter(isSelected)).toEqual([items[0], items[2], items[3]]);
      });

      it('replaces the selection with an unselected card, which becomes the anchor', async () => {
        const { root, items } = await renderContextualRoot(['1', '2', '3'].map((id) => contextualCard(id)));
        click(items[0], { ctrlKey: true });
        click(items[1], { ctrlKey: true });
        watchInvocation(root, items);

        invoke(items[2]);

        expect(menuOf(items[2])).toHaveAttribute('src', `${menuUrl}?ids%5B%5D=3&invoker_id=3`);
        expect(srcWrites).toEqual([`${menuUrl}?ids%5B%5D=3&invoker_id=3`]);
        expect(trace).toEqual(expectedTrace(label));
        expect(items.filter(isSelected)).toEqual([items[2]]);

        click(items[1], { shiftKey: true });
        expect(items.filter(isSelected)).toEqual([items[1], items[2]]);
      });

      it('leaves selection and anchor alone for a fixed card, without announcing', async () => {
        const { root, items } = await renderContextualRoot([
          contextualCard('1', { mobility: 'fixed' }),
          contextualCard('2'),
          contextualCard('3'),
          contextualCard('4'),
        ]);
        click(items[3], { ctrlKey: true });
        click(items[1], { ctrlKey: true });
        watchInvocation(root, items);

        invoke(items[0]);

        expect(menuOf(items[0])).toHaveAttribute('src', `${menuUrl}?ids%5B%5D=1&invoker_id=1`);
        expect(srcWrites).toEqual([`${menuUrl}?ids%5B%5D=1&invoker_id=1`]);
        expect(trace).toEqual(expectedTrace(label));
        expect(items.filter(isSelected)).toEqual([items[1], items[3]]);
        expect(announce).not.toHaveBeenCalled();

        click(items[2], { shiftKey: true });
        expect(items.filter(isSelected)).toEqual([items[1], items[2], items[3]]);
      });
    });
  });

  it('sets src to the ordered batch when opened on a selected card', async () => {
    const { items } = await renderRoot();
    click(items[2], { ctrlKey: true });
    click(items[0], { ctrlKey: true });

    openMenu(items[2]);

    expect(menuOf(items[2])).toHaveAttribute('src', `${menuUrl}?ids%5B%5D=1&ids%5B%5D=3&invoker_id=3`);
  });

  it('sets src to the invoker alone and replaces the selection when opened on an unselected card', async () => {
    const { items } = await renderRoot();
    click(items[0], { ctrlKey: true });
    click(items[1], { ctrlKey: true });

    openMenu(items[2]);

    expect(menuOf(items[2])).toHaveAttribute('src', `${menuUrl}?ids%5B%5D=3&invoker_id=3`);
    expect(items.filter(isSelected)).toEqual([items[2]]);
  });

  it('keeps the selection and sends only the invoker for a fixed card', async () => {
    const { items } = await renderRoot([card('1'), card('2'), card('3', { mobility: 'fixed' })]);
    click(items[0], { ctrlKey: true });
    click(items[1], { ctrlKey: true });

    openMenu(items[2]);

    expect(menuOf(items[2])).toHaveAttribute('src', `${menuUrl}?ids%5B%5D=3&invoker_id=3`);
    expect(items.filter(isSelected)).toEqual([items[0], items[1]]);
  });

  it('settles the scope when opened from the More button', async () => {
    const { items } = await renderRoot();

    openMenu(items[1]);

    expect(items.filter(isSelected)).toEqual([items[1]]);
    expect(menuOf(items[1])).toHaveAttribute('src', `${menuUrl}?ids%5B%5D=2&invoker_id=2`);
  });

  it('writes the server-rendered src again for a one-card scope', async () => {
    const { items } = await renderRoot();
    const serverSrc = menuOf(items[0]).getAttribute('src')!;
    const setAttribute = vi.spyOn(menuOf(items[0]), 'setAttribute');

    openMenu(items[0]);

    expect(menuOf(items[0])).toHaveAttribute('src', serverSrc);
    expect(setAttribute).toHaveBeenCalledExactlyOnceWith('src', serverSrc);
  });

  it('writes an identical src again for an unchanged selection', async () => {
    const { items } = await renderRoot();
    click(items[0], { ctrlKey: true });
    click(items[1], { ctrlKey: true });
    openMenu(items[1]);
    const batchSrc = `${menuUrl}?ids%5B%5D=1&ids%5B%5D=2&invoker_id=2`;
    const setAttribute = vi.spyOn(menuOf(items[1]), 'setAttribute');

    openMenu(items[1], 'closed');
    openMenu(items[1]);

    expect(menuOf(items[1])).toHaveAttribute('src', batchSrc);
    expect(setAttribute).toHaveBeenCalledExactlyOnceWith('src', batchSrc);
  });

  it('replaces src when reopened on another card', async () => {
    const { items } = await renderRoot();
    click(items[0], { ctrlKey: true });
    click(items[1], { ctrlKey: true });
    openMenu(items[1]);

    openMenu(items[0]);

    expect(menuOf(items[0])).toHaveAttribute('src', `${menuUrl}?ids%5B%5D=1&ids%5B%5D=2&invoker_id=1`);
  });

  it('ignores beforetoggle with newState closed', async () => {
    const { items } = await renderRoot();
    click(items[0], { ctrlKey: true });
    click(items[1], { ctrlKey: true });

    openMenu(items[1], 'closed');

    expect(menuOf(items[1])).toHaveAttribute('src', `${menuUrl}?ids%5B%5D=2&invoker_id=2`);
  });

  it('ignores popovers other than the primary menu', async () => {
    const { items } = await renderRoot();

    toggle(items[1].querySelector('#menu-2-tooltip')!);
    toggle(items[1].querySelector('#menu-2-submenu')!);

    items.forEach((item) => expect(item).not.toHaveAttribute('data-batch-selected'));
  });

  it('uses the batch without selecting while the root is busy', async () => {
    const { root, items } = await renderRoot();
    click(items[0], { ctrlKey: true });
    click(items[1], { ctrlKey: true });
    root.setAttribute('data-sortable-lists-busy', 'true');

    openMenu(items[2]);
    openMenu(items[1]);

    expect(menuOf(items[2])).toHaveAttribute('src', `${menuUrl}?ids%5B%5D=3&invoker_id=3`);
    expect(menuOf(items[1])).toHaveAttribute('src', `${menuUrl}?ids%5B%5D=1&ids%5B%5D=2&invoker_id=2`);
    expect(items.filter(isSelected)).toEqual([items[0], items[1]]);
  });
  describe('menu name', () => {
    const menuLabelKey = 'js.backlogs.action_menu.menu_label';
    const singularName = 'Work package actions';

    beforeEach(() => {
      window.I18n.store({
        en: {
          js: {
            backlogs: {
              action_menu: {
                menu_label: {
                  one: singularName,
                  other: 'Actions for %{count} selected work packages',
                },
              },
            },
          },
        },
      });
    });

    // Primer's IconButton names the button by its label tooltip, and the
    // deferred list by the button, which accname does not follow further.
    function namedCard(id:string):string {
      return `
        <li data-controller="sortable-lists--item"
            data-sortable-lists--item-id-value="${id}"
            data-sortable-lists--item-type-value="work_package">
          <action-menu src="${menuUrl}?ids%5B%5D=${id}&amp;invoker_id=${id}">
            <button id="menu-${id}-button" type="button" popovertarget="menu-${id}-overlay"
                    aria-labelledby="menu-${id}-tooltip"></button>
            <tool-tip id="menu-${id}-tooltip" for="menu-${id}-button" popover="manual">${singularName}</tool-tip>
            <anchored-position id="menu-${id}-overlay" popover="auto"></anchored-position>
          </action-menu>
        </li>
      `;
    }

    async function renderNamedRoot(ids:string[], { withKey = true } = {}) {
      const rendered = await renderRoot(
        ids.map(namedCard),
        withKey ? `data-sortable-lists--menu-source-menu-label-key-value="${menuLabelKey}"` : '',
      );
      rendered.items.forEach((item) => {
        Object.assign(menuOf(item), { invokerElement: item.querySelector('button') });
      });
      return rendered;
    }

    const buttonOf = (item:HTMLElement) => within(item).getByRole('button');
    const overlayOf = (item:HTMLElement) => item.querySelector<HTMLElement>(':scope action-menu > anchored-position')!;

    // What the deferred menu response puts into the overlay.
    // Built through DOM APIs so no text ends up interpreted as HTML.
    function menuList(menuId:string, scopeCount:number):HTMLUListElement {
      const list = document.createElement('ul');
      list.setAttribute('role', 'menu');
      list.id = `${menuId}-list`;
      list.setAttribute('data-sortable-lists--menu-source-target', 'menu');
      list.setAttribute('data-sortable-lists-scope-count', String(scopeCount));
      const entry = document.createElement('li');
      entry.setAttribute('role', 'none');
      const button = document.createElement('button');
      button.setAttribute('role', 'menuitem');
      button.type = 'button';
      button.textContent = 'Move to inbox';
      entry.append(button);
      list.append(entry);
      return list;
    }

    async function loadMenu(item:HTMLElement, scopeCount:number) {
      const menuId = `menu-${item.getAttribute('data-sortable-lists--item-id-value')}`;
      const list = menuList(menuId, scopeCount);
      list.setAttribute('aria-labelledby', `${menuId}-button`);
      overlayOf(item).replaceChildren(list);
      await waitFor(() => expect(list).toHaveAttribute('aria-labelledby', `${menuId}-tooltip`));
      return list;
    }

    // ToggleEvent carries newState, which fireEvent cannot construct.
    const closeMenu = (item:HTMLElement) => {
      overlayOf(item).dispatchEvent(new ToggleEvent('toggle', { newState: 'closed', oldState: 'open' }));
    };

    it('renames the More tooltip to the batch label while open', async () => {
      const { items } = await renderNamedRoot(['1', '2', '3']);
      click(items[0], { ctrlKey: true });
      click(items[2], { ctrlKey: true });

      openMenu(items[0]);
      await loadMenu(items[0], 2);

      expect(buttonOf(items[0])).toHaveAccessibleName('Actions for 2 selected work packages');
    });

    it('restores the singular label on close', async () => {
      const { items } = await renderNamedRoot(['1', '2']);
      click(items[0], { ctrlKey: true });
      click(items[1], { ctrlKey: true });
      openMenu(items[0]);
      await loadMenu(items[0], 2);

      closeMenu(items[0]);

      expect(buttonOf(items[0])).toHaveAccessibleName(singularName);
    });

    it("points the menu's aria-labelledby at the tooltip", async () => {
      const { items } = await renderNamedRoot(['1', '2']);
      click(items[0], { ctrlKey: true });
      click(items[1], { ctrlKey: true });

      openMenu(items[0]);
      const list = await loadMenu(items[0], 2);

      expect(list).toHaveAttribute('aria-labelledby', 'menu-1-tooltip');
      expect(list).toHaveAccessibleName('Actions for 2 selected work packages');
    });

    it('keeps the singular label for a singular scope', async () => {
      const { items } = await renderNamedRoot(['1', '2']);

      openMenu(items[1]);
      const list = await loadMenu(items[1], 1);

      expect(buttonOf(items[1])).toHaveAccessibleName(singularName);
      expect(list).toHaveAccessibleName(singularName);
    });

    it('names an over-cap batch with its real count', async () => {
      const { items } = await renderNamedRoot(['1', '2']);
      click(items[0], { ctrlKey: true });
      click(items[1], { ctrlKey: true });

      openMenu(items[0]);
      await loadMenu(items[0], 51);

      expect(buttonOf(items[0])).toHaveAccessibleName('Actions for 51 selected work packages');
    });

    it('names the batch again when reopened on an already loaded menu', async () => {
      const { items } = await renderNamedRoot(['1', '2']);
      click(items[0], { ctrlKey: true });
      click(items[1], { ctrlKey: true });
      openMenu(items[0]);
      await loadMenu(items[0], 2);
      closeMenu(items[0]);

      openMenu(items[0]);

      expect(buttonOf(items[0])).toHaveAccessibleName('Actions for 2 selected work packages');
    });

    it('leaves a menu that loads while closed with its singular label', async () => {
      const { items } = await renderNamedRoot(['1', '2']);

      await loadMenu(items[0], 2);

      expect(buttonOf(items[0])).toHaveAccessibleName(singularName);
    });

    it('restores the previous card when reopened on another card', async () => {
      const { items } = await renderNamedRoot(['1', '2', '3']);
      click(items[0], { ctrlKey: true });
      click(items[1], { ctrlKey: true });
      openMenu(items[0]);
      await loadMenu(items[0], 2);

      openMenu(items[1]);
      closeMenu(items[0]);
      await loadMenu(items[1], 2);

      expect(buttonOf(items[0])).toHaveAccessibleName(singularName);
      expect(buttonOf(items[1])).toHaveAccessibleName('Actions for 2 selected work packages');
    });

    it('leaves a list header menu with its own label on close', async () => {
      const { root } = await renderNamedRoot(['1']);
      root.insertAdjacentHTML('afterbegin', `
        <action-menu>
          <button id="header-button" type="button" aria-labelledby="header-tooltip"></button>
          <tool-tip id="header-tooltip" for="header-button" popover="manual">Sprint actions</tool-tip>
          <anchored-position id="header-overlay" popover="auto"></anchored-position>
        </action-menu>
      `);
      const header = root.querySelector<HTMLElement>('action-menu')!;
      Object.assign(header, { invokerElement: header.querySelector('button') });

      header.querySelector('anchored-position')!
        .dispatchEvent(new ToggleEvent('toggle', { newState: 'closed', oldState: 'open' }));

      expect(within(header).getByRole('button')).toHaveAccessibleName('Sprint actions');
    });

    it('names the menu but keeps the server-rendered label without a key', async () => {
      const { items } = await renderNamedRoot(['1', '2'], { withKey: false });
      click(items[0], { ctrlKey: true });
      click(items[1], { ctrlKey: true });

      openMenu(items[0]);
      const list = await loadMenu(items[0], 2);

      expect(buttonOf(items[0])).toHaveAccessibleName(singularName);
      expect(list).toHaveAccessibleName(singularName);
    });

    describe('before Turbo caches the page', () => {
      const singularSrc = (id:string) => `${menuUrl}?ids%5B%5D=${id}&invoker_id=${id}`;

      // Primer's deferred card menu as the server renders it.
      function lazyCard(id:string):string {
        return `
          <li data-controller="sortable-lists--item"
              data-sortable-lists--item-id-value="${id}"
              data-sortable-lists--item-type-value="work_package">
            <action-menu>
              <button id="menu-${id}-button" type="button" popovertarget="menu-${id}-overlay"
                      aria-labelledby="menu-${id}-tooltip"></button>
              <tool-tip id="menu-${id}-tooltip" for="menu-${id}-button" popover="manual">${singularName}</tool-tip>
              <anchored-position id="menu-${id}-overlay" popover="auto">
                <div class="Overlay">
                  <div class="Overlay-body" data-target="action-menu.overlayBody"></div>
                </div>
              </anchored-position>
              <template data-target="action-menu.loaderTemplate">
                <include-fragment loading="lazy"><p>Loading</p></include-fragment>
              </template>
            </action-menu>
          </li>
        `;
      }

      async function renderLazyRoot(ids:string[]) {
        const rendered = await renderRoot(
          ids.map(lazyCard),
          `data-sortable-lists--menu-source-menu-label-key-value="${menuLabelKey}"`,
        );
        rendered.items.forEach((item) => {
          // The sources are attributes, not markup: set them without interpolating.
          const src = singularSrc(item.getAttribute('data-sortable-lists--item-id-value')!);
          menuOf(item).setAttribute('src', src);
          item.querySelector('template')!.content.querySelector('include-fragment')!.setAttribute('src', src);
          Object.assign(menuOf(item), { invokerElement: item.querySelector('button') });
        });
        return rendered;
      }

      const bodyOf = (item:HTMLElement) => item.querySelector<HTMLElement>('.Overlay-body')!;

      // What Primer does with the response: the list replaces the fragment.
      async function loadBatchMenu(item:HTMLElement, scopeCount:number) {
        const menuId = `menu-${item.getAttribute('data-sortable-lists--item-id-value')}`;
        const list = menuList(menuId, scopeCount);
        bodyOf(item).replaceChildren(list);
        await waitFor(() => expect(list).toHaveAttribute('aria-labelledby', `${menuId}-tooltip`));
      }

      const cachePage = () => fireEvent(document, new CustomEvent('turbo:before-cache'));

      async function renderLoadedBatch() {
        const rendered = await renderLazyRoot(['1', '2']);
        const [first, second] = rendered.items;
        click(first, { ctrlKey: true });
        click(second, { ctrlKey: true });
        openMenu(first);
        await loadBatchMenu(first, 2);
        return rendered;
      }

      it('resets an open menu before the page is cached without moving focus', async () => {
        const { items } = await renderLoadedBatch();
        const [first] = items;
        expect(buttonOf(first)).toHaveAccessibleName('Actions for 2 selected work packages');
        const focused = document.activeElement;

        cachePage();

        expect(buttonOf(first)).toHaveAccessibleName(singularName);
        expect(document.activeElement).toBe(focused);
      });

      it('leaves a loaded body and its src to Primer before the page is cached', async () => {
        const { items } = await renderLoadedBatch();
        const batchSrc = `${menuUrl}?ids%5B%5D=1&ids%5B%5D=2&invoker_id=1`;
        expect(menuOf(items[0])).toHaveAttribute('src', batchSrc);

        cachePage();

        expect(within(items[0]).getByRole('menu', { hidden: true })).toBeInTheDocument();
        expect(bodyOf(items[0]).querySelector('include-fragment')).not.toBeInTheDocument();
        expect(menuOf(items[0])).toHaveAttribute('src', batchSrc);
      });

      it('restores the singular name of a menu cached while open', async () => {
        const { items } = await renderLoadedBatch();
        expect(buttonOf(items[0])).toHaveAccessibleName('Actions for 2 selected work packages');

        cachePage();

        expect(buttonOf(items[0])).toHaveAccessibleName(singularName);
      });

      it('closes a menu still open when the page is cached', async () => {
        const { items } = await renderLoadedBatch();
        const overlay = items[0].querySelector<HTMLElement>(':scope action-menu > anchored-position')!;
        overlay.showPopover();
        expect(overlay).toBeVisible();

        cachePage();

        expect(overlay).not.toBeVisible();
      });

      it('leaves a menu that never opened as the server rendered it', async () => {
        const { items } = await renderLoadedBatch();
        const loader = menuOf(items[1]).querySelector('template');

        cachePage();

        expect(bodyOf(items[1])).toBeEmptyDOMElement();
        expect(menuOf(items[1]).querySelector('template')).toBe(loader);
        expect(menuOf(items[1])).toHaveAttribute('src', singularSrc('2'));
      });

      it('stops resetting menus once disconnected', async () => {
        const { root, items } = await renderLoadedBatch();
        root.removeAttribute('data-controller');
        await waitFor(() => expect(root).not.toHaveAttribute('data-controller'));
        await new Promise(requestAnimationFrame);

        cachePage();

        expect(within(items[0]).getByRole('menu', { hidden: true })).toBeInTheDocument();
      });
    });
  });
});

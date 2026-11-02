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

import { fireEvent } from '@testing-library/dom';
import { LiveRegionElement } from '@primer/live-region-element';
import { usePlatform } from 'core-common/testing/platform';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
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

  async function renderRoot(cards:string[] = [card('1'), card('2'), card('3')]) {
    await ctx.mount(`
      <div id="sortable-root"
           data-controller="sortable-lists sortable-lists--menu-source"
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
    return { root, items };
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

  it('writes the server-rendered src for a one-card scope', async () => {
    const { items } = await renderRoot();
    const serverSrc = menuOf(items[0]).getAttribute('src')!;
    const setAttribute = vi.spyOn(menuOf(items[0]), 'setAttribute');

    openMenu(items[0]);

    expect(menuOf(items[0])).toHaveAttribute('src', serverSrc);
    expect(setAttribute).not.toHaveBeenCalled();
  });

  it('writes an identical src for an unchanged selection', async () => {
    const { items } = await renderRoot();
    click(items[0], { ctrlKey: true });
    click(items[1], { ctrlKey: true });
    openMenu(items[1]);
    const setAttribute = vi.spyOn(menuOf(items[1]), 'setAttribute');

    openMenu(items[1], 'closed');
    openMenu(items[1]);

    expect(menuOf(items[1])).toHaveAttribute('src', `${menuUrl}?ids%5B%5D=1&ids%5B%5D=2&invoker_id=2`);
    expect(setAttribute).not.toHaveBeenCalled();
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
});

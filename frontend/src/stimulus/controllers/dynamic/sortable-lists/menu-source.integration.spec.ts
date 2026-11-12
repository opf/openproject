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
import { userEvent } from 'vitest/browser';
import type { Mock } from 'vitest';
import '@github/include-fragment-element';
import '@openproject/primer-view-components/app/components/primer/alpha/action_menu/action_menu_element';
import { LiveRegionElement } from '@primer/live-region-element';
import { usePlatform } from 'core-common/testing/platform';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import { selectionTranslations } from './testing/selection-translations';

const menuUrl = '/projects/demo/backlogs/work_packages/menu';

describe('Menu source with Primer deferred loading', () => {
  let ctx:StimulusTestContext;
  let fetchMock:Mock<typeof fetch>;

  usePlatform();

  beforeEach(async () => {
    document.body.appendChild(document.createElement('live-region'));
    vi.spyOn(LiveRegionElement.prototype, 'announce').mockResolvedValue(undefined);
    window.I18n.store({ en: { js: { sortable_lists: { selection: selectionTranslations } } } });
    fetchMock = vi.fn<typeof fetch>().mockImplementation(() => Promise.resolve(new Response(
      '<ul role="menu" aria-label="Work package actions"><li role="none"><button role="menuitem">Move to sprint</button></li></ul>',
      { headers: { 'Content-Type': 'text/html' } },
    )));
    vi.stubGlobal('fetch', fetchMock);
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
    vi.unstubAllGlobals();
  });

  function card(id:string):string {
    return `
      <li data-controller="sortable-lists--item"
          data-sortable-lists--item-id-value="${id}"
          data-sortable-lists--item-type-value="work_package" tabindex="0">
        <action-menu src="${menuUrl}?ids%5B%5D=${id}&amp;invoker_id=${id}">
          <button type="button" popovertarget="menu-${id}" aria-label="Work package actions">More</button>
          <anchored-position id="menu-${id}" popover="auto" data-target="action-menu.overlay">
            <div class="Overlay-body" data-target="action-menu.overlayBody"></div>
          </anchored-position>
          <template data-target="action-menu.loaderTemplate">
            <include-fragment src="${menuUrl}?ids%5B%5D=${id}&amp;invoker_id=${id}" loading="lazy">
              <ul role="menu"><li role="none"><span role="menuitem" aria-disabled="true" tabindex="-1">
                <span role="status">Loading</span>
              </span></li></ul>
            </include-fragment>
          </template>
        </action-menu>
      </li>
    `;
  }

  async function renderRoot() {
    await ctx.mount(`
      <div id="sortable-root"
           data-controller="sortable-lists sortable-lists--menu-source"
           data-sortable-lists-sortable-lists--menu-source-outlet="#sortable-root"
           data-sortable-lists-selection-enabled-value="true"
           data-sortable-lists--menu-source-url-value="${menuUrl}"
           data-sortable-lists-sortable-lists--list-outlet="#sortable-root [data-controller~='sortable-lists--list']"
           data-sortable-lists-sortable-lists--item-outlet="#sortable-root [data-controller~='sortable-lists--item']">
        <ul data-controller="sortable-lists--list"
            data-sortable-lists--list-type-value="sprint"
            data-sortable-lists--list-id-value="1"
            data-sortable-lists--list-accepted-type-value="work_package">
          ${card('1')}${card('2')}
        </ul>
      </div>
    `);
    const items = Array.from(ctx.container.querySelectorAll<HTMLElement>('[data-sortable-lists--item-id-value]'));
    const menu = items[0].querySelector<HTMLElement>('action-menu')!;
    const button = within(items[0]).getByRole('button', { name: 'Work package actions' });
    return { items, menu, button };
  }

  async function expectLoaded(menu:HTMLElement) {
    await waitFor(() => {
      expect(within(menu).getByRole('menu', { name: 'Work package actions' })).toBeVisible();
      expect(within(menu).getByRole('menuitem', { name: 'Move to sprint' })).toBeVisible();
      expect(menu.querySelector('include-fragment')).not.toBeInTheDocument();
    });
  }

  it('reuses a healthy loaded menu for the same selection', async () => {
    const { items, menu, button } = await renderRoot();
    fireEvent.click(items[0]);
    fireEvent.click(items[1], { ctrlKey: true, metaKey: true });
    await userEvent.click(button);
    await expectLoaded(menu);
    expect(fetchMock).toHaveBeenCalledTimes(1);

    await userEvent.click(button);
    await userEvent.click(button);
    await expectLoaded(menu);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('loads a new source when the selection changes', async () => {
    const { items, menu, button } = await renderRoot();
    await userEvent.click(button);
    await expectLoaded(menu);
    await userEvent.click(button);
    fireEvent.click(items[1], { ctrlKey: true, metaKey: true });
    await userEvent.click(button);
    await expectLoaded(menu);

    expect(fetchMock).toHaveBeenCalledTimes(2);
    const request = fetchMock.mock.lastCall?.[0];
    expect(request).toBeInstanceOf(Request);
    if (!(request instanceof Request)) throw new Error('Expected a fragment request');
    expect(new URL(request.url).searchParams.getAll('ids[]')).toEqual(['1', '2']);
  });

  it('closes an open menu before Turbo caches the page and leaves focus to Primer', async () => {
    const { menu, button } = await renderRoot();
    await userEvent.click(button);
    await expectLoaded(menu);
    const popover = menu.querySelector<HTMLElement>('anchored-position')!;
    expect(popover.matches(':popover-open')).toBe(true);

    fireEvent(document, new CustomEvent('turbo:before-cache'));

    expect(popover.matches(':popover-open')).toBe(false);
    // Primer refocuses the invoker when the primary menu closes (#552); the
    // snapshot must not end with focus anywhere else.
    await waitFor(() => expect(document.activeElement).toBe(button));
  });

  it('retries a failed load when reopened', async () => {
    const { menu, button } = await renderRoot();
    let resolveFailure!:(response:Response) => void;
    fetchMock.mockReturnValueOnce(new Promise<Response>((resolve) => { resolveFailure = resolve; }));
    await userEvent.click(button);
    resolveFailure(new Response('', {
      status: 500,
      headers: { 'Content-Type': 'text/html' },
    }));
    await waitFor(() => expect(menu.querySelector('include-fragment')).toHaveClass('is-error'));
    await userEvent.click(button);
    await userEvent.click(button);
    await expectLoaded(menu);
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });
});

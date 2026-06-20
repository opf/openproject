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

import { Application } from '@hotwired/stimulus';
import type { MockInstance } from 'vitest';

import type BacklogFilterSelectPanelControllerType from './backlog-filter-select-panel.controller';

interface Navigable {
  visit(this:void, url:string):void;
}

interface PanelApi {
  selectedItems:{ value:string|null }[];
  items:HTMLElement[];
  checkItem(item:HTMLElement):void;
  uncheckItem(item:HTMLElement):void;
  hide():void;
}

type PanelStub = HTMLElement & PanelApi;

const IDENTIFIER = 'backlogs--backlog-filter-select-panel';

describe('Backlogs filter select panel controller', () => {
  let application:Application;
  let fixture:HTMLElement;
  let panel:PanelStub;
  let panelHideCalls:number;
  let Controller:typeof BacklogFilterSelectPanelControllerType;
  let prototype:Navigable;

  beforeAll(async () => {
    ({ default: Controller } = await import('./backlog-filter-select-panel.controller'));
  });

  beforeEach(() => {
    // Stub the navigation seam so submitting neither hits Turbo nor leaves the
    // test page; the spy doubles as the submit assertion.
    prototype = Controller.prototype as unknown as Navigable;
    vi.spyOn(prototype, 'visit').mockReturnValue(undefined);

    panelHideCalls = 0;

    fixture = document.createElement('div');
    document.body.appendChild(fixture);

    application = Application.start();
    application.register(IDENTIFIER, Controller);
  });

  afterEach(() => {
    application?.stop();
    fixture.remove();
    vi.restoreAllMocks();
  });

  // Renders the panel + footer buttons and waits (on real timers) for Stimulus
  // to connect the controller, which binds asynchronously via a MutationObserver.
  async function mount({
    url = '/projects/demo/backlogs',
    items = [] as string[],
    checked = [] as string[],
  } = {}) {
    window.history.replaceState({}, '', url);

    fixture.innerHTML = `
      <div
        data-controller="${IDENTIFIER}"
        data-${IDENTIFIER}-filter-key-value="bucket_ids"
        data-action="itemActivated->${IDENTIFIER}#refreshButtons panelClosed->${IDENTIFIER}#revertOnClose"
      >
        <select-panel></select-panel>
        <button type="button" data-${IDENTIFIER}-target="clearButton"
                data-action="click->${IDENTIFIER}#clear" disabled>Clear</button>
        <button type="button" data-${IDENTIFIER}-target="applyButton"
                data-action="click->${IDENTIFIER}#apply" disabled>Apply</button>
      </div>
    `;

    const root = fixture.querySelector<HTMLElement>(`[data-controller="${IDENTIFIER}"]`)!;
    setupPanel(root, items, checked);

    await new Promise((resolve) => { setTimeout(resolve, 0); });
    return root;
  }

  // Wires a minimal fake of Primer's SelectPanelElement onto <select-panel>:
  // items carry their value on a `.ActionListContent[data-value]`, and
  // check/uncheck mutate the selection and fire `itemActivated`, as Primer does.
  function setupPanel(root:HTMLElement, items:string[], checked:string[]) {
    const element = root.querySelector('select-panel') as unknown as PanelStub;
    const selected = new Set(checked);

    element.innerHTML = items.map((value) => `
      <li><span class="ActionListContent" data-value="${value}"
                aria-selected="${selected.has(value)}"></span></li>`).join('');

    const setItem = (item:HTMLElement, on:boolean) => {
      const content = item.querySelector('.ActionListContent')!;
      const value = content.getAttribute('data-value')!;
      if (on === selected.has(value)) return;

      if (on) { selected.add(value); } else { selected.delete(value); }
      content.setAttribute('aria-selected', String(on));
      element.dispatchEvent(new CustomEvent('itemActivated', { bubbles: true }));
    };

    Object.defineProperty(element, 'items', {
      configurable: true,
      get: () => Array.from(element.querySelectorAll('li')),
    });
    Object.defineProperty(element, 'selectedItems', {
      configurable: true,
      get: () => [...selected].map((value) => ({ value })),
    });
    element.checkItem = (item:HTMLElement) => setItem(item, true);
    element.uncheckItem = (item:HTMLElement) => setItem(item, false);
    element.hide = () => { panelHideCalls += 1; };

    panel = element;
  }

  // Simulates a user toggling an item in the open panel (fires itemActivated).
  function toggle(value:string, on:boolean) {
    const item = panel.items.find(
      (li) => li.querySelector('.ActionListContent')?.getAttribute('data-value') === value,
    )!;
    if (on) { panel.checkItem(item); } else { panel.uncheckItem(item); }
  }

  function controllerFor(root:HTMLElement):BacklogFilterSelectPanelControllerType {
    return application.getControllerForElementAndIdentifier(
      root, IDENTIFIER,
    ) as unknown as BacklogFilterSelectPanelControllerType;
  }

  const applyButton = () => fixture.querySelector<HTMLButtonElement>(`[data-${IDENTIFIER}-target="applyButton"]`)!;
  const clearButton = () => fixture.querySelector<HTMLButtonElement>(`[data-${IDENTIFIER}-target="clearButton"]`)!;

  function lastVisitedUrl():URL {
    const calls = (prototype.visit as unknown as MockInstance<(url:string) => void>).mock.calls;
    const [url] = calls.at(-1)!;
    return new URL(url, window.location.origin);
  }

  function selectedValues():string[] {
    return panel.selectedItems.map((item) => item.value).filter((v):v is string => v != null);
  }

  describe('button enablement', () => {
    it('enables Apply when the selection differs from the applied filter and disables it when reverted', async () => {
      await mount({ url: '/projects/demo/backlogs?bucket_ids=1', items: ['1', '2', '3'], checked: ['1'] });

      expect(applyButton()).toBeDisabled();

      toggle('2', true);
      expect(applyButton()).toBeEnabled();

      toggle('2', false);
      expect(applyButton()).toBeDisabled();
    });

    it('treats whitespace around comma-delimited ids as already applied (Apply stays disabled)', async () => {
      // The server tolerates padded, comma-delimited params (e.g. "1, 2 ,3"),
      // so a URL carrying them must read back as the same applied selection.
      await mount({ url: '/projects/demo/backlogs?bucket_ids=1,%202%20,3', items: ['1', '2', '3'], checked: ['1', '2', '3'] });

      // Round-trip a toggle to re-run the change check without altering the
      // selection: it must still equal the (padded) applied filter.
      toggle('2', false);
      toggle('2', true);

      expect(applyButton()).toBeDisabled();
    });

    it('enables Clear only while something is selected', async () => {
      await mount({ url: '/projects/demo/backlogs', items: ['1', '2'], checked: [] });

      expect(clearButton()).toBeDisabled();

      toggle('1', true);
      expect(clearButton()).toBeEnabled();

      toggle('1', false);
      expect(clearButton()).toBeDisabled();
    });
  });

  describe('apply', () => {
    it('navigates the backlogs frame with the current selection, preserving other params', async () => {
      const root = await mount({
        url: '/projects/demo/backlogs?bucket_ids=1&sprint_ids=9',
        items: ['1', '2'],
        checked: ['1'],
      });
      toggle('2', true);

      controllerFor(root).apply();

      expect(prototype.visit).toHaveBeenCalledTimes(1);
      const params = lastVisitedUrl().searchParams;
      expect(params.get('bucket_ids')).toBe('1,2');
      expect(params.get('sprint_ids')).toBe('9');
    });
  });

  describe('clear', () => {
    it('navigates with an empty selection and removes the filter param', async () => {
      const root = await mount({
        url: '/projects/demo/backlogs?bucket_ids=1',
        items: ['1', '2'],
        checked: ['1'],
      });

      controllerFor(root).clear();

      expect(prototype.visit).toHaveBeenCalledTimes(1);
      expect(lastVisitedUrl().searchParams.has('bucket_ids')).toBe(false);
      expect(selectedValues()).toEqual([]);
    });

    it('deselects and closes without navigating when the filter is already empty', async () => {
      const root = await mount({ url: '/projects/demo/backlogs', items: ['1', '2'], checked: [] });
      toggle('1', true);
      toggle('2', true);

      controllerFor(root).clear();

      expect(prototype.visit).not.toHaveBeenCalled();
      expect(panelHideCalls).toBe(1);
      expect(selectedValues()).toEqual([]);
    });
  });

  describe('close (native dismiss)', () => {
    it('reverts the selection to the applied filter without submitting', async () => {
      const root = await mount({
        url: '/projects/demo/backlogs?bucket_ids=1',
        items: ['1', '2'],
        checked: ['1'],
      });
      toggle('2', true);
      toggle('1', false);
      expect(selectedValues()).toEqual(['2']);

      controllerFor(root).revertOnClose();

      expect(prototype.visit).not.toHaveBeenCalled();
      expect(selectedValues()).toEqual(['1']);
    });

    it('does not revert once a submit is in flight', async () => {
      const root = await mount({
        url: '/projects/demo/backlogs?bucket_ids=1',
        items: ['1', '2'],
        checked: ['1'],
      });
      toggle('2', true);
      const controller = controllerFor(root);

      controller.apply();
      controller.revertOnClose();

      expect(prototype.visit).toHaveBeenCalledTimes(1);
      expect(selectedValues()).toEqual(['1', '2']);
    });
  });
});

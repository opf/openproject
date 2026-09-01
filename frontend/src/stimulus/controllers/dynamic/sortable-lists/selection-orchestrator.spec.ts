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

import { LiveRegionElement } from '@primer/live-region-element';
import { type MockInstance } from 'vitest';
import type { SelectionHost } from './selection-orchestrator';

// No Stimulus application, no outlets, no controller lifecycle: the host
// port lets selection be driven over a plain DOM.
describe('SelectionOrchestrator', () => {
  // Imported dynamically, after the mock above registers: spec files share
  // one module registry (the runner does not isolate them), so a static
  // import here would bind whatever another spec already pulled in — with
  // the real platform helper baked in.
  let SelectionOrchestrator:typeof import('./selection-orchestrator').SelectionOrchestrator;
  let batchSelectedAttribute:string;

  beforeAll(async () => {
    ({ SelectionOrchestrator } = await import('./selection-orchestrator'));
    ({ batchSelectedAttribute } = await import('./selection'));
  });

  let root:HTMLElement;
  let announceSpy:MockInstance<typeof LiveRegionElement.prototype.announce>;
  let busy = false;
  let focused:HTMLElement|null = null;

  function hostFor(element:HTMLElement):SelectionHost {
    return {
      rootElement: element,
      get busy() { return busy; },
      announcementScope: 'js.sortable_lists.selection',
      descriptionId: 'selection-description',
      focusItem: (item) => { focused = item; },
      ownerRowsContainer: (item) => {
        const list = item.closest<HTMLElement>('[data-controller~="sortable-lists--list"]');
        return list ? (list.querySelector<HTMLElement>(':scope > ul') ?? list) : null;
      },
    };
  }

  beforeEach(() => {
    busy = false;
    focused = null;
    root = document.createElement('div');
    root.setAttribute('data-controller', 'sortable-lists');
    root.innerHTML = `
      <div data-controller="sortable-lists--list"
           data-sortable-lists--list-type-value="sprint"
           data-sortable-lists--list-id-value="7">
        <ul>
          <li data-controller="sortable-lists--item" data-sortable-lists--item-id-value="1" data-sortable-lists--item-type-value="work_package"></li>
          <li data-controller="sortable-lists--item" data-sortable-lists--item-id-value="2" data-sortable-lists--item-type-value="work_package"></li>
          <li data-controller="sortable-lists--item" data-sortable-lists--item-id-value="3" data-sortable-lists--item-type-value="work_package"></li>
        </ul>
      </div>
      <div data-controller="sortable-lists--list"
           data-sortable-lists--list-type-value="section"
           data-sortable-lists--list-id-value="sections">
        <ul>
          <li data-controller="sortable-lists--item" data-sortable-lists--item-id-value="1"
              data-sortable-lists--item-type-value="section"></li>
        </ul>
      </div>
      <div data-controller="sortable-lists--list"
           data-sortable-lists--list-type-value="sprint"
           data-sortable-lists--list-id-value="8">
        <ul>
          <li data-controller="sortable-lists--item" data-sortable-lists--item-id-value="4" data-sortable-lists--item-type-value="work_package"></li>
          <li data-controller="sortable-lists--item" data-sortable-lists--item-id-value="5" data-sortable-lists--item-type-value="work_package"></li>
        </ul>
      </div>
    `;
    document.body.append(root, document.createElement('live-region'));
    announceSpy = vi.spyOn(LiveRegionElement.prototype, 'announce');
    pretendPlatform('Windows');
    window.I18n.store({
      en: {
        js: {
          sortable_lists: {
            selection: {
              cleared: 'Selection cleared.',
              not_selectable: 'Selection unchanged. This item cannot be selected.',
              range_blocked: 'Selection unchanged. That range contains an item that takes no part in this list\'s ordering.',
              range_restarted: { one: 'Could not extend the range. 1 item selected.', other: 'Could not extend the range. %{count} items selected.' },
              range_unavailable: 'Selection unchanged. Expand this list to select that range.',
              selected: { one: '1 item selected.', other: '%{count} items selected.' },
            },
          },
        },
      },
    });
  });

  const userAgentDataDescriptor = Object.getOwnPropertyDescriptor(navigator, 'userAgentData');

  afterEach(() => {
    root.remove();
    document.querySelector('live-region')?.remove();
    announceSpy.mockRestore();
    restorePlatform();
  });

  function pretendPlatform(platform:string):void {
    Object.defineProperty(navigator, 'userAgentData', {
      value: { platform },
      configurable: true,
    });
  }

  function restorePlatform():void {
    if (userAgentDataDescriptor) {
      Object.defineProperty(navigator, 'userAgentData', userAgentDataDescriptor);
    } else {
      delete (navigator as { userAgentData?:unknown }).userAgentData;
    }
  }

  // Type-qualified, because the fixture deliberately holds a section and a
  // work package that share id 1 — the collision a nested topology makes
  // routine.
  const itemOfType = (type:string, id:string) => root.querySelector<HTMLElement>(
    `[data-sortable-lists--item-type-value="${type}"][data-sortable-lists--item-id-value="${id}"]`,
  )!;
  const item = (id:string) => itemOfType('work_package', id);
  const sectionItem = (id:string) => itemOfType('section', id);
  const isSelected = (element:HTMLElement) => element.hasAttribute(batchSelectedAttribute);
  const clickOn = (element:HTMLElement, init:MouseEventInit = {}) => {
    const event = new MouseEvent('click', { bubbles: true, cancelable: true, ...init });
    Object.defineProperty(event, 'target', { value: element });
    return event;
  };

  it('selects the clicked card without any Stimulus wiring', () => {
    const orchestrator = new SelectionOrchestrator(hostFor(root));

    orchestrator.handleClick(clickOn(item('1')));

    expect(isSelected(item('1'))).toBe(true);
    expect(orchestrator.selectedIds()).toEqual(['1']);
  });

  it('extends a range from the anchor', () => {
    const orchestrator = new SelectionOrchestrator(hostFor(root));

    orchestrator.handleClick(clickOn(item('1')));
    orchestrator.handleClick(clickOn(item('3'), { shiftKey: true }));

    expect(orchestrator.selectedIds()).toEqual(['1', '2', '3']);
  });

  it('routes focus through the host rather than touching the element', () => {
    const orchestrator = new SelectionOrchestrator(hostFor(root));
    const event = new KeyboardEvent('keydown', { key: 'ArrowDown', bubbles: true, cancelable: true });
    Object.defineProperty(event, 'target', { value: item('1') });

    orchestrator.handleKeydown(event);

    expect(focused).toBe(item('2'));
  });

  it('reads busy from the host and refuses to mutate while a move is in flight', () => {
    const orchestrator = new SelectionOrchestrator(hostFor(root));
    busy = true;

    orchestrator.handleClick(clickOn(item('1')));

    expect(orchestrator.selectedIds()).toEqual([]);
  });

  it('clears presentation without disturbing the model', () => {
    const orchestrator = new SelectionOrchestrator(hostFor(root));
    orchestrator.handleClick(clickOn(item('1')));

    orchestrator.clearPresentation();

    expect(isSelected(item('1'))).toBe(false);
    expect(orchestrator.selectedIds()).toEqual(['1']);
  });

  // Falling through mid-move would open the details pane on a card the batch
  // was not allowed to follow.
  it('consumes a plain click while a move is in flight', () => {
    const orchestrator = new SelectionOrchestrator(hostFor(root));
    orchestrator.handleClick(clickOn(item('1')));
    busy = true;

    const event = clickOn(item('2'));
    orchestrator.handleClick(event);

    expect(event.defaultPrevented).toBe(true);
    expect(orchestrator.selectedIds()).toEqual(['1']);
  });

  describe('announcements', () => {
    const spoken = () => announceSpy.mock.calls.map((call) => call[0]);

    // A resized range of the same size still changed, and has no details
    // pane to serve as its own feedback.
    it('announces a range that swaps membership at the same size', () => {
      const orchestrator = new SelectionOrchestrator(hostFor(root));
      orchestrator.handleClick(clickOn(item('2')));
      orchestrator.handleClick(clickOn(item('3'), { shiftKey: true }));
      announceSpy.mockClear();

      orchestrator.handleClick(clickOn(item('1'), { shiftKey: true }));

      expect(orchestrator.selectedIds()).toEqual(['1', '2']);
      expect(spoken()).toEqual(['2 items selected.']);
    });

    // The baseline is what the previous render painted: tracking the last
    // announcement would leave a stale one behind a silent render.
    it('stays silent when a selection gesture changes nothing after a silent click', () => {
      const orchestrator = new SelectionOrchestrator(hostFor(root));
      orchestrator.handleClick(clickOn(item('1')));
      orchestrator.handleClick(clickOn(item('2')));
      announceSpy.mockClear();

      orchestrator.handleClick(clickOn(item('2'), { shiftKey: true }));

      expect(orchestrator.selectedIds()).toEqual(['2']);
      expect(spoken()).toEqual([]);
    });

    it('stays silent on a plain click that swaps a one-card selection', () => {
      const orchestrator = new SelectionOrchestrator(hostFor(root));
      orchestrator.handleClick(clickOn(item('1')));
      announceSpy.mockClear();

      orchestrator.handleClick(clickOn(item('2')));

      expect(orchestrator.selectedIds()).toEqual(['2']);
      expect(spoken()).toEqual([]);
    });

    it('still announces a plain click that changes the count', () => {
      const orchestrator = new SelectionOrchestrator(hostFor(root));
      orchestrator.handleClick(clickOn(item('1')));
      orchestrator.handleClick(clickOn(item('3'), { shiftKey: true }));
      announceSpy.mockClear();

      orchestrator.handleClick(clickOn(item('2')));

      expect(spoken()).toEqual(['1 item selected.']);
    });
  });

  describe('keyboard and pointer edge cases', () => {
    const keydownOn = (element:HTMLElement, key:string, init:KeyboardEventInit = {}) => {
      const event = new KeyboardEvent('keydown', { key, bubbles: true, cancelable: true, ...init });
      Object.defineProperty(event, 'target', { value: element });
      return event;
    };

    // Consuming the key with nothing to select would block the browser's own
    // select-all and announce nothing in its place.
    it('leaves Ctrl/Cmd+A alone when nothing is selectable', () => {
      root.querySelectorAll('[data-sortable-lists--item-id-value]')
        .forEach((el) => el.setAttribute('data-sortable-lists--item-mobility-value', 'fixed'));
      const orchestrator = new SelectionOrchestrator(hostFor(root));
      const event = keydownOn(item('1'), 'a', { ctrlKey: true });

      orchestrator.handleKeydown(event);

      expect(event.defaultPrevented).toBe(false);
      expect(orchestrator.selectedIds()).toEqual([]);
    });

    it('still consumes Ctrl/Cmd+A when there is something to select', () => {
      const orchestrator = new SelectionOrchestrator(hostFor(root));
      const event = keydownOn(item('1'), 'a', { ctrlKey: true });

      orchestrator.handleKeydown(event);

      expect(event.defaultPrevented).toBe(true);
      expect(orchestrator.selectedIds()).toEqual(['1', '2', '3']);
    });

    it('anchors select-all inside the list when the focused card is fixed', () => {
      item('1').setAttribute('data-sortable-lists--item-mobility-value', 'fixed');
      const orchestrator = new SelectionOrchestrator(hostFor(root));

      orchestrator.handleKeydown(keydownOn(item('1'), 'a', { ctrlKey: true }));

      expect(orchestrator.selectedIds()).toEqual(['2', '3']);
      // The fallback anchor is the first orderable card of the same list, so
      // a follow-up Shift ranges within it rather than from another list.
      orchestrator.handleKeydown(keydownOn(item('3'), ' ', { shiftKey: true }));
      expect(orchestrator.selectedIds()).toEqual(['2', '3']);
    });

    // Select all binds to the platform's one multi-select modifier: ⌘ on
    // Apple platforms, Ctrl elsewhere — never the other way around.
    it('consumes Cmd+A on Apple platforms', () => {
      pretendPlatform('macOS');
      const orchestrator = new SelectionOrchestrator(hostFor(root));
      const event = keydownOn(item('1'), 'a', { metaKey: true });

      orchestrator.handleKeydown(event);

      expect(event.defaultPrevented).toBe(true);
      expect(orchestrator.selectedIds()).toEqual(['1', '2', '3']);
    });

    it('leaves Ctrl+A alone on Apple platforms', () => {
      pretendPlatform('macOS');
      const orchestrator = new SelectionOrchestrator(hostFor(root));
      const event = keydownOn(item('1'), 'a', { ctrlKey: true });

      orchestrator.handleKeydown(event);

      expect(event.defaultPrevented).toBe(false);
      expect(orchestrator.selectedIds()).toEqual([]);
    });

    it('leaves Meta+A alone off Apple platforms', () => {
      const orchestrator = new SelectionOrchestrator(hostFor(root));
      const event = keydownOn(item('1'), 'a', { metaKey: true });

      orchestrator.handleKeydown(event);

      expect(event.defaultPrevented).toBe(false);
      expect(orchestrator.selectedIds()).toEqual([]);
    });

    // With nothing selectable in this list, the browser's own select-all
    // keeps the gesture even though another list has cards.
    it('leaves Ctrl/Cmd+A alone when only other lists are selectable', () => {
      root.querySelectorAll('[data-sortable-lists--list-id-value="7"] [data-sortable-lists--item-id-value]')
        .forEach((el) => el.setAttribute('data-sortable-lists--item-mobility-value', 'fixed'));
      const orchestrator = new SelectionOrchestrator(hostFor(root));
      const event = keydownOn(item('1'), 'a', { ctrlKey: true });

      orchestrator.handleKeydown(event);

      expect(event.defaultPrevented).toBe(false);
      expect(orchestrator.selectedIds()).toEqual([]);
    });

    // Holding Space would otherwise toggle the card over and over.
    it('ignores a repeated Space keydown', () => {
      const orchestrator = new SelectionOrchestrator(hostFor(root));
      orchestrator.handleKeydown(keydownOn(item('1'), ' '));

      orchestrator.handleKeydown(keydownOn(item('1'), ' ', { repeat: true }));

      expect(orchestrator.selectedIds()).toEqual(['1']);
    });

    it('refuses to extend a range onto a fixed card', () => {
      item('2').setAttribute('data-sortable-lists--item-mobility-value', 'fixed');
      const orchestrator = new SelectionOrchestrator(hostFor(root));

      orchestrator.handleKeydown(keydownOn(item('1'), 'ArrowDown', { shiftKey: true }));

      expect(isSelected(item('2'))).toBe(false);
      expect(orchestrator.selectedIds()).toEqual([]);
    });

    // Ctrl-click opens the contextual menu on Apple platforms: it must
    // neither toggle nor fall through to the ordinary-click path.
    it('ignores Ctrl-click entirely on Apple platforms', () => {
      pretendPlatform('macOS');
      const orchestrator = new SelectionOrchestrator(hostFor(root));
      orchestrator.handleClick(clickOn(item('1')));

      const event = clickOn(item('2'), { ctrlKey: true });
      orchestrator.handleClick(event);

      expect(orchestrator.selectedIds()).toEqual(['1']);
      expect(isSelected(item('2'))).toBe(false);
      expect(event.defaultPrevented).toBe(false);
    });

    it('still treats Ctrl-click as multi-select elsewhere', () => {
      pretendPlatform('Windows');
      const orchestrator = new SelectionOrchestrator(hostFor(root));
      orchestrator.handleClick(clickOn(item('1')));

      orchestrator.handleClick(clickOn(item('2'), { ctrlKey: true }));

      expect(orchestrator.selectedIds()).toEqual(['1', '2']);
    });

    // Meta is not an alternate multi-select modifier off Apple platforms: a
    // Meta-click classifies as an ordinary click and replaces the batch.
    it('does not treat Meta-click as multi-select elsewhere', () => {
      pretendPlatform('Windows');
      const orchestrator = new SelectionOrchestrator(hostFor(root));
      orchestrator.handleClick(clickOn(item('1')));

      orchestrator.handleClick(clickOn(item('2'), { metaKey: true }));

      expect(orchestrator.selectedIds()).toEqual(['2']);
    });
  });

  // collapseForDrag stamps the anchor at drag start, so a cross-list drop
  // leaves it naming the source list. Without a rebind the next Shift in the
  // destination reads as cross-list and restarts instead of extending.
  it('extends a range after the anchored card moved to another list', () => {
    const orchestrator = new SelectionOrchestrator(hostFor(root));
    const moved = item('1');
    orchestrator.handleClick(clickOn(moved));

    root.querySelector('[data-sortable-lists--list-id-value="8"] ul')!.prepend(moved);
    orchestrator.reconcile();
    orchestrator.handleClick(clickOn(item('4'), { shiftKey: true }));

    expect(orchestrator.selectedIds()).toEqual(['1', '4']);
  });

  describe('one batch, one item type', () => {
    // Section 1 and work package 1 are different items that happen to share
    // an id, which is what a nested topology makes routine.
    it('does not paint an item of another type that shares an id', () => {
      const orchestrator = new SelectionOrchestrator(hostFor(root));

      orchestrator.handleClick(clickOn(item('1')));

      expect(isSelected(item('1'))).toBe(true);
      expect(isSelected(sectionItem('1'))).toBe(false);
    });

    it('restarts the batch when Ctrl/Cmd-click lands on another type', () => {
      const orchestrator = new SelectionOrchestrator(hostFor(root));
      orchestrator.handleClick(clickOn(item('1')));
      orchestrator.handleClick(clickOn(item('2'), { ctrlKey: true }));

      orchestrator.handleClick(clickOn(sectionItem('1'), { ctrlKey: true }));

      expect(orchestrator.selectedIds()).toEqual(['1']);
      expect(isSelected(sectionItem('1'))).toBe(true);
      expect(isSelected(item('1'))).toBe(false);
    });

    it('restarts the batch when Space toggles another type', () => {
      const orchestrator = new SelectionOrchestrator(hostFor(root));
      orchestrator.handleClick(clickOn(item('1')));

      const event = new KeyboardEvent('keydown', { key: ' ', bubbles: true, cancelable: true });
      Object.defineProperty(event, 'target', { value: sectionItem('1') });
      orchestrator.handleKeydown(event);

      expect(isSelected(sectionItem('1'))).toBe(true);
      expect(isSelected(item('1'))).toBe(false);
    });

    it('scopes select-all to the anchoring candidate type', () => {
      const orchestrator = new SelectionOrchestrator(hostFor(root));
      const event = new KeyboardEvent('keydown', { key: 'a', ctrlKey: true, bubbles: true, cancelable: true });
      Object.defineProperty(event, 'target', { value: sectionItem('1') });

      orchestrator.handleKeydown(event);

      expect(orchestrator.selectedIds()).toEqual(['1']);
      expect(isSelected(sectionItem('1'))).toBe(true);
      expect(isSelected(item('2'))).toBe(false);
    });

    // A bare-id lookup would find the section first, since it appears
    // earlier in document order, and rebind the anchor to the wrong list.
    it('rebinds the anchor to its own type when an earlier item shares its id', () => {
      const orchestrator = new SelectionOrchestrator(hostFor(root));
      const moved = item('1');
      orchestrator.handleClick(clickOn(moved));

      root.querySelector('[data-sortable-lists--list-id-value="8"] ul')!.prepend(moved);
      orchestrator.reconcile();
      orchestrator.handleClick(clickOn(item('4'), { shiftKey: true }));

      expect(orchestrator.selectedIds()).toEqual(['1', '4']);
    });
  });

  it('drops members that a morph removed from the document', () => {
    const orchestrator = new SelectionOrchestrator(hostFor(root));
    orchestrator.handleClick(clickOn(item('1')));
    orchestrator.handleClick(clickOn(item('2'), { ctrlKey: true }));
    item('1').remove();

    orchestrator.reconcile();

    expect(orchestrator.selectedIds()).toEqual(['2']);
    expect(announceSpy).toHaveBeenCalled();
  });
});

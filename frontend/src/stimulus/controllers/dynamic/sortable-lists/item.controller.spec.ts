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

vi.mock('@atlaskit/pragmatic-drag-and-drop/combine', () => ({
  combine: vi.fn((...cleanups:(() => void)[]) => vi.fn(() => {
    cleanups.forEach((cleanup) => cleanup());
  })),
}));

vi.mock('@atlaskit/pragmatic-drag-and-drop/element/adapter', () => ({
  draggable: vi.fn(() => vi.fn()),
  dropTargetForElements: vi.fn(() => vi.fn()),
  monitorForElements: vi.fn(() => vi.fn()),
}));

vi.mock('@atlaskit/pragmatic-drag-and-drop/prevent-unhandled', () => ({
  preventUnhandled: {
    start: vi.fn(),
    stop: vi.fn(),
  },
}));

vi.mock('@atlaskit/pragmatic-drag-and-drop/element/set-custom-native-drag-preview', () => ({
  setCustomNativeDragPreview: vi.fn(),
}));

import type { draggable as draggableFn, dropTargetForElements as dropTargetForElementsFn } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';
import type { setCustomNativeDragPreview as setCustomNativeDragPreviewFn } from '@atlaskit/pragmatic-drag-and-drop/element/set-custom-native-drag-preview';
import type { preventUnhandled as preventUnhandledType } from '@atlaskit/pragmatic-drag-and-drop/prevent-unhandled';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type { ActionEvent } from '@hotwired/stimulus';
import type ItemControllerType from './item.controller';
import type { SortableListsRoot } from './drag-and-drop';

describe('Sortable lists item controller', () => {
  let draggable:typeof draggableFn;
  let dropTargetForElements:typeof dropTargetForElementsFn;
  let preventUnhandled:typeof preventUnhandledType;
  let setCustomNativeDragPreview:typeof setCustomNativeDragPreviewFn;
  let ItemController:typeof ItemControllerType;
  let sortableItemData:typeof import('./drag-and-drop').sortableItemData;

  interface TestItemController {
    renderDropIndicator(edge:'top'|'bottom'|null):void;
    clearDropIndicator():void;
    disconnect():void;
  }

  beforeAll(async () => {
    ({ draggable, dropTargetForElements } = await import('@atlaskit/pragmatic-drag-and-drop/element/adapter'));
    ({ preventUnhandled } = await import('@atlaskit/pragmatic-drag-and-drop/prevent-unhandled'));
    ({ setCustomNativeDragPreview } = await import('@atlaskit/pragmatic-drag-and-drop/element/set-custom-native-drag-preview'));
    ({ default: ItemController } = await import('./item.controller'));
    ({ sortableItemData } = await import('./drag-and-drop'));
  });

  function controllerFor(element:HTMLElement) {
    const controller = Object.create(ItemController.prototype) as unknown as TestItemController;

    Object.defineProperty(controller, 'element', { value: element });
    Object.defineProperty(controller, 'idValue', { value: '1' });
    Object.defineProperty(controller, 'typeValue', { value: 'item' });

    return controller;
  }

  function fakeRoot(
    element = document.createElement('div'),
    { busy = false, ownerListElement = null, ownerRowsContainer = () => null }:{
      busy?:boolean;
      ownerListElement?:HTMLElement|null;
      ownerRowsContainer?:(itemElement:HTMLElement) => HTMLElement|null;
    } = {},
  ):SortableListsRoot {
    Object.defineProperty(element, 'isConnected', { value: true, configurable: true });
    return {
      element,
      busy,
      moveInDirection: vi.fn(),
      moveAvailability: vi.fn(() => null),
      ownerListElementOf: vi.fn(() => ownerListElement),
      ownerRowsContainer: vi.fn(ownerRowsContainer),
    };
  }

  function connectedControllerFor(
    element:HTMLElement,
    {
      handle = null,
      root = fakeRoot(),
      confinedValue = false,
      externalUrl = null,
      label = null,
    }:{
      handle?:HTMLElement|null;
      root?:SortableListsRoot|null;
      confinedValue?:boolean;
      externalUrl?:string|null;
      label?:string|null;
    } = {},
  ) {
    const controller = Object.create(ItemController.prototype) as InstanceType<typeof ItemControllerType>;

    Object.defineProperty(controller, 'element', { value: element });
    Object.defineProperty(controller, 'idValue', { value: '123' });
    Object.defineProperty(controller, 'hasIdValue', { value: true });
    Object.defineProperty(controller, 'typeValue', { value: 'item' });
    Object.defineProperty(controller, 'hasTypeValue', { value: true });
    Object.defineProperty(controller, 'confinedValue', { value: confinedValue });
    Object.defineProperty(controller, 'externalUrlValue', { value: externalUrl ?? '' });
    Object.defineProperty(controller, 'hasExternalUrlValue', { value: externalUrl !== null });
    Object.defineProperty(controller, 'labelValue', { value: label ?? '' });
    Object.defineProperty(controller, 'hasLabelValue', { value: label !== null });
    Object.defineProperty(controller, 'hasHandleTarget', { value: handle !== null });
    if (handle) {
      Object.defineProperty(controller, 'handleTarget', { value: handle });
    }

    controller.connect();
    if (root) {
      controller.connectRoot(root);
    }

    return controller;
  }

  function draggableArgs(element = document.createElement('article')) {
    return {
      dragHandle: null,
      element,
      input: {} as never,
    };
  }

  function dragEventPayload(element = document.createElement('article')) {
    return {
      location: { current: { input: { clientX: 0, clientY: 0 } } } as never,
      source: {
        data: {},
        dragHandle: null,
        element,
      },
    };
  }

  beforeEach(() => {
    vi.clearAllMocks();
    vi.mocked(dropTargetForElements).mockImplementation(({ element }) => {
      element.setAttribute('data-drop-target-for-element', 'true');

      return vi.fn(() => {
        element.removeAttribute('data-drop-target-for-element');
      });
    });
  });

  function connectItem({ id, type }:{ id:string; type:string }) {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);
    const controller = Object.create(ItemController.prototype) as InstanceType<typeof ItemControllerType>;

    Object.defineProperty(controller, 'element', { value: document.createElement('li') });
    Object.defineProperty(controller, 'idValue', { value: id });
    Object.defineProperty(controller, 'hasIdValue', { value: id !== '' });
    Object.defineProperty(controller, 'typeValue', { value: type });
    Object.defineProperty(controller, 'hasTypeValue', { value: type !== '' });
    Object.defineProperty(controller, 'confinedValue', { value: false });
    Object.defineProperty(controller, 'hasHandleTarget', { value: false });

    controller.connect();

    return warn;
  }

  it('registers a drag source', () => {
    const element = document.createElement('li');

    connectedControllerFor(element);

    expect(draggable).toHaveBeenCalledWith(expect.objectContaining({ element }));
  });

  it('warns when connected without an item id', () => {
    const warn = connectItem({ id: '', type: 'work_package' });

    expect(warn).toHaveBeenCalledWith(expect.stringContaining('id'), expect.anything());
  });

  it('warns when connected without an item type', () => {
    const warn = connectItem({ id: '123', type: '' });

    expect(warn).toHaveBeenCalledWith(expect.stringContaining('type'), expect.anything());
  });

  it('does not warn when id and type are both present', () => {
    const warn = connectItem({ id: '123', type: 'work_package' });

    expect(warn).not.toHaveBeenCalled();
  });

  it('re-establishes registrations and the marker attribute on reregister', () => {
    const element = document.createElement('li');
    const controller = connectedControllerFor(element);

    controller.reregister();

    expect(draggable).toHaveBeenCalledTimes(2);
    expect(dropTargetForElements).toHaveBeenCalledTimes(2);
    // The mocked cleanup strips the marker attribute, so its presence shows the
    // fresh registration ran after the stale one was cleaned up.
    expect(element.getAttribute('data-drop-target-for-element')).toEqual('true');
  });

  it('marks the closest edge while dragging over an item', () => {
    const element = document.createElement('article');
    const controller = controllerFor(element);

    controller.renderDropIndicator('top');

    expect(element.dataset.dropPosition).toEqual('top');
  });

  it('marks the closest edge on the containing row when present', () => {
    const element = document.createElement('li');
    const controller = controllerFor(element);

    element.classList.add('Box-row');

    controller.renderDropIndicator('top');

    expect(element.dataset.dropPosition).toEqual('top');
  });

  it('renders the bottom edge as the next row top edge when both describe the same insertion point', () => {
    const element = document.createElement('li');
    const nextElement = document.createElement('li');
    const controller = controllerFor(element);

    element.setAttribute('data-sortable-lists--item-id-value', '1');
    nextElement.setAttribute('data-sortable-lists--item-id-value', '2');
    document.body.append(element, nextElement);

    controller.renderDropIndicator('bottom');

    expect(element.hasAttribute('data-drop-position')).toBe(false);
    expect(nextElement.dataset.dropPosition).toEqual('top');
  });

  it('removes the drop position when leaving an item', () => {
    const element = document.createElement('li');
    const nextElement = document.createElement('li');
    const controller = controllerFor(element);

    element.setAttribute('data-sortable-lists--item-id-value', '1');
    nextElement.setAttribute('data-sortable-lists--item-id-value', '2');
    document.body.append(element, nextElement);

    controller.renderDropIndicator('bottom');
    controller.clearDropIndicator();

    expect(element.hasAttribute('data-drop-position')).toBe(false);
    expect(nextElement.hasAttribute('data-drop-position')).toBe(false);
  });

  it('does not clear an indicator owned by another item controller', () => {
    const element = document.createElement('li');
    const nextElement = document.createElement('li');
    const controller = controllerFor(element);

    element.setAttribute('data-sortable-lists--item-id-value', '1');
    nextElement.setAttribute('data-sortable-lists--item-id-value', '2');
    document.body.append(element, nextElement);

    controller.renderDropIndicator('bottom');
    nextElement.dataset.dropPosition = 'top';
    nextElement.dataset.dropPositionOwner = '2';

    controller.clearDropIndicator();

    expect(nextElement.dataset.dropPosition).toEqual('top');
    expect(nextElement.dataset.dropPositionOwner).toEqual('2');
  });

  it('clears its own drop indicator when the item disconnects mid-drag', () => {
    const element = document.createElement('li');
    const nextElement = document.createElement('li');
    const controller = controllerFor(element);

    element.setAttribute('data-sortable-lists--item-id-value', '1');
    nextElement.setAttribute('data-sortable-lists--item-id-value', '2');
    document.body.append(element, nextElement);

    controller.renderDropIndicator('bottom');
    expect(nextElement.dataset.dropPosition).toEqual('top');

    // A list-refresh morph removes the hovering row: its controller disconnects
    // without an onDrop, so the indicator it owns on the sibling must be cleared
    // here or it lingers forever.
    controller.disconnect();

    expect(nextElement.hasAttribute('data-drop-position')).toBe(false);
    expect(nextElement.hasAttribute('data-drop-position-owner')).toBe(false);
  });

  describe('sticky drop target boundaries', () => {
    afterEach(() => {
      document.body.replaceChildren();
    });

    function mountedRows() {
      const list = document.createElement('ul');
      list.style.cssText = 'margin:0;padding:0;list-style:none;';

      const rows = ['1', '2', '3'].map(() => {
        const row = document.createElement('li');
        row.style.cssText = 'display:block;height:30px;margin:0 0 10px 0;';
        list.append(row);
        return row;
      });

      document.body.append(list);
      return rows;
    }

    function stickyAt(element:HTMLElement, clientY:number) {
      return vi.mocked(dropTargetForElements).mock.lastCall?.[0].getIsSticky?.({
        element,
        input: { clientY } as never,
        source: {
          data: {},
          element: document.createElement('article'),
        } as never,
      });
    }

    it('keeps the item drop target active while moving through row gaps', () => {
      const [first, second] = mountedRows();

      connectedControllerFor(first);

      const gapY = (first.getBoundingClientRect().bottom + second.getBoundingClientRect().top) / 2;
      expect(stickyAt(first, gapY)).toBe(true);
    });

    it('releases the sticky target above the first row, where the list header sits', () => {
      const [first] = mountedRows();

      connectedControllerFor(first);

      expect(stickyAt(first, first.getBoundingClientRect().top - 5)).toBe(false);
    });

    it('releases the sticky target below the last row, over the empty space', () => {
      const [first, , third] = mountedRows();

      connectedControllerFor(first);

      expect(stickyAt(first, third.getBoundingClientRect().bottom + 5)).toBe(false);
    });

    it('releases the sticky target once the row is detached from a rows container', () => {
      const row = document.createElement('li');

      connectedControllerFor(row);

      expect(stickyAt(row, 0)).toBe(false);
    });

    it('uses the root-resolved rows container when the DOM parent is not the rows container', () => {
      const [first, , third] = mountedRows();
      const list = first.parentElement!;
      // Wrap the item in an intermediate div, so its DOM parent (the wrapper,
      // holding only itself) no longer matches its actual rows container
      // (the list, holding all three rows). Only a root-resolved lookup can
      // still see the full rows span.
      const wrapper = document.createElement('div');
      first.replaceWith(wrapper);
      wrapper.append(first);

      connectedControllerFor(first, { root: fakeRoot(document.createElement('div'), { ownerRowsContainer: () => list }) });

      // Reachable only if the sticky bounds span the whole list (root-resolved);
      // the DOM-parent fallback (the one-row wrapper) would release well before it.
      expect(stickyAt(first, third.getBoundingClientRect().bottom - 1)).toBe(true);
    });
  });

  it('does not accept itself as an item drop target', () => {
    const root = document.createElement('div');
    const element = document.createElement('article');

    connectedControllerFor(element, { root: fakeRoot(root) });

    expect(vi.mocked(dropTargetForElements).mock.lastCall?.[0].canDrop?.({
      element,
      input: {} as never,
      source: {
        data: sortableItemData({ type: 'item', itemId: '123', rootElement: root }),
        element: document.createElement('article'),
      } as never,
    })).toBe(false);
  });

  it('does not accept drops from another sortable lists root', () => {
    const targetRoot = document.createElement('div');
    const foreignRoot = document.createElement('div');
    const targetElement = document.createElement('article');

    connectedControllerFor(targetElement, { root: fakeRoot(targetRoot) });

    expect(vi.mocked(dropTargetForElements).mock.lastCall?.[0].canDrop?.({
      element: targetElement,
      input: {} as never,
      source: {
        data: sortableItemData({ type: 'item', itemId: '456', rootElement: foreignRoot }),
        element: document.createElement('article'),
      } as never,
    })).toBe(false);
  });

  it('does not accept a drop whose type differs from its own', () => {
    const root = document.createElement('div');
    const targetElement = document.createElement('article');

    connectedControllerFor(targetElement, { root: fakeRoot(root) });

    expect(vi.mocked(dropTargetForElements).mock.lastCall?.[0].canDrop?.({
      element: targetElement,
      input: {} as never,
      source: {
        data: sortableItemData({ type: 'meeting_agenda_item', itemId: '456', rootElement: root }),
        element: document.createElement('article'),
      } as never,
    })).toBe(false);
  });

  it('accepts a same-type drop from another item in its root', () => {
    const root = document.createElement('div');
    const targetElement = document.createElement('article');

    connectedControllerFor(targetElement, { root: fakeRoot(root) });

    expect(vi.mocked(dropTargetForElements).mock.lastCall?.[0].canDrop?.({
      element: targetElement,
      input: {} as never,
      source: {
        data: sortableItemData({ type: 'item', itemId: '456', rootElement: root }),
        element: document.createElement('article'),
      } as never,
    })).toBe(true);
  });

  // A confined item may only land in its source list. Rows of that list keep
  // accepting it (within-list reorder), rows of any other list refuse it, and
  // with no payload list there is nothing it may land on.
  describe('a confined drag source', () => {
    function canDropOnto(targetElement:HTMLElement, root:HTMLElement, sourceListElement:HTMLElement|null) {
      return vi.mocked(dropTargetForElements).mock.lastCall?.[0].canDrop?.({
        element: targetElement,
        input: {} as never,
        source: {
          data: sortableItemData({
            type: 'item',
            itemId: '456',
            rootElement: root,
            sourceListElement,
            confined: true,
          }),
          element: document.createElement('article'),
        } as never,
      });
    }

    it('still registers a drag source', () => {
      const element = document.createElement('li');

      connectedControllerFor(element, { confinedValue: true });

      expect(draggable).toHaveBeenCalledWith(expect.objectContaining({ element }));
    });

    it('is accepted by a row inside its source list', () => {
      const root = document.createElement('div');
      const sourceList = document.createElement('div');
      const targetElement = document.createElement('article');
      sourceList.appendChild(targetElement);

      connectedControllerFor(targetElement, { root: fakeRoot(root) });

      expect(canDropOnto(targetElement, root, sourceList)).toBe(true);
    });

    it('is refused by a row of a foreign list', () => {
      const root = document.createElement('div');
      const sourceList = document.createElement('div');
      const targetElement = document.createElement('article');

      connectedControllerFor(targetElement, { root: fakeRoot(root) });

      expect(canDropOnto(targetElement, root, sourceList)).toBe(false);
    });

    it('is refused everywhere when its payload carries no source list', () => {
      const root = document.createElement('div');
      const targetElement = document.createElement('article');

      connectedControllerFor(targetElement, { root: fakeRoot(root) });

      expect(canDropOnto(targetElement, root, null)).toBe(false);
    });
  });

  it('accepts an unconfined drop from a row of another list', () => {
    const root = document.createElement('div');
    const foreignList = document.createElement('div');
    const targetElement = document.createElement('article');

    connectedControllerFor(targetElement, { root: fakeRoot(root) });

    expect(vi.mocked(dropTargetForElements).mock.lastCall?.[0].canDrop?.({
      element: targetElement,
      input: {} as never,
      source: {
        data: sortableItemData({
          type: 'item',
          itemId: '456',
          rootElement: root,
          sourceListElement: foreignList,
        }),
        element: document.createElement('article'),
      } as never,
    })).toBe(true);
  });

  it('does not accept drops while the root is busy moving another item', () => {
    const root = document.createElement('div');
    const targetElement = document.createElement('article');

    connectedControllerFor(targetElement, { root: fakeRoot(root, { busy: true }) });

    expect(vi.mocked(dropTargetForElements).mock.lastCall?.[0].canDrop?.({
      element: targetElement,
      input: {} as never,
      source: {
        data: sortableItemData({ type: 'item', itemId: '456', rootElement: root }),
        element: document.createElement('article'),
      } as never,
    })).toBe(false);
  });

  it('exposes the external URL as native drag data for external consumers', () => {
    const element = document.createElement('article');

    connectedControllerFor(element, { externalUrl: 'http://example.org/work_packages/123' });

    const externalData = vi.mocked(draggable).mock.lastCall?.[0]
      .getInitialDataForExternal?.(draggableArgs(element));

    expect(externalData).toEqual({
      'text/uri-list': 'http://example.org/work_packages/123',
      'text/plain': 'http://example.org/work_packages/123',
    });
  });

  it('adds a text/html link flavour when the item has a label', () => {
    const element = document.createElement('article');

    connectedControllerFor(element, {
      externalUrl: 'http://example.org/work_packages/123',
      label: 'Feature #123: Card subject',
    });

    const externalData = vi.mocked(draggable).mock.lastCall?.[0]
      .getInitialDataForExternal?.(draggableArgs(element));

    expect(externalData).toEqual({
      'text/uri-list': 'http://example.org/work_packages/123',
      'text/plain': 'http://example.org/work_packages/123',
      'text/html': '<a href="http://example.org/work_packages/123">Feature #123: Card subject</a>',
    });
  });

  it('escapes HTML-sensitive characters in the external link label', () => {
    const element = document.createElement('article');

    connectedControllerFor(element, {
      externalUrl: 'http://example.org/work_packages/123',
      label: '<script>alert("x")</script> & more',
    });

    const externalData = vi.mocked(draggable).mock.lastCall?.[0]
      .getInitialDataForExternal?.(draggableArgs(element));

    expect(externalData?.['text/html']).toBe(
      '<a href="http://example.org/work_packages/123">&lt;script&gt;alert("x")&lt;/script&gt; &amp; more</a>',
    );
  });

  it('does not expose native external drag data without an external URL', () => {
    const element = document.createElement('article');

    connectedControllerFor(element);

    expect(vi.mocked(draggable).mock.lastCall?.[0].getInitialDataForExternal).toBeUndefined();
  });

  it('does not expose native external drag data for a blank external URL', () => {
    const element = document.createElement('article');

    connectedControllerFor(element, { externalUrl: '' });

    expect(vi.mocked(draggable).mock.lastCall?.[0].getInitialDataForExternal).toBeUndefined();
  });

  it('prevents unhandled browser drag feedback while dragging an item', () => {
    const element = document.createElement('article');

    connectedControllerFor(element);

    vi.mocked(draggable).mock.lastCall?.[0].onDragStart?.(dragEventPayload(element));
    expect(preventUnhandled.start).toHaveBeenCalledOnce();

    vi.mocked(draggable).mock.lastCall?.[0].onDrop?.(dragEventPayload(element));
    expect(preventUnhandled.stop).toHaveBeenCalledOnce();
  });

  it('does not start dragging from interactive descendants', () => {
    const element = document.createElement('article');
    const link = document.createElement('a');

    link.href = '/work_packages/123';
    element.appendChild(link);
    vi.spyOn(document, 'elementFromPoint').mockReturnValue(link);
    connectedControllerFor(element);

    expect(vi.mocked(draggable).mock.lastCall?.[0].canDrag?.({
      element,
      dragHandle: null,
      input: { clientX: 10, clientY: 10 } as never,
    })).toBe(false);
  });

  it('starts dragging from non-interactive descendants', () => {
    const element = document.createElement('article');
    const text = document.createElement('span');

    element.appendChild(text);
    vi.spyOn(document, 'elementFromPoint').mockReturnValue(text);
    connectedControllerFor(element);

    expect(vi.mocked(draggable).mock.lastCall?.[0].canDrag?.({
      element,
      dragHandle: null,
      input: { clientX: 10, clientY: 10 } as never,
    })).toBe(true);
  });

  it('starts dragging from the focusable drag handle itself', () => {
    const element = document.createElement('li');
    const handle = document.createElement('article');

    handle.tabIndex = 0;
    handle.setAttribute('data-sortable-lists--item-target', 'preview handle');
    element.appendChild(handle);
    document.body.appendChild(element);
    vi.spyOn(document, 'elementFromPoint').mockReturnValue(handle);
    connectedControllerFor(element, { handle });

    expect(vi.mocked(draggable).mock.lastCall?.[0].canDrag?.({
      element,
      dragHandle: handle,
      input: { clientX: 10, clientY: 10 } as never,
    })).toBe(true);

    element.remove();
  });

  it('does not start dragging while the root is busy moving another item', () => {
    const element = document.createElement('article');
    const text = document.createElement('span');
    element.appendChild(text);
    vi.spyOn(document, 'elementFromPoint').mockReturnValue(text);

    connectedControllerFor(element, { root: fakeRoot(document.createElement('div'), { busy: true }) });

    expect(vi.mocked(draggable).mock.lastCall?.[0].canDrag?.({
      element, dragHandle: null, input: { clientX: 10, clientY: 10 } as never,
    })).toBe(false);
  });

  it('refuses to drag before the root reference is connected', () => {
    const element = document.createElement('article');
    const text = document.createElement('span');
    element.appendChild(text);
    vi.spyOn(document, 'elementFromPoint').mockReturnValue(text);

    connectedControllerFor(element, { root: null });

    expect(vi.mocked(draggable).mock.lastCall?.[0].canDrag?.({
      element, dragHandle: null, input: { clientX: 10, clientY: 10 } as never,
    })).toBe(false);
  });

  it('includes the root element in the drag payload', () => {
    const root = document.createElement('div');
    const element = document.createElement('article');
    connectedControllerFor(element, { root: fakeRoot(root) });

    expect(vi.mocked(draggable).mock.lastCall?.[0].getInitialData?.(draggableArgs(element)))
      .toEqual(expect.objectContaining({ itemId: '123', type: 'item', rootElement: root }));
  });

  it('includes the root-resolved source list and confinement in the drag payload', () => {
    const root = document.createElement('div');
    const sourceList = document.createElement('div');
    const element = document.createElement('article');
    connectedControllerFor(element, {
      root: fakeRoot(root, { ownerListElement: sourceList }),
      confinedValue: true,
    });

    expect(vi.mocked(draggable).mock.lastCall?.[0].getInitialData?.(draggableArgs(element)))
      .toEqual(expect.objectContaining({ sourceListElement: sourceList, confined: true }));
  });

  it('defaults the payload to unconfined with no source list', () => {
    const element = document.createElement('article');
    connectedControllerFor(element);

    expect(vi.mocked(draggable).mock.lastCall?.[0].getInitialData?.(draggableArgs(element)))
      .toEqual(expect.objectContaining({ sourceListElement: null, confined: false }));
  });

  describe('Stimulus application wiring', () => {
    let ctx:StimulusTestContext;
    let fixture:HTMLElement;

    beforeEach(async () => {
      ctx = await setupStimulusTest({
        controllers: {
          'sortable-lists--item': ItemController,
        },
      });
      fixture = ctx.container;
    });

    afterEach(() => {
      ctx.dispose();
    });

    function renderBacklogsRow(itemId = '123', { boxClasses = '' } = {}) {
      const rowHtml = `
        <li
          class="Box-row"
          data-controller="sortable-lists--item"
          data-test-selector="work-package-${itemId}"
          data-sortable-lists--item-id-value="${itemId}"
          data-sortable-lists--item-type-value="work_package"
        >
          <article
            tabindex="0"
            data-controller="backlogs--work-package"
            data-sortable-lists--item-target="preview handle"
            data-action="click->backlogs--work-package#select"
            data-dragging="source"
            data-drop-position="top"
            data-drop-position-owner="${itemId}"
          >
            <span
              data-controller="nested"
              data-action="click->nested#noop"
              data-backlogs--work-package-target="subject"
            ></span>
          </article>
        </li>
      `;

      fixture.innerHTML = boxClasses ? `<ul class="${boxClasses}">${rowHtml}</ul>` : rowHtml;

      return {
        row: fixture.querySelector<HTMLElement>('.Box-row')!,
        article: fixture.querySelector<HTMLElement>('[data-controller="backlogs--work-package"]')!,
      };
    }

    it('registers the row as both draggable and drop target', async () => {
      const { row } = renderBacklogsRow();

      await ctx.nextFrame();

      expect(vi.mocked(draggable)).toHaveBeenCalledWith(expect.objectContaining({
        element: row,
      }));
      expect(vi.mocked(dropTargetForElements)).toHaveBeenCalledWith(expect.objectContaining({
        element: row,
      }));
    });

    it('uses the handle target as the pointer drag handle without adding drag ARIA', async () => {
      const { article } = renderBacklogsRow();

      await ctx.nextFrame();

      expect(vi.mocked(draggable)).toHaveBeenCalledWith(expect.objectContaining({
        dragHandle: article,
      }));
      expect(article.hasAttribute('aria-roledescription')).toBe(false);
      expect(article.hasAttribute('aria-disabled')).toBe(false);
      expect(article.hasAttribute('aria-pressed')).toBe(false);
      expect(article.hasAttribute('role')).toBe(false);
      expect(article.getAttribute('tabindex')).toEqual('0');
      expect(fixture.querySelector('[id^="sortable-lists-drag-handle-instructions"]')).toBeNull();
    });

    it('does not intercept keyboard events on the card handle', async () => {
      const { row, article } = renderBacklogsRow();
      const event = new KeyboardEvent('keydown', {
        bubbles: true,
        cancelable: true,
        key: ' ',
      });

      await ctx.nextFrame();
      article.dispatchEvent(event);

      expect(event.defaultPrevented).toBe(false);
      expect(row.hasAttribute('data-dragging')).toBe(false);
    });

    it('builds the sortable item data for the drag payload', async () => {
      const { article } = renderBacklogsRow();

      await ctx.nextFrame();

      expect(vi.mocked(draggable).mock.lastCall?.[0].getInitialData?.(draggableArgs(article))).toEqual(expect.objectContaining({
        itemId: '123',
        type: 'work_package',
      }));
    });

    it('renders a sanitized copy of the preview target for the native drag preview', async () => {
      const { article } = renderBacklogsRow();
      const nativeSetDragImage = vi.fn();
      const previewContainer = document.createElement('div');

      vi.spyOn(article, 'getBoundingClientRect').mockReturnValue({
        x: 0,
        y: 0,
        top: 0,
        left: 0,
        right: 320,
        bottom: 64,
        width: 320,
        height: 64,
        toJSON: vi.fn(),
      });

      await ctx.nextFrame();

      vi.mocked(draggable).mock.lastCall?.[0].onGenerateDragPreview?.({
        ...dragEventPayload(article),
        nativeSetDragImage,
      });

      expect(setCustomNativeDragPreview).toHaveBeenCalledOnce();

      const previewOptions = vi.mocked(setCustomNativeDragPreview).mock.lastCall?.[0] as {
        render:({ container }:{ container:HTMLElement }) => void;
        nativeSetDragImage:typeof nativeSetDragImage;
      };

      expect(previewOptions.nativeSetDragImage).toBe(nativeSetDragImage);

      previewOptions.render({ container: previewContainer });

      const preview = previewContainer.firstElementChild as HTMLElement;

      expect(preview).not.toBe(article);
      expect(preview.tagName).toEqual('ARTICLE');
      expect(preview.style.width).toEqual('320px');
      expect(preview.hasAttribute('data-preview')).toBe(true);
      expect(preview.hasAttribute('data-controller')).toBe(false);
      expect(preview.hasAttribute('data-sortable-lists--item-target')).toBe(false);
      expect(preview.hasAttribute('data-action')).toBe(false);
      expect(preview.hasAttribute('data-dragging')).toBe(false);
      expect(preview.hasAttribute('data-drop-position')).toBe(false);
      expect(preview.hasAttribute('data-drop-position-owner')).toBe(false);
      expect(preview.hasAttribute('aria-roledescription')).toBe(false);
      expect(preview.hasAttribute('aria-describedby')).toBe(false);
      expect(preview.hasAttribute('aria-disabled')).toBe(false);
      expect(preview.querySelector('[data-controller]')).toBeNull();
      expect(preview.querySelector('[data-action]')).toBeNull();
      expect(preview.querySelector('[data-backlogs--work-package-target]')).toBeNull();
    });

    it('offsets the preview so the pointer keeps its grab position on the card', async () => {
      const { article } = renderBacklogsRow();

      vi.spyOn(article, 'getBoundingClientRect').mockReturnValue({
        x: 100,
        y: 200,
        top: 200,
        left: 100,
        right: 420,
        bottom: 264,
        width: 320,
        height: 64,
        toJSON: vi.fn(),
      });

      await ctx.nextFrame();

      vi.mocked(draggable).mock.lastCall?.[0].onGenerateDragPreview?.({
        ...dragEventPayload(article),
        location: { current: { input: { clientX: 140, clientY: 230 } } } as never,
        nativeSetDragImage: vi.fn(),
      });

      const previewOptions = vi.mocked(setCustomNativeDragPreview).mock.lastCall?.[0] as {
        getOffset:(args:{ container:HTMLElement }) => { x:number; y:number };
      };
      const container = document.createElement('div');

      vi.spyOn(container, 'getBoundingClientRect').mockReturnValue({
        x: 0,
        y: 0,
        top: 0,
        left: 0,
        right: 320,
        bottom: 64,
        width: 320,
        height: 64,
        toJSON: vi.fn(),
      });

      expect(previewOptions.getOffset({ container })).toEqual({ x: 40, y: 30 });
    });

    function generatePreview(article:HTMLElement):HTMLElement {
      const previewContainer = document.createElement('div');

      vi.mocked(draggable).mock.lastCall?.[0].onGenerateDragPreview?.({
        ...dragEventPayload(article),
        nativeSetDragImage: vi.fn(),
      });

      const previewOptions = vi.mocked(setCustomNativeDragPreview).mock.lastCall?.[0] as {
        render:({ container }:{ container:HTMLElement }) => void;
      };

      previewOptions.render({ container: previewContainer });

      return previewContainer;
    }

    it('copies the Box density variant class onto the preview container', async () => {
      const { article } = renderBacklogsRow('123', { boxClasses: 'Box Box--condensed' });

      await ctx.nextFrame();

      const container = generatePreview(article);

      expect(container.classList.contains('Box--condensed')).toBe(true);
      expect(container.classList.contains('Box--spacious')).toBe(false);
    });

    it('does not add density variant classes for a default-density Box', async () => {
      const { article } = renderBacklogsRow('123', { boxClasses: 'Box' });

      await ctx.nextFrame();

      const container = generatePreview(article);

      expect(container.classList.contains('Box--condensed')).toBe(false);
      expect(container.classList.contains('Box--spacious')).toBe(false);
    });
  });

  describe('move menu', () => {
    let menuCtx:StimulusTestContext|undefined;

    afterEach(() => {
      menuCtx?.dispose();
      menuCtx = undefined;
    });

    // Mounts the element through Stimulus (the same setupStimulusTest harness
    // the file's other wiring tests use), so targets/actions/elements wire the
    // way they do in production rather than being newed up directly.
    async function mountItemController(el:HTMLElement):Promise<InstanceType<typeof ItemControllerType>> {
      menuCtx = await setupStimulusTest({
        controllers: {
          'sortable-lists--item': ItemController,
        },
      });
      menuCtx.container.appendChild(el);
      await menuCtx.nextFrame();

      return menuCtx.getController<InstanceType<typeof ItemControllerType>>('sortable-lists--item', el);
    }

    // Builds an item element containing a fake <action-menu> whose four move
    // items are <li> targets (direction + move action on the li). The menu
    // stub exposes the Primer item-state API the controller calls;
    // isItemDisabled is driven by a live class check so the click-guard test
    // is realistic.
    interface FakeActionMenu {
      enableItem:ReturnType<typeof vi.fn>;
      disableItem:ReturnType<typeof vi.fn>;
      showItem:ReturnType<typeof vi.fn>;
      hideItem:ReturnType<typeof vi.fn>;
      isItemDisabled:ReturnType<typeof vi.fn>;
      isItemHidden:ReturnType<typeof vi.fn>;
    }

    function renderItemWithMenu(idNumber:number, withDivider = false):{ el:HTMLElement; menu:FakeActionMenu } {
      const el = document.createElement('div');
      el.dataset.controller = 'sortable-lists--item';
      el.setAttribute('data-sortable-lists--item-id-value', String(idNumber));
      el.setAttribute('data-sortable-lists--item-type-value', 'work_package');

      const menuElement = document.createElement('action-menu');
      // The divider opens the move group, so everything below it is what
      // decides whether it still separates anything.
      menuElement.innerHTML = (withDivider ? '<li data-sortable-lists--item-target="moveDivider"></li>' : '')
        + ['top', 'up', 'down', 'bottom'].map((direction) => (
          `<li data-sortable-lists--item-target="moveItem" data-sortable-lists--item-direction-param="${direction}"`
          + ' data-action="click->sortable-lists--item#move"><button></button></li>'
        )).join('');
      const parent = document.createElement('li');
      parent.setAttribute('data-sortable-lists--item-target', 'moveMenu');
      menuElement.appendChild(parent);
      el.appendChild(menuElement);

      const menu:FakeActionMenu = {
        enableItem: vi.fn((li:Element|null) => li?.classList.remove('ActionListItem--disabled')),
        disableItem: vi.fn((li:Element|null) => li?.classList.add('ActionListItem--disabled')),
        // Primer's own implementations, so the hidden attribute the divider
        // check reads is as real here as the disabled class above.
        showItem: vi.fn((li:Element|null) => li?.removeAttribute('hidden')),
        hideItem: vi.fn((li:Element|null) => li?.setAttribute('hidden', 'hidden')),
        isItemDisabled: vi.fn((li:Element|null) => !!li?.classList.contains('ActionListItem--disabled')),
        isItemHidden: vi.fn((li:Element|null) => !!li?.hasAttribute('hidden')),
      };
      Object.assign(menuElement, menu);

      return { el, menu };
    }

    const liFor = (el:HTMLElement, direction:string) => el.querySelector<HTMLElement>(`li[data-sortable-lists--item-direction-param="${direction}"]`)!;
    // Availability defaults to the first/last extremes so the position-driven
    // specs read naturally; individual tests can override the map to exercise
    // the marker-aware (truncated list) wiring.
    const availabilityFromPosition = (position:{ isFirst:boolean; isLast:boolean }) => ({
      top: !position.isFirst,
      up: !position.isFirst,
      down: !position.isLast,
      bottom: !position.isLast,
    });
    const stubRoot = (
      el:HTMLElement,
      position:{ isFirst:boolean; isLast:boolean },
      moveInDirection = vi.fn(),
      availability = availabilityFromPosition(position),
    ) => ({
      element: el, busy: false, moveAvailability: () => availability, moveInDirection,
    } as unknown as SortableListsRoot);

    it('hides up/top for a first item and shows the rest', async () => {
      const { el, menu } = renderItemWithMenu(1);
      document.body.appendChild(el);
      const controller = await mountItemController(el);
      controller.connectRoot(stubRoot(el, { isFirst: true, isLast: false }));
      controller.moveItemTargetConnected();

      expect(menu.hideItem).toHaveBeenCalledWith(liFor(el, 'top'));
      expect(menu.hideItem).toHaveBeenCalledWith(liFor(el, 'up'));
      expect(menu.showItem).toHaveBeenCalledWith(liFor(el, 'down'));
      expect(menu.showItem).toHaveBeenCalledWith(liFor(el, 'bottom'));
    });

    it('hides a mid-list direction the root reports unavailable (truncation gap)', async () => {
      const { el, menu } = renderItemWithMenu(1);
      document.body.appendChild(el);
      const controller = await mountItemController(el);
      // Not an extreme (neither first nor last), but the root deems "down"
      // unavailable because it would cross a hidden block.
      const gappedAvailability = { top: true, up: true, down: false, bottom: true };
      controller.connectRoot(stubRoot(el, { isFirst: false, isLast: false }, vi.fn(), gappedAvailability));
      controller.moveItemTargetConnected();

      expect(menu.hideItem).toHaveBeenCalledWith(liFor(el, 'down'));
      expect(menu.showItem).toHaveBeenCalledWith(liFor(el, 'up'));
    });

    it('disables unavailable items instead of hiding them when hideUnavailable is off', async () => {
      const { el, menu } = renderItemWithMenu(1);
      el.setAttribute('data-sortable-lists--item-hide-unavailable-value', 'false');
      document.body.appendChild(el);
      const controller = await mountItemController(el);
      controller.connectRoot(stubRoot(el, { isFirst: true, isLast: false }));
      controller.moveItemTargetConnected();

      expect(menu.disableItem).toHaveBeenCalledWith(liFor(el, 'top'));
      expect(menu.disableItem).toHaveBeenCalledWith(liFor(el, 'up'));
      expect(menu.enableItem).toHaveBeenCalledWith(liFor(el, 'down'));
      expect(menu.enableItem).toHaveBeenCalledWith(liFor(el, 'bottom'));
      expect(menu.hideItem).not.toHaveBeenCalled();
      expect(menu.showItem).not.toHaveBeenCalled();
    });

    it('hides the parent submenu when nothing is available (single item)', async () => {
      const { el, menu } = renderItemWithMenu(1);
      document.body.appendChild(el);
      const controller = await mountItemController(el);
      controller.connectRoot(stubRoot(el, { isFirst: true, isLast: true }));
      controller.moveItemTargetConnected();

      const parent = el.querySelector<HTMLElement>('li[data-sortable-lists--item-target="moveMenu"]')!;
      expect(menu.hideItem).toHaveBeenCalledWith(parent);
    });

    // Regression: the divider is rendered server-side from a permission check
    // alone, so an item with nowhere to move used to be left with a separator
    // and nothing below it.
    it('hides the divider when nothing below it is left visible', async () => {
      const { el } = renderItemWithMenu(1, true);
      document.body.appendChild(el);
      const controller = await mountItemController(el);
      controller.connectRoot(stubRoot(el, { isFirst: true, isLast: true }));
      controller.moveItemTargetConnected();

      const divider = el.querySelector<HTMLElement>('li[data-sortable-lists--item-target="moveDivider"]')!;
      expect(divider.hasAttribute('hidden')).toBe(true);
    });

    it('keeps the divider while something below it is still visible', async () => {
      const { el } = renderItemWithMenu(1, true);
      document.body.appendChild(el);
      const controller = await mountItemController(el);
      controller.connectRoot(stubRoot(el, { isFirst: true, isLast: false }));
      controller.moveItemTargetConnected();

      const divider = el.querySelector<HTMLElement>('li[data-sortable-lists--item-target="moveDivider"]')!;
      expect(divider.hasAttribute('hidden')).toBe(false);
    });

    // A divider has no `.ActionListContent`, so routing it through
    // `disableItem` would throw — and in this mode the group stays visible
    // anyway, only disabled.
    it('leaves the divider alone when hideUnavailable is off', async () => {
      const { el } = renderItemWithMenu(1, true);
      el.setAttribute('data-sortable-lists--item-hide-unavailable-value', 'false');
      document.body.appendChild(el);
      const controller = await mountItemController(el);
      controller.connectRoot(stubRoot(el, { isFirst: true, isLast: true }));
      controller.moveItemTargetConnected();

      const divider = el.querySelector<HTMLElement>('li[data-sortable-lists--item-target="moveDivider"]')!;
      expect(divider.hasAttribute('hidden')).toBe(false);
    });

    it('delegates an enabled click to the root and no-ops a disabled one', async () => {
      const { el } = renderItemWithMenu(2);
      document.body.appendChild(el);
      const moveInDirection = vi.fn();
      const controller = await mountItemController(el);
      controller.connectRoot(stubRoot(el, { isFirst: false, isLast: false }, moveInDirection));
      controller.moveItemTargetConnected();

      liFor(el, 'down').click();
      expect(moveInDirection).toHaveBeenCalledWith(el, 'down');

      liFor(el, 'up').classList.add('ActionListItem--disabled'); // menu.isItemDisabled now returns true for it
      moveInDirection.mockClear();
      liFor(el, 'up').click();
      expect(moveInDirection).not.toHaveBeenCalled();
    });

    it('does nothing when there is no action-menu (drag-only consumer)', async () => {
      const el = document.createElement('div');
      el.dataset.controller = 'sortable-lists--item';
      el.setAttribute('data-sortable-lists--item-id-value', '1');
      el.setAttribute('data-sortable-lists--item-type-value', 'work_package');
      document.body.appendChild(el);
      const controller = await mountItemController(el);
      const moveInDirection = vi.fn();

      // No moveItem targets and no <action-menu>: the availability refresh
      // must no-op, not throw.
      expect(() => {
        controller.connectRoot(stubRoot(el, { isFirst: true, isLast: true }, moveInDirection));
        // @ts-expect-error exercising the guard directly
        controller.refreshMoveMenuAvailability?.();
      }).not.toThrow();

      // move() must also no-op rather than throw: there is no menu to read
      // isItemDisabled/isItemHidden from, and no move should reach the root.
      const moveEvent:ActionEvent = Object.assign(new Event('click'), { params: {} });
      Object.defineProperty(moveEvent, 'currentTarget', { value: el });

      expect(() => controller.move(moveEvent)).not.toThrow();
      expect(moveInDirection).not.toHaveBeenCalled();
    });
  });
});

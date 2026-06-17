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

import type { draggable as draggableFn, dropTargetForElements as dropTargetForElementsFn } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';
import type { setCustomNativeDragPreview as setCustomNativeDragPreviewFn } from '@atlaskit/pragmatic-drag-and-drop/element/set-custom-native-drag-preview';
import type { preventUnhandled as preventUnhandledType } from '@atlaskit/pragmatic-drag-and-drop/prevent-unhandled';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
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
  }

  beforeAll(async () => {
    vi.doMock('@atlaskit/pragmatic-drag-and-drop/combine', () => ({
      combine: vi.fn((...cleanups:(() => void)[]) => vi.fn(() => {
        cleanups.forEach((cleanup) => cleanup());
      })),
    }));

    vi.doMock('@atlaskit/pragmatic-drag-and-drop/element/adapter', () => ({
      draggable: vi.fn(() => vi.fn()),
      dropTargetForElements: vi.fn(() => vi.fn()),
      monitorForElements: vi.fn(() => vi.fn()),
    }));

    vi.doMock('@atlaskit/pragmatic-drag-and-drop/prevent-unhandled', () => ({
      preventUnhandled: {
        start: vi.fn(),
        stop: vi.fn(),
      },
    }));

    vi.doMock('@atlaskit/pragmatic-drag-and-drop/element/set-custom-native-drag-preview', () => ({
      setCustomNativeDragPreview: vi.fn(),
    }));

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
    { moving = false, acceptedType = null as string|null } = {},
  ):SortableListsRoot {
    Object.defineProperty(element, 'isConnected', { value: true, configurable: true });
    return { element, moving, acceptedType };
  }

  function connectedControllerFor(
    element:HTMLElement,
    { handle = null, root = fakeRoot() }:{ handle?:HTMLElement|null; root?:SortableListsRoot|null } = {},
  ) {
    const controller = Object.create(ItemController.prototype) as InstanceType<typeof ItemControllerType>;

    Object.defineProperty(controller, 'element', { value: element });
    Object.defineProperty(controller, 'idValue', { value: '123' });
    Object.defineProperty(controller, 'hasIdValue', { value: true });
    Object.defineProperty(controller, 'typeValue', { value: 'item' });
    Object.defineProperty(controller, 'hasTypeValue', { value: true });
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
    Object.defineProperty(controller, 'hasHandleTarget', { value: false });

    controller.connect();

    return warn;
  }

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

  it('keeps the item drop target active while moving through row gaps', () => {
    const element = document.createElement('article');

    connectedControllerFor(element);

    expect(vi.mocked(dropTargetForElements).mock.lastCall?.[0].getIsSticky?.({
      element,
      input: {} as never,
      source: {
        data: {},
        element: document.createElement('article'),
      } as never,
    })).toBe(true);
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

  it('does not accept drops whose type is rejected by the root', () => {
    const root = document.createElement('div');
    const targetElement = document.createElement('article');

    connectedControllerFor(targetElement, { root: fakeRoot(root, { acceptedType: 'work_package' }) });

    expect(vi.mocked(dropTargetForElements).mock.lastCall?.[0].canDrop?.({
      element: targetElement,
      input: {} as never,
      source: {
        data: sortableItemData({ type: 'meeting_agenda_item', itemId: '456', rootElement: root }),
        element: document.createElement('article'),
      } as never,
    })).toBe(false);
  });

  it('does not accept drops while the root is moving another item', () => {
    const root = document.createElement('div');
    const targetElement = document.createElement('article');

    connectedControllerFor(targetElement, { root: fakeRoot(root, { moving: true }) });

    expect(vi.mocked(dropTargetForElements).mock.lastCall?.[0].canDrop?.({
      element: targetElement,
      input: {} as never,
      source: {
        data: sortableItemData({ type: 'item', itemId: '456', rootElement: root }),
        element: document.createElement('article'),
      } as never,
    })).toBe(false);
  });

  it('does not expose native external drag data', () => {
    const element = document.createElement('article');

    connectedControllerFor(element);

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

  it('does not start dragging while the root is moving another item', () => {
    const element = document.createElement('article');
    const text = document.createElement('span');
    element.appendChild(text);
    vi.spyOn(document, 'elementFromPoint').mockReturnValue(text);

    connectedControllerFor(element, { root: fakeRoot(document.createElement('div'), { moving: true }) });

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
            data-controller="backlogs--story"
            data-sortable-lists--item-target="preview handle"
            data-action="click->backlogs--story#select"
            data-dragging="source"
            data-drop-position="top"
            data-drop-position-owner="${itemId}"
          >
            <span
              data-controller="nested"
              data-action="click->nested#noop"
              data-backlogs--story-target="subject"
            ></span>
          </article>
        </li>
      `;

      fixture.innerHTML = boxClasses ? `<ul class="${boxClasses}">${rowHtml}</ul>` : rowHtml;

      return {
        row: fixture.querySelector<HTMLElement>('.Box-row')!,
        article: fixture.querySelector<HTMLElement>('[data-controller="backlogs--story"]')!,
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
      expect(preview.querySelector('[data-backlogs--story-target]')).toBeNull();
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
});

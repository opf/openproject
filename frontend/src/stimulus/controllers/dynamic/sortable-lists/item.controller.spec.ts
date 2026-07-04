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
import type SortableListsControllerType from '../sortable-lists.controller';

// The item controller resolves its root through a real Stimulus outlet, so
// both the root (`sortable-lists.controller.ts`) and the item controller are
// registered here and wired together through the
// `data-sortable-lists--item-sortable-lists-outlet`
// attribute, exactly as production markup does.
describe('Sortable lists item controller', () => {
  let draggable:typeof draggableFn;
  let dropTargetForElements:typeof dropTargetForElementsFn;
  let preventUnhandled:typeof preventUnhandledType;
  let setCustomNativeDragPreview:typeof setCustomNativeDragPreviewFn;
  let ItemController:typeof ItemControllerType;
  let SortableListsController:typeof SortableListsControllerType;
  let sortableItemData:typeof import('./drag-and-drop').sortableItemData;

  interface TestItemController {
    renderDropIndicator(edge:'top'|'bottom'|null):void;
    clearDropIndicator():void;
  }

  let ctx:StimulusTestContext;
  let fixture:HTMLElement;

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

    vi.doMock('@atlaskit/pragmatic-drag-and-drop-auto-scroll/element', () => ({
      autoScrollForElements: vi.fn(() => vi.fn()),
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
    ({ default: SortableListsController } = await import('../sortable-lists.controller'));
    ({ sortableItemData } = await import('./drag-and-drop'));
  });

  beforeEach(async () => {
    vi.clearAllMocks();
    vi.mocked(dropTargetForElements).mockImplementation(({ element }) => {
      element.setAttribute('data-drop-target-for-element', 'true');

      return vi.fn(() => {
        element.removeAttribute('data-drop-target-for-element');
      });
    });

    ctx = await setupStimulusTest({
      controllers: {
        'sortable-lists': SortableListsController,
        'sortable-lists--item': ItemController,
      },
    });
    fixture = ctx.container;
  });

  afterEach(() => ctx.dispose());

  function controllerFor(element:HTMLElement) {
    const controller = Object.create(ItemController.prototype) as unknown as TestItemController;

    Object.defineProperty(controller, 'element', { value: element });
    Object.defineProperty(controller, 'idValue', { value: '1' });
    Object.defineProperty(controller, 'typeValue', { value: 'item' });

    return controller;
  }

  async function connectedItemFor({
    id = '123',
    type = 'item',
    outlet = true,
    innerHtml = '',
  }:{
    id?:string|null;
    type?:string|null;
    outlet?:boolean;
    innerHtml?:string;
  } = {}) {
    fixture.innerHTML = `
      <div id="root" data-controller="sortable-lists">
        <li data-controller="sortable-lists--item"
            ${id != null ? `data-sortable-lists--item-id-value="${id}"` : ''}
            ${type != null ? `data-sortable-lists--item-type-value="${type}"` : ''}
            ${outlet ? 'data-sortable-lists--item-sortable-lists-outlet="#root"' : ''}>${innerHtml}</li>
      </div>
    `;
    const root = fixture.querySelector<HTMLElement>('#root')!;
    const item = fixture.querySelector<HTMLElement>('[data-controller~="sortable-lists--item"]')!;
    await ctx.nextFrame();

    const controller = ctx.application.getControllerForElementAndIdentifier(item, 'sortable-lists--item') as unknown as InstanceType<typeof ItemControllerType>;

    return { root, item, controller };
  }

  function setRootMoving(root:HTMLElement, moving:boolean):void {
    const rootController = ctx.application.getControllerForElementAndIdentifier(root, 'sortable-lists') as unknown as { movingFlag:boolean };

    rootController.movingFlag = moving;
  }

  function draggableOptionsFor(element:HTMLElement) {
    return vi.mocked(draggable).mock.calls.find(([options]) => options.element === element)?.[0];
  }

  function dropTargetOptionsFor(element:HTMLElement) {
    return vi.mocked(dropTargetForElements).mock.calls.find(([options]) => options.element === element)?.[0];
  }

  function dragArgs(element:HTMLElement, dragHandle:HTMLElement|null = null) {
    return { element, dragHandle, input: { clientX: 0, clientY: 0 } as never };
  }

  function dragEventPayload(element:HTMLElement) {
    return {
      location: { current: { input: { clientX: 0, clientY: 0 } } } as never,
      source: {
        data: {},
        dragHandle: null,
        element,
      },
    };
  }

  it('warns when the id value is missing or empty', async () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);

    await connectedItemFor({ id: null });
    expect(warn).toHaveBeenCalledWith(expect.stringContaining('id'), expect.anything());
    warn.mockClear();

    await connectedItemFor({ id: '' });
    expect(warn).toHaveBeenCalledWith(expect.stringContaining('id'), expect.anything());

    warn.mockRestore();
  });

  it('warns when the type value is missing or empty', async () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);

    await connectedItemFor({ type: null });
    expect(warn).toHaveBeenCalledWith(expect.stringContaining('type'), expect.anything());
    warn.mockClear();

    await connectedItemFor({ type: '' });
    expect(warn).toHaveBeenCalledWith(expect.stringContaining('type'), expect.anything());

    warn.mockRestore();
  });

  it('does not warn when id and type are both present', async () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);

    await connectedItemFor({ id: '123', type: 'work_package' });

    expect(warn).not.toHaveBeenCalled();
    warn.mockRestore();
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

  it('keeps the item drop target active while moving through row gaps', async () => {
    const { item } = await connectedItemFor();

    expect(dropTargetOptionsFor(item)?.getIsSticky?.({
      element: item,
      input: {} as never,
      source: {
        data: {},
        element: document.createElement('article'),
      } as never,
    })).toBe(true);
  });

  it('accepts drops only from items of the same type', async () => {
    const { root, item } = await connectedItemFor({ id: '123', type: 'item' });

    expect(dropTargetOptionsFor(item)?.canDrop?.({
      element: item,
      input: {} as never,
      source: {
        data: sortableItemData({ type: 'item', itemId: '456', rootElement: root }),
        element: document.createElement('li'),
      } as never,
    })).toBe(true);

    expect(dropTargetOptionsFor(item)?.canDrop?.({
      element: item,
      input: {} as never,
      source: {
        data: sortableItemData({ type: 'other', itemId: '456', rootElement: root }),
        element: document.createElement('li'),
      } as never,
    })).toBe(false);
  });

  it('rejects drops from itself', async () => {
    const { root, item } = await connectedItemFor({ id: '123', type: 'item' });

    expect(dropTargetOptionsFor(item)?.canDrop?.({
      element: item,
      input: {} as never,
      source: {
        data: sortableItemData({ type: 'item', itemId: '123', rootElement: root }),
        element: document.createElement('li'),
      } as never,
    })).toBe(false);
  });

  it('rejects drops from another root', async () => {
    const { item } = await connectedItemFor({ id: '123', type: 'item' });
    const foreignRoot = document.createElement('div');

    expect(dropTargetOptionsFor(item)?.canDrop?.({
      element: item,
      input: {} as never,
      source: {
        data: sortableItemData({ type: 'item', itemId: '456', rootElement: foreignRoot }),
        element: document.createElement('li'),
      } as never,
    })).toBe(false);
  });

  it('does not expose native external drag data', async () => {
    const { item } = await connectedItemFor();

    expect(draggableOptionsFor(item)?.getInitialDataForExternal).toBeUndefined();
  });

  it('prevents unhandled browser drag feedback while dragging an item', async () => {
    const { item } = await connectedItemFor();

    draggableOptionsFor(item)?.onDragStart?.(dragEventPayload(item));
    expect(preventUnhandled.start).toHaveBeenCalledOnce();

    draggableOptionsFor(item)?.onDrop?.(dragEventPayload(item));
    expect(preventUnhandled.stop).toHaveBeenCalledOnce();
  });

  it('does not start dragging from interactive descendants', async () => {
    const { item } = await connectedItemFor({
      innerHtml: '<a href="/work_packages/123">Link</a>',
    });
    const link = item.querySelector('a')!;

    vi.spyOn(document, 'elementFromPoint').mockReturnValue(link);

    expect(draggableOptionsFor(item)?.canDrag?.(dragArgs(item))).toBe(false);
  });

  it('starts dragging from non-interactive descendants', async () => {
    const { item } = await connectedItemFor({
      innerHtml: '<span>text</span>',
    });
    const text = item.querySelector('span')!;

    vi.spyOn(document, 'elementFromPoint').mockReturnValue(text);

    expect(draggableOptionsFor(item)?.canDrag?.(dragArgs(item))).toBe(true);
  });

  it('starts dragging from the focusable drag handle itself', async () => {
    const { item } = await connectedItemFor({
      innerHtml: '<article tabindex="0" data-sortable-lists--item-target="preview handle"></article>',
    });
    const handle = item.querySelector('article')!;

    vi.spyOn(document, 'elementFromPoint').mockReturnValue(handle);

    expect(draggableOptionsFor(item)?.canDrag?.(dragArgs(item, handle))).toBe(true);
  });

  it('refuses to start a drag while the root is moving', async () => {
    const { root, item } = await connectedItemFor();

    setRootMoving(root, true);

    expect(draggableOptionsFor(item)?.canDrag?.(dragArgs(item))).toBe(false);
  });

  it('refuses to start a drag when the root outlet is missing', async () => {
    const { item } = await connectedItemFor({ outlet: false });

    expect(draggableOptionsFor(item)?.canDrag?.(dragArgs(item))).toBe(false);
  });

  it('includes the root element in the drag payload', async () => {
    const { root, item } = await connectedItemFor({ id: '123', type: 'item' });

    expect(draggableOptionsFor(item)?.getInitialData?.(dragArgs(item)))
      .toEqual(expect.objectContaining({ itemId: '123', type: 'item', rootElement: root }));
  });

  describe('Stimulus application wiring', () => {
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

      expect(vi.mocked(draggable).mock.lastCall?.[0].getInitialData?.(dragArgs(article))).toEqual(expect.objectContaining({
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
});

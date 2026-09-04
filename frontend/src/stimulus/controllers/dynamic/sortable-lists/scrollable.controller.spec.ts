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

import { type autoScrollForElements as autoScrollForElementsFn } from '@atlaskit/pragmatic-drag-and-drop-auto-scroll/element';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type ScrollableControllerType from './scrollable.controller';
import type { sortableItemData as sortableItemDataFn, SortableListsRoot } from './drag-and-drop';

vi.doMock('@atlaskit/pragmatic-drag-and-drop-auto-scroll/element', () => ({
  autoScrollForElements: vi.fn(() => vi.fn()),
}));

describe('Sortable lists scrollable controller', () => {
  let autoScrollForElements:typeof autoScrollForElementsFn;
  let ScrollableController:typeof ScrollableControllerType;
  let sortableItemData:typeof sortableItemDataFn;
  let ctx:StimulusTestContext;

  beforeAll(async () => {
    ({ autoScrollForElements } = await import('@atlaskit/pragmatic-drag-and-drop-auto-scroll/element'));
    ({ default: ScrollableController } = await import('./scrollable.controller'));
    ({ sortableItemData } = await import('./drag-and-drop'));
  });

  beforeEach(async () => {
    vi.clearAllMocks();
    ctx = await setupStimulusTest({
      controllers: { 'sortable-lists--scrollable': ScrollableController },
    });
  });

  afterEach(() => ctx.dispose());

  const input = () => ({ clientX: 0, clientY: 0 }) as never;

  async function mount(values = '') {
    ctx.container.innerHTML = `<div data-controller="sortable-lists--scrollable" ${values}></div>`;
    await ctx.nextFrame();
    const element = ctx.container.querySelector<HTMLElement>('[data-controller~="sortable-lists--scrollable"]')!;
    const controller = ctx.getController<ScrollableControllerType>('sortable-lists--scrollable', element);
    return { element, controller };
  }

  function stubRoot(element:HTMLElement):SortableListsRoot {
    return {
      element,
      busy: false,
      moveInDirection: vi.fn(),
      moveAvailability: vi.fn(() => null),
      ownerListElementOf: vi.fn(() => null),
      ownerRowsContainer: vi.fn(() => null),
    };
  }

  function scrollArgs(element:HTMLElement, data:Record<string|symbol, unknown>) {
    return { element, input: input(), source: { data, element, dragHandle: null } };
  }

  it('registers auto-scroll on its own element', async () => {
    const { element } = await mount();
    expect(autoScrollForElements).toHaveBeenCalledWith(expect.objectContaining({ element }));
  });

  it('drops the previous registration and registers again on reregister', async () => {
    const { controller } = await mount();

    controller.reregister();

    expect(autoScrollForElements).toHaveBeenCalledTimes(2);
  });

  it('refuses to scroll before a root is connected', async () => {
    const { element } = await mount();
    const options = vi.mocked(autoScrollForElements).mock.lastCall?.[0];
    expect(options?.canScroll?.(scrollArgs(element, sortableItemData({ itemId: '1', type: 'work_package', rootElement: element })))).toBe(false);
  });

  it('scrolls only for sortable items owned by the connected root', async () => {
    const { element, controller } = await mount();
    const root = document.createElement('div');
    controller.connectRoot(stubRoot(root));
    const options = vi.mocked(autoScrollForElements).mock.lastCall?.[0];

    expect(options?.canScroll?.(scrollArgs(element, sortableItemData({ itemId: '1', type: 'work_package', rootElement: root })))).toBe(true);
    expect(options?.canScroll?.(scrollArgs(element, sortableItemData({ itemId: '1', type: 'work_package', rootElement: document.createElement('div') })))).toBe(false);
    expect(options?.canScroll?.(scrollArgs(element, { type: 'unrelated' }))).toBe(false);
  });

  it('exposes default vertical axis and standard speed', async () => {
    const { element } = await mount();
    const options = vi.mocked(autoScrollForElements).mock.lastCall?.[0];
    expect(options?.getAllowedAxis?.(scrollArgs(element, { type: 'x' }))).toEqual('vertical');
    expect(options?.getConfiguration?.(scrollArgs(element, { type: 'x' }))).toEqual({ maxScrollSpeed: 'standard' });
  });

  it('honours valid overrides and falls back on invalid ones', async () => {
    const valid = await mount('data-sortable-lists--scrollable-allowed-axis-value="horizontal" data-sortable-lists--scrollable-max-scroll-speed-value="fast"');
    let options = vi.mocked(autoScrollForElements).mock.lastCall?.[0];
    expect(options?.getAllowedAxis?.(scrollArgs(valid.element, { type: 'x' }))).toEqual('horizontal');
    expect(options?.getConfiguration?.(scrollArgs(valid.element, { type: 'x' }))).toEqual({ maxScrollSpeed: 'fast' });

    ctx.container.innerHTML = '';
    await ctx.nextFrame();

    const invalid = await mount('data-sortable-lists--scrollable-allowed-axis-value="sideways" data-sortable-lists--scrollable-max-scroll-speed-value="warp"');
    options = vi.mocked(autoScrollForElements).mock.lastCall?.[0];
    expect(options?.getAllowedAxis?.(scrollArgs(invalid.element, { type: 'x' }))).toEqual('vertical');
    expect(options?.getConfiguration?.(scrollArgs(invalid.element, { type: 'x' }))).toEqual({ maxScrollSpeed: 'standard' });
  });

  it('runs the auto-scroll cleanup on disconnect', async () => {
    const cleanup = vi.fn();
    vi.mocked(autoScrollForElements).mockReturnValue(cleanup);
    await mount();
    ctx.container.innerHTML = '';
    await ctx.nextFrame();
    expect(cleanup).toHaveBeenCalledOnce();
  });
});

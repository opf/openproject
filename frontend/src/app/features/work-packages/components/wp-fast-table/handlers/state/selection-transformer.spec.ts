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

import { createEnvironmentInjector, DestroyRef, EnvironmentInjector, Injector } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Subject } from 'rxjs';
import { fireEvent, waitFor } from '@testing-library/dom';
import { States } from 'core-app/core/states/states.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewFocusService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { usePlatform } from 'core-common/testing/platform';
import { WorkPackageTable } from '../../wp-fast-table';
import { buildTable, TableHarness } from '../../testing/table-harness';
import { WorkPackageFixture } from '../../testing/work-package-fixture';
import { SelectionTransformer } from './selection-transformer';

describe('SelectionTransformer', () => {
  usePlatform('Linux');

  it('stops reacting and unregisters Escape clearing when its table lifetime is destroyed', () => {
    const tableRendered = new Subject<RenderedWorkPackage[]>();
    const selectionChanged = new Subject<void>();
    const focusChanged = new Subject<void>();
    const stopAllSubscriptions = new Subject<void>();
    const renderedRows:RenderedWorkPackage[] = [
      { workPackageId: '2', classIdentifier: 'wp-row-2', hidden: false },
    ];
    const querySpace = {
      tableRendered: {
        values$: () => tableRendered,
      },
      stopAllSubscriptions,
    };
    const selection = {
      live$: () => selectionChanged,
      isSelected: vi.fn(() => false),
      hasSelectionState: true,
      selectionKeys: new Set(),
      reset: vi.fn(),
      opContextMenu: { close: vi.fn() },
    };
    const focus = {
      whenChanged: () => focusChanged,
      ifShouldFocus: vi.fn(),
      isFocused: vi.fn(() => false),
    };
    const parent = TestBed.inject(EnvironmentInjector);
    const injector = createEnvironmentInjector([
      { provide: IsolatedQuerySpace, useValue: querySpace },
      { provide: WorkPackageViewSelectionService, useValue: selection },
      { provide: WorkPackageViewFocusService, useValue: focus },
    ], parent);
    const lifetime = Injector.create({ providers: [], parent: injector });
    const root = document.createElement('div');
    root.innerHTML = `
      <div class="wp-table--row" tabindex="0" data-work-package-id="2" data-class-identifier="wp-row-2">
        <span>Subject</span>
      </div>
    `;
    document.body.append(root);
    const table = {
      injector,
      destroyRef: lifetime.get(DestroyRef),
      tableAndTimelineContainer: root,
      renderedRows,
      semantics: { paintSelection: vi.fn() },
    } as unknown as WorkPackageTable;
    new SelectionTransformer(injector, table);

    fireEvent.keyDown(document.body, { key: 'Escape' });
    expect(selection.reset).toHaveBeenCalledOnce();

    selection.reset.mockClear();
    selection.isSelected.mockClear();
    focus.ifShouldFocus.mockClear();
    const sharedStop = vi.spyOn(stopAllSubscriptions, 'next');
    lifetime.destroy();

    selectionChanged.next();
    focusChanged.next();
    tableRendered.next(renderedRows);

    fireEvent.keyDown(document.body, { key: 'Escape' });

    expect(sharedStop).not.toHaveBeenCalled();
    expect(selection.reset).not.toHaveBeenCalled();
    expect(selection.isSelected).not.toHaveBeenCalled();
    expect(focus.ifShouldFocus).not.toHaveBeenCalled();
    injector.destroy();
    root.remove();
  });

  it('keeps a surviving table clearing on Escape after another is destroyed', () => {
    const parent = TestBed.inject(EnvironmentInjector);
    const build = () => {
      const reset = vi.fn();
      const injector = createEnvironmentInjector([
        { provide: IsolatedQuerySpace, useValue: { tableRendered: { values$: () => new Subject() }, stopAllSubscriptions: new Subject<void>() } },
        { provide: WorkPackageViewSelectionService, useValue: { live$: () => new Subject(), hasSelectionState: true, selectionKeys: new Set(), reset } },
        { provide: WorkPackageViewFocusService, useValue: { whenChanged: () => new Subject(), ifShouldFocus: vi.fn(), isFocused: vi.fn(() => false) } },
      ], parent);
      const lifetime = Injector.create({ providers: [], parent: injector });
      const root = document.createElement('div');
      document.body.append(root);
      new SelectionTransformer(injector, { injector, destroyRef: lifetime.get(DestroyRef), tableAndTimelineContainer: root, renderedRows: [], semantics: { paintSelection: vi.fn() } } as unknown as WorkPackageTable);
      return { injector, lifetime, root, reset };
    };
    const first = build();
    const second = build();

    first.lifetime.destroy();
    fireEvent.keyDown(document.body, { key: 'Escape' });

    expect(first.reset).not.toHaveBeenCalled();
    expect(second.reset).toHaveBeenCalledOnce();
    second.lifetime.destroy();
    first.injector.destroy();
    second.injector.destroy();
    first.root.remove();
    second.root.remove();
  });

  it.each([
    ['Ctrl+D', { ctrlKey: true }],
    ['Meta+D', { metaKey: true }],
  ])('leaves %s to the browser with a live selection', (_name, modifier) => {
    const parent = TestBed.inject(EnvironmentInjector);
    const injector = createEnvironmentInjector([
      States,
      IsolatedQuerySpace,
      WorkPackageViewSelectionService,
      { provide: OPContextMenuService, useValue: { close: vi.fn() } },
      { provide: WorkPackageViewFocusService, useValue: { whenChanged: () => new Subject(), ifShouldFocus: vi.fn(), isFocused: vi.fn(() => false) } },
    ], parent);
    const selection = injector.get(WorkPackageViewSelectionService);
    const lifetime = Injector.create({ providers: [], parent: injector });
    const root = document.createElement('div');
    root.innerHTML = '<div class="wp-table--row" tabindex="0" data-work-package-id="2" data-class-identifier="wp-row-2">Row</div>';
    document.body.append(root);
    new SelectionTransformer(injector, { injector, destroyRef: lifetime.get(DestroyRef), tableAndTimelineContainer: root, renderedRows: [], semantics: { paintSelection: vi.fn() } } as unknown as WorkPackageTable);
    selection.initializeSelection(['2']);

    const allowed = fireEvent.keyDown(root.firstElementChild!, {
      key: 'd', keyCode: 68, which: 68, ...modifier,
    });

    expect(allowed).toBe(true);
    expect(selection.getSelectedWorkPackageIds()).toEqual(['2']);
    lifetime.destroy();
    injector.destroy();
    root.remove();
  });

  it('prunes selection only after its own table has committed', () => {
    const tableRendered = new Subject<RenderedWorkPackage[]>();
    const retainRendered = vi.fn();
    const ledger = { generation: 0 };
    const parent = TestBed.inject(EnvironmentInjector);
    const injector = createEnvironmentInjector([
      { provide: IsolatedQuerySpace, useValue: { tableRendered: { values$: () => tableRendered }, stopAllSubscriptions: new Subject<void>() } },
      { provide: WorkPackageViewSelectionService, useValue: { live$: () => new Subject(), retainRendered, hasSelectionState: false, selectionKeys: new Set(), reset: vi.fn() } },
      { provide: WorkPackageViewFocusService, useValue: { whenChanged: () => new Subject(), ifShouldFocus: vi.fn(), isFocused: vi.fn(() => false) } },
    ], parent);
    const lifetime = Injector.create({ providers: [], parent: injector });
    const root = document.createElement('div');
    document.body.append(root);
    new SelectionTransformer(injector, {
      injector, destroyRef: lifetime.get(DestroyRef), tableAndTimelineContainer: root, renderedRows: [], ledger, semantics: { paintSelection: vi.fn() },
    } as unknown as WorkPackageTable);

    const stale = [{ workPackageId: '2', classIdentifier: 'wp-card-2', hidden: false }];
    tableRendered.next(stale);
    expect(retainRendered).not.toHaveBeenCalled();

    ledger.generation = 1;
    const own = [{ workPackageId: '1', classIdentifier: 'wp-row-1', hidden: false }];
    tableRendered.next(own);
    expect(retainRendered).toHaveBeenCalledExactlyOnceWith(own);

    lifetime.destroy();
    injector.destroy();
    root.remove();
  });
});

describe('SelectionTransformer with two tables showing the same work packages', () => {
  const harnesses:TableHarness[] = [];
  let first:TableHarness;
  let second:TableHarness;

  const mount = async (workPackages:WorkPackageFixture[], states:States) => {
    const table = buildTable({ workPackages, states });
    harnesses.push(table);
    await table.render();
    // A fixed height makes the table side overflow, so it is the scroll parent the helper picks.
    table.container.style.height = '20px';
    return table;
  };

  beforeEach(async () => {
    const states = new States();
    first = await mount([{ id: '3' }, { id: '1' }, { id: '2' }, { id: '4' }], states);
    second = await mount([{ id: '1' }, { id: '2' }, { id: '3' }, { id: '4' }], states);
    first.container.scrollTop = first.container.scrollHeight;
  });

  afterEach(async () => {
    await Promise.all(harnesses.splice(0).map((table) => table.destroy()));
  });

  it('focuses and scrolls to the row in the table that asked for it', async () => {
    const firstScroll = first.container.scrollTop;
    expect(firstScroll).toBeGreaterThan(0);

    second.focus.updateFocus('3', true);
    await second.render();

    const row = second.row('3');
    await waitFor(() => expect(row).toHaveFocus());
    const { scrollTop, clientHeight } = second.container;
    const alignedTop = row.offsetTop;
    const alignedBottom = row.offsetTop + row.offsetHeight - clientHeight;
    // Firefox reports a fractional scrollTop; the offset metrics are rounded to whole pixels.
    expect(scrollTop).toBeGreaterThan(Math.min(alignedTop, alignedBottom) - 1);
    expect(scrollTop).toBeLessThan(Math.max(alignedTop, alignedBottom) + 1);
    expect(first.container.scrollTop).toBe(firstScroll);
  });

  it('leaves both tables alone when its own table does not show the row', async () => {
    const firstScroll = first.container.scrollTop;

    second.focus.updateFocus('3', true);
    await second.render([{ id: '1' }, { id: '2' }, { id: '4' }]);

    expect(document.body).toHaveFocus();
    expect(first.container.scrollTop).toBe(firstScroll);
  });
});

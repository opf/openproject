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

import { createEnvironmentInjector, EnvironmentInjector } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Subject } from 'rxjs';
import { fireEvent } from '@testing-library/dom';
import { FocusHelperService } from 'core-app/shared/directives/focus/focus-helper';
import { States } from 'core-app/core/states/states.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewFocusService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { usePlatform } from 'core-common/testing/platform';
import { WorkPackageTable } from '../../wp-fast-table';
import { SelectionTransformer } from './selection-transformer';

describe('SelectionTransformer', () => {
  usePlatform('Linux');

  it('stops reacting and unregisters keyboard selection when its injector is destroyed', () => {
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
      selectAll: vi.fn(),
      hasSelectionState: true,
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
      { provide: FocusHelperService, useValue: { focus: vi.fn() } },
    ], parent);
    const root = document.createElement('div');
    root.innerHTML = `
      <div class="wp-table--row" tabindex="0" data-work-package-id="2" data-class-identifier="wp-row-2">
        <span>Subject</span>
      </div>
    `;
    document.body.append(root);
    const table = {
      injector,
      tableAndTimelineContainer: root,
      renderedRows,
    } as unknown as WorkPackageTable;
    new SelectionTransformer(injector, table);
    const row = root.querySelector<HTMLElement>('.wp-table--row')!;

    fireEvent.keyDown(row, { key: 'a', ctrlKey: true });
    expect(selection.selectAll).toHaveBeenCalledOnce();

    fireEvent.keyDown(document.body, { key: 'Escape' });
    expect(selection.reset).toHaveBeenCalledOnce();

    selection.selectAll.mockClear();
    selection.reset.mockClear();
    selection.isSelected.mockClear();
    focus.ifShouldFocus.mockClear();
    const sharedStop = vi.spyOn(stopAllSubscriptions, 'next');
    injector.destroy();

    fireEvent.keyDown(row, { key: 'a', ctrlKey: true });
    selectionChanged.next();
    focusChanged.next();
    tableRendered.next(renderedRows);

    fireEvent.keyDown(document.body, { key: 'Escape' });

    expect(sharedStop).not.toHaveBeenCalled();
    expect(selection.selectAll).not.toHaveBeenCalled();
    expect(selection.reset).not.toHaveBeenCalled();
    expect(selection.isSelected).not.toHaveBeenCalled();
    expect(focus.ifShouldFocus).not.toHaveBeenCalled();
    root.remove();
  });

  it('keeps a surviving table clearing on Escape after another is destroyed', () => {
    const parent = TestBed.inject(EnvironmentInjector);
    const build = () => {
      const reset = vi.fn();
      const injector = createEnvironmentInjector([
        { provide: IsolatedQuerySpace, useValue: { tableRendered: { values$: () => new Subject() }, stopAllSubscriptions: new Subject<void>() } },
        { provide: WorkPackageViewSelectionService, useValue: { live$: () => new Subject(), hasSelectionState: true, reset } },
        { provide: WorkPackageViewFocusService, useValue: { whenChanged: () => new Subject(), ifShouldFocus: vi.fn(), isFocused: vi.fn(() => false) } },
        { provide: FocusHelperService, useValue: { focus: vi.fn() } },
      ], parent);
      const root = document.createElement('div');
      document.body.append(root);
      new SelectionTransformer(injector, { injector, tableAndTimelineContainer: root, renderedRows: [] } as unknown as WorkPackageTable);
      return { injector, root, reset };
    };
    const first = build();
    const second = build();

    first.injector.destroy();
    fireEvent.keyDown(document.body, { key: 'Escape' });

    expect(first.reset).not.toHaveBeenCalled();
    expect(second.reset).toHaveBeenCalledOnce();
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
      { provide: FocusHelperService, useValue: { focus: vi.fn() } },
    ], parent);
    const selection = injector.get(WorkPackageViewSelectionService);
    const root = document.createElement('div');
    root.innerHTML = '<div class="wp-table--row" tabindex="0" data-work-package-id="2" data-class-identifier="wp-row-2">Row</div>';
    document.body.append(root);
    new SelectionTransformer(injector, { injector, tableAndTimelineContainer: root, renderedRows: [] } as unknown as WorkPackageTable);
    selection.initializeSelection(['2']);

    const allowed = fireEvent.keyDown(root.firstElementChild!, {
      key: 'd', keyCode: 68, which: 68, ...modifier,
    });

    expect(allowed).toBe(true);
    expect(selection.getSelectedWorkPackageIds()).toEqual(['2']);
    injector.destroy();
    root.remove();
  });
});

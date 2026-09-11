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
import { FocusHelperService } from 'core-app/shared/directives/focus/focus-helper';
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
      registerDeselectAllListener: vi.fn(),
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

    row.dispatchEvent(new KeyboardEvent('keydown', {
      key: 'a', ctrlKey: true, bubbles: true, cancelable: true,
    }));
    expect(selection.selectAll).toHaveBeenCalledOnce();

    selection.selectAll.mockClear();
    selection.isSelected.mockClear();
    focus.ifShouldFocus.mockClear();
    const sharedStop = vi.spyOn(stopAllSubscriptions, 'next');
    injector.destroy();

    row.dispatchEvent(new KeyboardEvent('keydown', {
      key: 'a', ctrlKey: true, bubbles: true, cancelable: true,
    }));
    selectionChanged.next();
    focusChanged.next();
    tableRendered.next(renderedRows);

    expect(sharedStop).not.toHaveBeenCalled();
    expect(selection.selectAll).not.toHaveBeenCalled();
    expect(selection.isSelected).not.toHaveBeenCalled();
    expect(focus.ifShouldFocus).not.toHaveBeenCalled();
    root.remove();
  });
});

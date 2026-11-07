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

import '@openproject/primer-view-components/app/components/primer/alpha/tool_tip.js';
import { fireEvent, within } from '@testing-library/dom';
import { ApplicationRef } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { OpActionMenuService } from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu.service';
import { OpTableActionsService } from 'core-app/features/work-packages/components/wp-table/table-actions/table-actions.service';
import { OpTableActionFactory } from 'core-app/features/work-packages/components/wp-table/table-actions/table-action';
import { MountedTableActionButtons } from 'core-app/features/work-packages/components/wp-table/table-actions/mounted-table-action-buttons.service';
import {
  OpMountedContextMenuTableAction,
  OpStaticContextMenuTableAction,
} from 'core-app/features/work-packages/components/wp-table/table-actions/actions/primer-context-menu-table-action';
import { buildTable, TableHarness } from '../testing/table-harness';

type Variant = 'static'|'mounted';

const factories:Record<Variant, OpTableActionFactory> = {
  static: (injector, workPackage) => new OpStaticContextMenuTableAction(injector, workPackage),
  mounted: (injector, workPackage) => new OpMountedContextMenuTableAction(injector, workPackage),
};

const fixtures = (count:number, offset = 0) => Array.from({ length: count }, (_, i) => ({ id: String(offset + i + 1) }));

describe.each<Variant>(['static', 'mounted'])('%s Primer context menu action', (variant) => {
  let harness:TableHarness;

  const mount = async (count = 3) => {
    harness = buildTable({
      workPackages: fixtures(count),
      productionMarkup: true,
      configuration: { actionsColumnEnabled: true, contextMenuEnabled: true },
      translations: { 'js.label_open_context_menu': 'Open context menu' },
      providers: [
        MountedTableActionButtons,
        {
          provide: OpTableActionsService,
          useFactory: () => {
            const actions = new OpTableActionsService();
            actions.setActions(factories[variant]);
            return actions;
          },
        },
      ],
    });
    await harness.render();
  };

  afterEach(() => harness.destroy());

  it('renders one invisible icon button with a tooltip label per row', async () => {
    await mount();

    ['1', '2', '3'].forEach((id) => {
      const button = within(harness.row(id)).getByRole('button', { name: 'Open context menu' });
      expect(button).toHaveClass('Button--iconOnly', 'Button--invisible', 'wp-table-context-menu-link');
      expect(button.querySelector('svg')).toBeInTheDocument();
      expect(document.querySelector(`tool-tip[for="${button.id}"]`)).toHaveTextContent('Open context menu');
    });
  });

  it('opens the action menu on click', async () => {
    await mount();
    const show = vi.spyOn(harness.injector.get(OpActionMenuService), 'show').mockImplementation(() => undefined);

    fireEvent.click(within(harness.row('2')).getByRole('button', { name: 'Open context menu' }));

    expect(show).toHaveBeenCalledOnce();
  });

  it('keeps one live button view per rendered row through a redraw', async () => {
    const appRef = TestBed.inject(ApplicationRef);
    const viewsBefore = appRef.viewCount;
    const started = performance.now();
    await mount(100);
    const rendered = performance.now();
    const viewsAfterRender = appRef.viewCount - viewsBefore;
    await harness.render(fixtures(100, 100));
    const redrawn = performance.now();
    const viewsAfterRedraw = appRef.viewCount - viewsBefore;
    const tickStarted = performance.now();
    for (let i = 0; i < 50; i += 1) appRef.tick();
    const tickAverage = (performance.now() - tickStarted) / 50;

    // eslint-disable-next-line no-console -- spike measurement output
    console.info(`[table-action-variants] ${variant}: render ${(rendered - started).toFixed(1)}ms, redraw ${(redrawn - rendered).toFixed(1)}ms, views +${viewsAfterRender} after render, +${viewsAfterRedraw} after redraw, tick ${tickAverage.toFixed(2)}ms (dev mode, rough)`);

    expect(within(harness.row('150')).getByRole('button', { name: 'Open context menu' })).toBeInTheDocument();
    expect(viewsAfterRedraw).toBe(variant === 'mounted' ? 100 : 0);
  });

  it('releases every mounted view when the table is destroyed', async () => {
    const appRef = TestBed.inject(ApplicationRef);
    const viewsBefore = appRef.viewCount;
    await mount(10);

    await harness.destroy();

    expect(appRef.viewCount).toBe(viewsBefore);
  });
});

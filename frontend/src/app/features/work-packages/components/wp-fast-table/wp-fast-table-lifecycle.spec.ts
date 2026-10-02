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

import { ElementRef, Injector, runInInjectionContext } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { fireEvent, waitFor } from '@testing-library/dom';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { EmbeddedTablesMacroComponent } from 'core-app/features/work-packages/components/wp-table/embedded/embedded-tables-macro.component';
import { States } from 'core-app/core/states/states.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { WorkPackageTableConfigurationObject } from 'core-app/features/work-packages/components/wp-table/wp-table-configuration';
import { buildTable, TableHarness, TableHarnessOptions } from './testing/table-harness';
import { buildWorkPackage } from './testing/work-package-fixture';

const newStatus = { href: '/api/v3/statuses/1' };
const inProgressStatus = { href: '/api/v3/statuses/2' };

const grouped:TableHarnessOptions = {
  workPackages: [
    { id: '1', attributes: { status: newStatus } },
    { id: '2', attributes: { status: newStatus } },
    { id: '3', attributes: { status: inProgressStatus } },
  ],
  groups: [
    { value: 'New', href: newStatus.href, count: 2 },
    { value: 'In progress', href: inProgressStatus.href, count: 1 },
  ],
};

describe('WorkPackageTable lifecycle', () => {
  const harnesses:TableHarness[] = [];

  const mount = async (options:TableHarnessOptions) => {
    const harness = buildTable(options);
    harnesses.push(harness);
    await harness.render();
    return harness;
  };

  const toggleGroup = (harness:TableHarness, index:number) => {
    fireEvent.click(harness.groupHeader(index).querySelector('.expander')!);
  };

  afterEach(async () => {
    await Promise.all(harnesses.splice(0).map((harness) => harness.destroy()));
  });

  describe('with two tables showing the same work packages', () => {
    let states:States;
    let first:TableHarness;
    let second:TableHarness;

    beforeEach(async () => {
      states = new States();
      first = await mount({ ...grouped, states });
      second = await mount({ ...grouped, states });
    });

    it('keeps selection and the current work package with the table that was clicked', () => {
      first.click('2');

      expect(first.selection.getSelectedWorkPackageIds()).toEqual(['2']);
      expect(first.focus.focusedWorkPackage).toBe('2');
      expect(first.row('2')).toHaveClass('-checked');
      expect(second.selection.isEmpty).toBe(true);
      expect(second.focus.focusedWorkPackage).toBe('1');
      expect(second.row('2')).not.toHaveClass('-checked');
    });

    it('collapses a group only in its own table', async () => {
      toggleGroup(first, 0);

      await waitFor(() => expect(first.row('1')).not.toBeVisible());
      expect(second.row('1')).toBeVisible();
      expect(second.row('2')).toBeVisible();
      expect(second.renderedState()).toEqual([['1', false], ['2', false], ['3', false]]);
    });

    it('refreshes a changed work package in every table showing it', async () => {
      states.workPackages.get('1').putValue(buildWorkPackage({ id: '1', subject: 'Renamed', attributes: { status: newStatus } }));

      await waitFor(() => expect(first.row('1')).toHaveTextContent('Renamed'));
      await waitFor(() => expect(second.row('1')).toHaveTextContent('Renamed'));
    });

    it('keeps the surviving table working after the other is destroyed', async () => {
      await first.destroy();

      second.click('2');
      toggleGroup(second, 1);

      expect(second.selection.getSelectedWorkPackageIds()).toEqual(['2']);
      await waitFor(() => expect(second.row('3')).not.toBeVisible());
    });

    it('stops redrawing a table once its query space stops', async () => {
      first.querySpace.stopAllSubscriptions.next();

      first.querySpace.results.putValue({ elements: [buildWorkPackage({ id: '9' })] } as WorkPackageCollectionResource);
      first.querySpace.initialized.putValue(null);
      await second.render([{ id: '9', attributes: { status: newStatus } }]);

      expect(second.rowIds()).toEqual(['9']);
      expect(first.rowIds()).toEqual(['1', '2', '3']);
    });
  });

  describe('with consumer configuration over production defaults', () => {
    const mountConfigured = (configuration?:WorkPackageTableConfigurationObject) => mount({
      workPackages: [{ id: '1' }, { id: '2' }],
      configuration,
      productionDefaults: true,
    });

    it('opens the table menu with the default configuration', async () => {
      const harness = await mountConfigured();
      const opened = vi.spyOn(harness.injector.get(OPContextMenuService), 'show');

      expect(fireEvent.contextMenu(harness.row('1'))).toBe(false);
      expect(opened).toHaveBeenCalledTimes(1);
    });

    it('leaves the native context menu alone in the embedded table macro', async () => {
      const host = Injector.create({
        providers: [{ provide: ElementRef, useValue: new ElementRef(document.createElement('div')) }],
        parent: TestBed.inject(Injector),
      });
      const macro = runInInjectionContext(host, () => new EmbeddedTablesMacroComponent());
      const harness = await mountConfigured(macro.configuration);
      const opened = vi.spyOn(harness.injector.get(OPContextMenuService), 'show');

      expect(fireEvent.contextMenu(harness.row('1'))).toBe(true);
      expect(fireEvent.keyDown(harness.row('1'), { key: 'F10', shiftKey: true, altKey: true })).toBe(true);

      expect(opened).not.toHaveBeenCalled();
      expect(harness.selection.isEmpty).toBe(true);
    });
  });

  it('does not duplicate click and context menu effects across rerenders', async () => {
    const harness = await mount({ workPackages: [{ id: '1' }, { id: '2' }], configuration: { contextMenuEnabled: true } });
    await harness.render([{ id: '1' }, { id: '2' }]);
    await harness.render([{ id: '2' }, { id: '1' }]);
    const clicked:string[] = [];
    harness.outputs.itemClicked.subscribe(({ workPackageId }) => clicked.push(workPackageId));
    const opened = vi.spyOn(harness.injector.get(OPContextMenuService), 'show');

    harness.click('1');
    fireEvent.contextMenu(harness.row('2'));

    expect(clicked).toEqual(['1']);
    expect(opened).toHaveBeenCalledTimes(1);
  });
});

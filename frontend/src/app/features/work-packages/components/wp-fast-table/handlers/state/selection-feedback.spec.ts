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

import { fireEvent } from '@testing-library/dom';
import { LiveRegionElement } from '@primer/live-region-element';
import { type MockInstance } from 'vitest';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageContextMenuHelperService } from 'core-app/features/work-packages/components/wp-table/context-menu-helper/wp-context-menu-helper.service';
import { OpTableActionsService } from 'core-app/features/work-packages/components/wp-table/table-actions/table-actions.service';
import { OpDetailsTableAction } from 'core-app/features/work-packages/components/wp-table/table-actions/actions/details-table-action';
import { buildTable, TableHarness } from '../../testing/table-harness';

describe('Table selection feedback', () => {
  let harness:TableHarness;
  let announceSpy:MockInstance<typeof LiveRegionElement.prototype.announce>;

  const detailsActions = () => {
    const actions = new OpTableActionsService();
    actions.setActions((injector, workPackage) => new OpDetailsTableAction(injector, workPackage));
    return actions;
  };

  const mount = async (keyboardNavigationEnabled:boolean, actionsColumnEnabled = false) => {
    harness = buildTable({
      configuration: { keyboardNavigationEnabled, contextMenuEnabled: true, actionsColumnEnabled },
      productionMarkup: true,
      workPackages: [{ id: '1' }, { id: '2' }, { id: '3' }, { id: '4' }],
      providers: actionsColumnEnabled ? [{ provide: OpTableActionsService, useFactory: detailsActions }] : [],
    });
    await harness.render();
    vi.spyOn(harness.injector.get(WorkPackageContextMenuHelperService), 'getPermittedActions')
      .mockImplementation((_workPackages:WorkPackageResource[]) => []);
  };

  const spoken = () => announceSpy.mock.calls.map(([message]) => message);
  const openDetails = (workPackageId:string) => fireEvent.click(
    harness.row(workPackageId).querySelector<HTMLElement>('a[data-wp-state="split"]')!,
  );
  const escape = () => fireEvent.keyDown(document.body, { key: 'Escape' });

  beforeEach(() => {
    document.body.append(document.createElement('live-region'));
    announceSpy = vi.spyOn(LiveRegionElement.prototype, 'announce');
    window.I18n.store({
      en: {
        js: {
          work_packages: {
            selection: {
              all_selected: {
                one: 'All %{count} work package on this page selected.',
                other: 'All %{count} work packages on this page selected.',
              },
              cleared: 'Selection cleared.',
              selected: { one: '%{count} work package selected.', other: '%{count} work packages selected.' },
            },
          },
        },
      },
    });
  });

  afterEach(async () => {
    await harness.destroy();
    document.querySelector('live-region')?.remove();
    announceSpy.mockRestore();
  });

  describe('on a capability-on table', () => {
    beforeEach(() => mount(true));

    it('plain click on an unselected row is silent', () => {
      harness.click('1');
      harness.click('2');

      expect(announceSpy).not.toHaveBeenCalled();
    });

    it('plain click collapsing a batch announces the new count', () => {
      harness.click('1');
      harness.click('3', { shiftKey: true });
      announceSpy.mockClear();

      harness.click('2');

      expect(spoken()).toEqual(['1 work package selected.']);
    });

    it('Ctrl-click toggle announces', () => {
      harness.click('1');
      harness.click('2', { ctrlKey: true });
      harness.click('2', { ctrlKey: true });

      expect(spoken()).toEqual(['2 work packages selected.', '1 work package selected.']);
    });

    it('Shift-click range announces', () => {
      harness.click('1');
      harness.click('3', { shiftKey: true });

      expect(spoken()).toEqual(['3 work packages selected.']);
    });

    it('Shift-click same-count replacement announces', () => {
      harness.click('2');
      harness.click('1', { shiftKey: true });
      announceSpy.mockClear();

      harness.click('3', { shiftKey: true });

      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['2', '3']);
      expect(spoken()).toEqual(['2 work packages selected.']);
    });

    it('Escape that clears membership announces "Selection cleared."', () => {
      harness.click('1');
      harness.click('2', { ctrlKey: true });
      announceSpy.mockClear();

      escape();

      expect(spoken()).toEqual(['Selection cleared.']);
    });

    it('Escape that only drops an anchor is silent', () => {
      harness.click('1');
      harness.click('1', { ctrlKey: true });
      announceSpy.mockClear();
      expect(harness.selection.hasSelectionState).toBe(true);

      escape();

      expect(announceSpy).not.toHaveBeenCalled();
      expect(harness.selection.hasSelectionState).toBe(false);
    });

    it('right-click on an unselected row inside a batch collapse announces', () => {
      harness.click('1');
      harness.click('2', { shiftKey: true });
      announceSpy.mockClear();

      fireEvent.contextMenu(harness.row('3'));

      expect(spoken()).toEqual(['1 work package selected.']);
    });

    it('drag collapse announces', () => {
      harness.click('1');
      harness.click('2', { shiftKey: true });
      announceSpy.mockClear();

      harness.dragStart('3');

      expect(spoken()).toEqual(['1 work package selected.']);
    });

    it('pruning after a re-render that drops a selected row announces the new count', async () => {
      harness.click('1');
      harness.click('3', { shiftKey: true });
      announceSpy.mockClear();

      await harness.render([{ id: '1' }, { id: '2' }]);

      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1', '2']);
      expect(spoken()).toEqual(['2 work packages selected.']);
    });

    it('pruning a selection set by the route on the first render is silent', async () => {
      harness.selection.initializeSelection(['99']);

      await harness.render();

      expect(harness.selection.isEmpty).toBe(true);
      expect(announceSpy).not.toHaveBeenCalled();
    });

    it('pruning after a programmatic update is silent', async () => {
      harness.click('1');
      harness.click('3', { shiftKey: true });
      harness.selection.update({ selected: { 2: true, 3: true } });
      announceSpy.mockClear();

      await harness.render([{ id: '1' }, { id: '2' }]);

      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['2']);
      expect(announceSpy).not.toHaveBeenCalled();
    });

    it('a gesture after a programmatic update announces normally', () => {
      harness.selection.update({ selected: { 2: true } });

      harness.click('3', { ctrlKey: true });

      expect(spoken()).toEqual(['2 work packages selected.']);
    });
  });

  describe('split-details link on a capability-on table', () => {
    beforeEach(() => mount(true, true));

    it('collapsing a batch announces the new count once', () => {
      harness.click('1');
      harness.click('2', { shiftKey: true });
      announceSpy.mockClear();

      openDetails('3');

      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['3']);
      expect(spoken()).toEqual(['1 work package selected.']);
    });

    it('moving a single selection is silent', () => {
      harness.click('1');

      openDetails('2');

      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['2']);
      expect(announceSpy).not.toHaveBeenCalled();
    });
  });

  describe('split-details link on a capability-off table', () => {
    beforeEach(() => mount(false, true));

    it('announces nothing when collapsing a batch', () => {
      harness.click('1');
      harness.click('2', { shiftKey: true });

      openDetails('3');

      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['3']);
      expect(announceSpy).not.toHaveBeenCalled();
    });
  });

  describe('on a capability-off table', () => {
    beforeEach(() => mount(false));

    it('announces nothing across the same script', async () => {
      harness.click('1');
      harness.click('3', { shiftKey: true });
      harness.click('2', { ctrlKey: true });
      harness.click('2');
      harness.click('1', { shiftKey: true });
      fireEvent.contextMenu(harness.row('3'));
      harness.dragStart('2');
      escape();
      await harness.render([{ id: '1' }]);

      expect(harness.table.selectionFeedback).toBeNull();
      expect(announceSpy).not.toHaveBeenCalled();
    });
  });
});

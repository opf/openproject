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

import { fireEvent, waitFor, within } from '@testing-library/dom';
import type { Mock } from 'vitest';
import { userEvent } from 'vitest/browser';
import { activeFieldClassName } from 'core-app/shared/components/fields/edit/edit-form/edit-form';
import { buildTable, TableHarness } from '../../testing/table-harness';
import { uiStateLinkClass } from '../../builders/ui-state-link-builder';
import { navigableCells } from './keyboard/roving-tabindex';

type ItemClicked = (event:{ workPackageId:string, double:boolean }) => void;

describe('Table with selection disabled', () => {
  let harness:TableHarness;
  let itemClicked:Mock<ItemClicked>;

  beforeEach(async () => {
    harness = buildTable({
      workPackages: [{ id: '1' }, { id: '2' }],
      productionMarkup: true,
      configuration: { selectionEnabled: false, inlineEditEnabled: false },
    });
    await harness.render();
    itemClicked = vi.fn<ItemClicked>();
    harness.outputs.itemClicked.subscribe(itemClicked);
  });

  afterEach(() => harness.destroy());

  const focusRow = (workPackageId:string) => {
    const navigation = harness.table.keyboardNavigation;
    navigation.focusPosition(navigation.positionOfCell(harness.row(workPackageId))!);
    expect(harness.row(workPackageId)).toHaveFocus();
  };

  const expectNothingSelected = () => {
    expect(harness.selection.getSelectedWorkPackageIds()).toEqual([]);
    expect(harness.focus.explicitlyFocusedWorkPackage).toBeNull();
    harness.rows().forEach((row) => {
      expect(row).not.toHaveAttribute('aria-selected');
      expect(row).not.toHaveAttribute('data-pressed');
    });
  };

  it('moves keyboard focus to a clicked cell without selecting or opening its row', () => {
    fireEvent.click(within(harness.row('2')).getByLabelText(/^subject /));

    expect(harness.row('2')).toContainElement(document.activeElement as HTMLElement);
    expect(itemClicked).not.toHaveBeenCalled();
    expectNothingSelected();
  });

  it('leaves focus on a button clicked inside a cell', () => {
    const button = document.createElement('button');
    navigableCells(harness.row('2'))[0].append(button);
    button.focus();

    fireEvent.click(button);

    expect(button).toHaveFocus();
    expectNothingSelected();
  });

  it('does not open a row on double click', () => {
    fireEvent.dblClick(harness.row('1').cells[1]);

    expect(itemClicked).not.toHaveBeenCalled();
    expectNothingSelected();
  });

  it('ignores modified clicks', () => {
    harness.click('1', { ctrlKey: true });
    harness.click('2', { shiftKey: true });

    expect(itemClicked).not.toHaveBeenCalled();
    expectNothingSelected();
  });

  it('does not activate a row with Enter and leaves the key to the browser', () => {
    focusRow('1');

    const notPrevented = fireEvent.keyDown(document.activeElement!, { key: 'Enter' });

    expect(notPrevented).toBe(true);
    expect(itemClicked).not.toHaveBeenCalled();
    expectNothingSelected();
  });

  it.each([
    ['Shift+Space', { key: ' ', code: 'Space', shiftKey: true }],
    ['Ctrl+A', { key: 'a', ctrlKey: true }],
    ['Meta+A', { key: 'a', metaKey: true }],
  ])('does not select rows with %s', (_name, init) => {
    focusRow('1');

    fireEvent.keyDown(document.activeElement!, init);

    expect(harness.row('1')).toContainElement(document.activeElement as HTMLElement);
    expectNothingSelected();
  });

  it('moves focus with Shift+ArrowDown without selecting', () => {
    focusRow('1');

    const notPrevented = fireEvent.keyDown(document.activeElement!, { key: 'ArrowDown', shiftKey: true });

    expect(notPrevented).toBe(false);
    expect(harness.row('2')).toContainElement(document.activeElement as HTMLElement);
    expectNothingSelected();
  });

  it('keeps Shift+Space from scrolling the page', () => {
    focusRow('1');

    const notPrevented = fireEvent.keyDown(document.activeElement!, { key: ' ', code: 'Space', shiftKey: true });

    expect(notPrevented).toBe(false);
  });

  describe('with a work package state link', () => {
    let link:HTMLAnchorElement;
    let stateLinkClicked:Mock<(event:{ workPackageId:string, requestedState:string }) => void>;

    beforeEach(() => {
      link = document.createElement('a');
      link.href = '#';
      link.textContent = '1';
      link.classList.add(uiStateLinkClass);
      link.dataset.wpState = 'show';
      link.dataset.workPackageId = '1';
      navigableCells(harness.row('1'))[0].append(link);
      stateLinkClicked = vi.fn();
      harness.outputs.stateLinkClicked.subscribe(stateLinkClicked);
    });

    it('opens the work package on click without selecting it', () => {
      fireEvent.click(link);

      expect(stateLinkClicked).toHaveBeenCalledWith({ workPackageId: '1', requestedState: 'show' });
      expectNothingSelected();
    });

    it('opens the work package with Enter without selecting it', async () => {
      link.focus();

      await userEvent.keyboard('{Enter}');

      expect(stateLinkClicked).toHaveBeenCalledWith({ workPackageId: '1', requestedState: 'show' });
      expectNothingSelected();
    });
  });

  it('still moves focus with ArrowDown', () => {
    focusRow('1');

    fireEvent.keyDown(document.activeElement!, { key: 'ArrowDown' });

    expect(harness.row('2')).toContainElement(document.activeElement as HTMLElement);
  });

  it('keeps an existing selection when a row is picked up for dragging', async () => {
    await harness.destroy();
    harness = buildTable({
      workPackages: [{ id: '1' }, { id: '2' }],
      configuration: { selectionEnabled: false, dragAndDropEnabled: true },
    });
    await harness.render();
    harness.selection.replaceSelection('1');

    harness.dragStart('2');

    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1']);
  });
});

describe('Table with selection disabled and inline editing enabled', () => {
  let harness:TableHarness;

  beforeEach(async () => {
    harness = buildTable({
      workPackages: [{ id: '1', subject: 'Editable record' }],
      editing: {},
      configuration: { selectionEnabled: false },
      translations: { 'js.inplace.button_edit': '%{attribute}: Edit' },
    });
    await harness.render();
  });

  afterEach(() => harness.destroy());

  it('leaves focus in the editor opened by a click', async () => {
    fireEvent.click(within(harness.row('1')).getByLabelText('subject Editable record: Edit'));

    await waitFor(() => expect(within(harness.row('1')).getByRole('textbox')).toHaveFocus());
    expect(harness.selection.getSelectedWorkPackageIds()).toEqual([]);
  });

  it('keeps focus in the open editor when clicking inside it', async () => {
    fireEvent.click(within(harness.row('1')).getByLabelText('subject Editable record: Edit'));
    const textbox = await within(harness.row('1')).findByRole('textbox');
    await waitFor(() => expect(textbox).toHaveFocus());

    fireEvent.click(textbox);

    expect(textbox).toHaveFocus();
  });

  it('keeps focus in the open editor when clicking a control nested inside it', async () => {
    fireEvent.click(within(harness.row('1')).getByLabelText('subject Editable record: Edit'));
    const textbox = await within(harness.row('1')).findByRole('textbox');
    await waitFor(() => expect(textbox).toHaveFocus());
    const host = document.createElement('div');
    host.classList.add(activeFieldClassName);
    const nested = document.createElement('button');
    host.append(nested);
    textbox.closest('td, th')!.append(host);

    fireEvent.click(nested);

    expect(textbox).toHaveFocus();
  });
});

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
import { userEvent } from 'vitest/browser';
import { buildTable, TableHarness, TableHarnessOptions } from '../../../testing/table-harness';
import { wpOccurrenceKey } from '../../../rendered-occurrence-ledger';
import { States } from 'core-app/core/states/states.service';
import { insideGrid, navigableCells } from './roving-tabindex';
import { cellTargets, rowControls } from './cell-interaction';
import { activateTableField } from '../../cell/edit-cell-handler';
import { OpTableActionsService } from 'core-app/features/work-packages/components/wp-table/table-actions/table-actions.service';
import { OpUnlinkTableAction } from 'core-app/features/work-packages/components/wp-table/table-actions/actions/unlink-table-action';

describe('CellInteraction', () => {
  const harnesses:TableHarness[] = [];

  const mount = async (options:Partial<TableHarnessOptions> = {}) => {
    const table = buildTable({
      workPackages: [{ id: '1' }, { id: '2' }],
      editing: {},
      productionMarkup: true,
      ...options,
      configuration: { inlineCreateEnabled: true, ...options.configuration },
    });
    harnesses.push(table);
    await table.render();
    return table;
  };

  const positionOf = (table:TableHarness, cell:HTMLElement) => table.table.keyboardNavigation!.positionOfCell(cell)!;

  afterEach(async () => {
    await Promise.all(harnesses.splice(0).map((table) => table.destroy()));
  });

  it('classifies only enabled visible non-editor controls in DOM order', async () => {
    const table = await mount();
    const cell = navigableCells(table.row('1'))[0];
    const link = document.createElement('a');
    link.href = '#';
    const button = document.createElement('button');
    const input = document.createElement('input');
    const select = document.createElement('select');
    const textarea = document.createElement('textarea');
    const roleButton = document.createElement('span');
    roleButton.setAttribute('role', 'button');
    const disabled = document.createElement('button');
    disabled.disabled = true;
    const disabledInput = document.createElement('input');
    disabledInput.disabled = true;
    const hidden = document.createElement('button');
    hidden.style.display = 'none';
    const ariaHidden = document.createElement('button');
    ariaHidden.setAttribute('aria-hidden', 'true');
    const ariaDisabled = document.createElement('span');
    ariaDisabled.setAttribute('role', 'button');
    ariaDisabled.setAttribute('aria-disabled', 'true');
    const drag = document.createElement('span');
    const fieldset = document.createElement('fieldset');
    fieldset.disabled = true;
    const fieldsetInput = document.createElement('input');
    fieldset.append(fieldsetInput);
    cell.append(link, button, input, select, textarea, roleButton, disabled, disabledInput, hidden, ariaHidden, ariaDisabled, drag, fieldset);

    expect(cellTargets(cell)).toEqual([link, button, input, select, textarea, roleButton]);
  });

  it('activates a single control from the cell without moving focus', async () => {
    const table = await mount();
    const cell = navigableCells(table.row('1'))[0];
    const link = document.createElement('a');
    link.href = '#';
    cell.append(link);
    const click = vi.spyOn(link, 'click').mockImplementation(() => undefined);
    table.table.keyboardNavigation!.focusPosition(positionOf(table, cell));

    fireEvent.keyDown(cell, { key: 'Enter' });

    expect(click).toHaveBeenCalledOnce();
    expect(cell).toHaveFocus();
  });

  describe('with an unlink action', () => {
    const mountWithUnlink = async () => {
      const unlink = vi.fn();
      const table = await mount({
        configuration: { actionsColumnEnabled: true },
        providers: [{
          provide: OpTableActionsService,
          useFactory: () => {
            const actions = new OpTableActionsService();
            actions.setActions(OpUnlinkTableAction.factoryFor('remove-child-action', 'Remove child', unlink));
            return actions;
          },
        }],
      });
      const link = within(table.row('1')).getByRole('link', { name: 'Remove child' });
      table.table.keyboardNavigation!.focusPosition(positionOf(table, link.closest('td, th')!));
      return { table, unlink, link, cell: link.closest('td, th')! };
    };

    it('focuses the unlink control on Enter and activates it on a second Enter', async () => {
      const { table, unlink, link } = await mountWithUnlink();

      await userEvent.keyboard('{Enter}');

      expect(link).toHaveFocus();
      expect(unlink).not.toHaveBeenCalled();

      await userEvent.keyboard('{Enter}');

      expect(unlink).toHaveBeenCalledExactlyOnceWith(table.injector.get(States).workPackages.get('1').value);
    });

    it('cancels a repeated Enter on a destructive control', async () => {
      const { table, unlink, link } = await mountWithUnlink();
      await userEvent.keyboard('{Enter}');
      expect(link).toHaveFocus();

      const repeated = new KeyboardEvent('keydown', { key: 'Enter', repeat: true, bubbles: true, cancelable: true });
      link.dispatchEvent(repeated);

      expect(repeated.defaultPrevented).toBe(true);
      expect(unlink).not.toHaveBeenCalled();

      await userEvent.keyboard('{Enter}');

      expect(unlink).toHaveBeenCalledExactlyOnceWith(table.injector.get(States).workPackages.get('1').value);
    });

    it('returns from the focused unlink control to its cell with Escape and continues the walk with Tab', async () => {
      const { table, link, cell } = await mountWithUnlink();
      await userEvent.keyboard('{Enter}');
      expect(link).toHaveFocus();

      await userEvent.keyboard('{Escape}');
      expect(cell).toHaveFocus();

      await userEvent.keyboard('{Enter}');
      expect(link).toHaveFocus();
      await userEvent.tab({ shift: true });
      expect(cell).toHaveFocus();

      await userEvent.keyboard('{Enter}');
      await userEvent.tab();
      expect(within(table.container).getByRole('button', { name: 'Create new work package' })).toHaveFocus();
    });

    it('still activates the ID link of the same row without moving focus', async () => {
      const { table } = await mountWithUnlink();
      const idCell = navigableCells(table.row('1'))[0];
      const idLink = idCell.appendChild(document.createElement('a'));
      idLink.href = '#';
      idLink.textContent = '1';
      const click = vi.spyOn(idLink, 'click').mockImplementation(() => undefined);
      table.table.keyboardNavigation!.focusPosition(positionOf(table, idCell));

      await userEvent.keyboard('{Enter}');

      expect(click).toHaveBeenCalledOnce();
      expect(idCell).toHaveFocus();
    });
  });

  it('focuses the first control of a several-control cell', async () => {
    const table = await mount();
    const cell = navigableCells(table.row('1'))[0];
    const first = document.createElement('button');
    const second = document.createElement('button');
    cell.append(first, second);
    table.table.keyboardNavigation!.focusPosition(positionOf(table, cell));

    fireEvent.keyDown(cell, { key: 'Enter' });

    expect(first).toHaveFocus();
    expect(second).not.toHaveFocus();
    expect(table.table.keyboardNavigation!.position).toEqual(positionOf(table, cell));
  });

  it.each(['Enter', 'F2'])('opens an editable cell with %s', async (key) => {
    const table = await mount();
    const cell = navigableCells(table.row('1'))[1];
    table.table.keyboardNavigation!.focusPosition(positionOf(table, cell));

    fireEvent.keyDown(cell, { key });

    await waitFor(() => expect(within(cell).getByRole('textbox')).toHaveFocus());
  });

  it('reuses an already-open editor with its instance and draft', async () => {
    const table = await mount();
    const cell = navigableCells(table.row('1'))[1];
    table.table.keyboardNavigation!.focusPosition(positionOf(table, cell));
    fireEvent.keyDown(cell, { key: 'Enter' });
    const input = await waitFor(() => within(cell).getByRole<HTMLInputElement>('textbox'));
    await waitFor(() => expect(table.table.editing.forms['1'].activeFields.subject).toBeDefined());
    const handler = table.table.editing.forms['1'].activeFields.subject;
    input.value = 'Draft';
    table.table.keyboardNavigation!.focusPosition(positionOf(table, cell));

    fireEvent.keyDown(cell, { key: 'F2' });

    expect(table.table.editing.forms['1'].activeFields.subject).toBe(handler);
    expect(within(cell).getByRole('textbox')).toBe(input);
    expect(input).toHaveFocus();
    expect(input).toHaveValue('Draft');
    expect(table.table.keyboardNavigation!.position).toEqual(positionOf(table, cell));
  });

  it('focuses an open editor overlay instead of its trigger on re-entry', async () => {
    const table = await mount();
    const cell = navigableCells(table.row('1'))[1];
    table.table.keyboardNavigation!.focusPosition(positionOf(table, cell));
    fireEvent.keyDown(cell, { key: 'Enter' });
    await waitFor(() => expect(table.table.editing.forms['1'].activeFields.subject).toBeDefined());
    const handler = table.table.editing.forms['1'].activeFields.subject;
    const overlay = document.body.appendChild(document.createElement('div'));
    const overlayButton = overlay.appendChild(document.createElement('button'));
    handler.registerOverlay(overlay);
    cell.focus();

    fireEvent.keyDown(cell, { key: 'Enter' });

    expect(overlayButton).toHaveFocus();
    expect(table.table.editing.forms['1'].activeFields.subject).toBe(handler);
    overlay.remove();
  });

  it('does nothing for F2 on a non-editable cell', async () => {
    const table = await mount();
    const cell = navigableCells(table.row('1'))[0];
    table.table.keyboardNavigation!.focusPosition(positionOf(table, cell));

    expect(fireEvent.keyDown(cell, { key: 'F2' })).toBe(true);
    expect(cell.querySelector('input')).toBeNull();
  });

  it('toggles a group from its cell with Enter', async () => {
    const table = await mount({
      workPackages: [{ id: '1', attributes: { status: { href: '/api/v3/statuses/1' } } }],
      groups: [{ value: 'New', href: '/api/v3/statuses/1', count: 1 }],
    });
    const group = table.groupHeader(0);
    const cell = navigableCells(group)[0];
    table.table.keyboardNavigation!.focusPosition(positionOf(table, cell));

    fireEvent.keyDown(cell, { key: 'Enter' });

    expect(table.row('1')).not.toBeVisible();
    expect(navigableCells(table.groupHeader(0))[0]).toHaveFocus();
  });

  it('walks row controls in DOM order with native exit and reverse return', async () => {
    const table = await mount();
    const cells = navigableCells(table.row('1'));
    const idLink = document.createElement('a');
    idLink.href = '#';
    idLink.textContent = '1';
    const details = document.createElement('button');
    details.textContent = 'Details';
    const menu = document.createElement('button');
    menu.textContent = 'Menu';
    cells[0].append(idLink);
    cells[1].append(details, menu);
    const create = within(table.container).getByRole('button', { name: 'Create new work package' });
    const before = document.createElement('button');
    table.table.tableAndTimelineContainer.before(before);
    table.table.keyboardNavigation!.focusPosition({ key: wpOccurrenceKey('1'), cell: null, desiredColumn: null });
    const originalPosition = table.table.keyboardNavigation!.position;
    const selection = table.selection.getSelectedWorkPackageIds();

    await userEvent.tab();
    expect(idLink).toHaveFocus();
    await userEvent.tab();
    expect(details).toHaveFocus();
    await userEvent.tab();
    expect(menu).toHaveFocus();
    await userEvent.tab();
    expect(create).toHaveFocus();
    expect(table.table.keyboardNavigation!.position).toEqual(originalPosition);
    expect(table.selection.getSelectedWorkPackageIds()).toEqual(selection);
    expect(table.row('1')).toHaveAttribute('tabindex', '0');

    table.row('1').focus();
    await userEvent.tab();
    expect(idLink).toHaveFocus();
    await userEvent.tab();
    expect(details).toHaveFocus();
    await userEvent.tab();
    expect(menu).toHaveFocus();
    await userEvent.tab({ shift: true });
    expect(details).toHaveFocus();
    await userEvent.tab({ shift: true });
    expect(idLink).toHaveFocus();
    await userEvent.tab({ shift: true });
    expect(table.row('1')).toHaveFocus();
    await userEvent.tab({ shift: true });
    expect(before).toHaveFocus();
    before.remove();
  });

  it('walks only the origin cell and later cells without wrapping', async () => {
    const table = await mount();
    const cells = navigableCells(table.row('1'));
    const idLink = document.createElement('a');
    idLink.href = '#';
    const details = document.createElement('button');
    const menu = document.createElement('button');
    cells[0].append(idLink);
    cells[1].append(details, menu);
    const create = within(table.container).getByRole('button', { name: 'Create new work package' });
    table.table.keyboardNavigation!.focusPosition(positionOf(table, cells[1]));

    await userEvent.tab();
    expect(details).toHaveFocus();
    expect(idLink).not.toHaveFocus();
    await userEvent.tab();
    expect(menu).toHaveFocus();
    await userEvent.tab({ shift: true });
    expect(details).toHaveFocus();
    await userEvent.tab({ shift: true });
    expect(cells[1]).toHaveFocus();

    await userEvent.tab();
    expect(details).toHaveFocus();
    await userEvent.tab();
    expect(menu).toHaveFocus();
    await userEvent.tab();
    expect(create).toHaveFocus();
  });

  it('returns to the walk origin for Escape and navigation keys', async () => {
    const table = await mount();
    const cells = navigableCells(table.row('1'));
    const control = document.createElement('button');
    cells[0].append(control);
    table.table.keyboardNavigation!.focusPosition({ key: wpOccurrenceKey('1'), cell: null, desiredColumn: null });
    table.click('1');
    await userEvent.tab();
    expect(control).toHaveFocus();

    fireEvent.keyDown(control, { key: 'Escape' });

    expect(table.row('1')).toHaveFocus();
    expect(table.selection.getSelectedWorkPackageIds()).toEqual(['1']);

    await userEvent.tab();
    fireEvent.keyDown(control, { key: 'ArrowDown' });
    expect(table.row('2')).toHaveFocus();
  });

  it('parks an editor at the Tab boundary and re-engages the same instance', async () => {
    const table = await mount();
    const cell = navigableCells(table.row('1'))[1];
    table.table.keyboardNavigation!.focusPosition(positionOf(table, cell));
    fireEvent.keyDown(cell, { key: 'Enter' });
    await waitFor(() => expect(table.table.editing.forms['1'].activeFields.subject).toBeDefined());
    const handler = table.table.editing.forms['1'].activeFields.subject;
    const input = within(cell).getByRole<HTMLInputElement>('textbox');
    input.value = 'Parked draft';
    input.focus();

    await userEvent.tab();

    expect(cell).toHaveFocus();
    expect(input).toHaveAttribute('tabindex', '-1');
    expect(input).toHaveValue('Parked draft');
    expect(table.table.keyboardNavigation!.position).toEqual(positionOf(table, cell));

    await userEvent.tab();
    expect(within(table.container).getByRole('button', { name: 'Create new work package' })).toHaveFocus();
    cell.focus();
    fireEvent.keyDown(cell, { key: 'Enter' });

    expect(table.table.editing.forms['1'].activeFields.subject).toBe(handler);
    expect(within(cell).getByRole('textbox')).toBe(input);
    expect(input).toHaveFocus();
    expect(input).not.toHaveAttribute('tabindex', '-1');
    expect(input).toHaveValue('Parked draft');
  });

  it('parks on Shift+Tab from the first input inside the editor form', async () => {
    const table = await mount();
    const cell = navigableCells(table.row('1'))[1];
    table.table.keyboardNavigation!.focusPosition(positionOf(table, cell));
    fireEvent.keyDown(cell, { key: 'Enter' });
    await waitFor(() => expect(table.table.editing.forms['1'].activeFields.subject).toBeDefined());
    const input = within(cell).getByRole<HTMLInputElement>('textbox');
    expect(input.closest('form')).toHaveAttribute('tabindex', '-1');
    input.value = 'Parked draft';
    input.focus();

    await userEvent.tab({ shift: true });

    expect(cell).toHaveFocus();
    expect(input).toHaveAttribute('tabindex', '-1');
    expect(input).toHaveValue('Parked draft');
  });

  it('keeps inline-create editor Tab native during a grid repaint', async () => {
    const table = await mount();
    const row = table.addInlineCreateRow();
    const form = Object.values(table.table.editing.forms)[0];
    const handler = await form.activate('subject');
    handler!.focus();
    const input = within(row).getByRole('textbox');

    const rendered = table.nextRender();
    table.table.redrawTable();
    await rendered;
    await userEvent.tab();

    expect(input).not.toHaveAttribute('tabindex', '-1');
    expect(table.row('1')).toHaveAttribute('tabindex', '0');

    const overlay = document.body.appendChild(document.createElement('button'));
    handler!.registerOverlay(overlay);
    overlay.focus();
    expect(fireEvent.keyDown(overlay, { key: 'Tab' })).toBe(true);
    expect(input).not.toHaveAttribute('tabindex', '-1');
    overlay.remove();
  });

  it('does not land in an editor opened in a later row during native exit', async () => {
    const table = await mount({ workPackages: [{ id: '1' }, { id: '2' }, { id: '3' }] });
    const editorCell = navigableCells(table.row('3'))[1];
    table.table.keyboardNavigation!.focusPosition(positionOf(table, editorCell));
    fireEvent.keyDown(editorCell, { key: 'Enter' });
    await waitFor(() => expect(table.table.editing.forms['3'].activeFields.subject).toBeDefined());
    const input = within(editorCell).getByRole('textbox');
    const cells = navigableCells(table.row('1'));
    const control = document.createElement('button');
    cells[0].append(control);
    const create = within(table.container).getByRole('button', { name: 'Create new work package' });
    table.table.keyboardNavigation!.focusPosition({ key: wpOccurrenceKey('1'), cell: null, desiredColumn: null });

    await userEvent.tab();
    expect(control).toHaveFocus();
    await userEvent.tab();

    expect(create).toHaveFocus();
    expect(input).not.toHaveFocus();
  });

  it('leaves natively from empty group-header and totals walks', async () => {
    const table = await mount({
      workPackages: [{ id: '1', attributes: { status: { href: '/api/v3/statuses/1' } } }],
      groups: [{ value: 'New', href: '/api/v3/statuses/1', count: 1 }],
    });
    const group = table.groupHeader(0);
    table.table.keyboardNavigation!.focusPosition(positionOf(table, group));

    await userEvent.tab();

    expect(insideGrid(table.table.scrollContainer, document.activeElement)).toBe(false);
    const totals = navigableCells(table.totalsRow())[0];
    table.table.keyboardNavigation!.focusPosition(positionOf(table, totals));
    await userEvent.tab();
    expect(insideGrid(table.table.scrollContainer, document.activeElement)).toBe(false);
  });

  it('re-engages a parked invalid field before validation focus', async () => {
    const table = await mount();
    const cell = navigableCells(table.row('1'))[1];
    table.table.keyboardNavigation!.focusPosition(positionOf(table, cell));
    fireEvent.keyDown(cell, { key: 'Enter' });
    await waitFor(() => expect(table.table.editing.forms['1'].activeFields.subject).toBeDefined());
    const form = table.table.editing.forms['1'];
    const handler = form.activeFields.subject;
    const input = within(cell).getByRole<HTMLInputElement>('textbox');
    input.focus();
    await userEvent.tab();
    expect(cell).toHaveFocus();
    handler.setErrors(['Required']);

    (form as unknown as { focusOnFirstError():void }).focusOnFirstError();

    expect(input).toHaveFocus();
    expect(input).not.toHaveAttribute('tabindex', '-1');
    await userEvent.tab();
    expect(cell).toHaveFocus();
  });

  it.each([false, true])('leaves Tab native inside an owned overlay (shift: %s)', async (shiftKey) => {
    const table = await mount();
    const cell = navigableCells(table.row('1'))[1];
    table.table.keyboardNavigation!.focusPosition(positionOf(table, cell));
    fireEvent.keyDown(cell, { key: 'Enter' });
    await waitFor(() => expect(table.table.editing.forms['1'].activeFields.subject).toBeDefined());
    const handler = table.table.editing.forms['1'].activeFields.subject;
    const overlay = document.body.appendChild(document.createElement('div'));
    const first = overlay.appendChild(document.createElement('button'));
    const last = overlay.appendChild(document.createElement('button'));
    handler.registerOverlay(overlay);
    const boundary = shiftKey ? first : last;
    boundary.focus();

    expect(fireEvent.keyDown(boundary, { key: 'Tab', shiftKey })).toBe(true);

    expect(boundary).toHaveFocus();
    expect(first).not.toHaveAttribute('tabindex');
    expect(within(cell).getByRole('textbox')).not.toHaveAttribute('tabindex', '-1');
    overlay.remove();
  });

  it('does not move inline-create focus into the grid on a full render', async () => {
    const table = await mount();
    const remembered = navigableCells(table.row('1'))[1];
    table.table.keyboardNavigation!.focusPosition(positionOf(table, remembered));
    const row = table.addInlineCreateRow();
    const form = Object.values(table.table.editing.forms)[0];
    const handler = await form.activate('subject');
    handler!.focus();
    await waitFor(() => expect(within(row).getByRole('textbox')).toHaveFocus());

    await table.render();

    expect(navigableCells(table.row('1'))[1]).not.toHaveFocus();
  });

  it('restores the cell of a parked editor after a full render', async () => {
    const table = await mount();
    const cell = navigableCells(table.row('2'))[1];
    table.table.keyboardNavigation!.focusPosition(positionOf(table, cell));
    fireEvent.keyDown(cell, { key: 'Enter' });
    await waitFor(() => expect(within(cell).getByRole('textbox')).toHaveFocus());
    await userEvent.tab();
    expect(cell).toHaveFocus();

    await table.render([{ id: '2' }, { id: '1' }]);

    expect(navigableCells(table.row('2'))[1]).toHaveFocus();
  });

  it('parks an engaged editor when a pointer moves focus to another cell', async () => {
    const table = await mount();
    const editorCell = navigableCells(table.row('2'))[1];
    table.table.keyboardNavigation!.focusPosition(positionOf(table, editorCell));
    fireEvent.keyDown(editorCell, { key: 'Enter' });
    const input = await waitFor(() => within(editorCell).getByRole<HTMLInputElement>('textbox'));
    await waitFor(() => expect(input).toHaveFocus());
    const otherCell = navigableCells(table.row('1'))[1];
    fireEvent.mouseDown(otherCell, { button: 0 });
    otherCell.focus();
    fireEvent.mouseUp(otherCell, { button: 0 });
    expect(otherCell).toHaveFocus();
    const create = within(table.container).getByRole('button', { name: 'Create new work package' });
    create.focus();

    await userEvent.tab({ shift: true });

    expect(input).not.toHaveFocus();
    expect(input).toHaveAttribute('tabindex', '-1');
  });

  it('parks an engaged editor when focus leaves the table for an outside control', async () => {
    const table = await mount();
    const editorCell = navigableCells(table.row('1'))[1];
    table.table.keyboardNavigation!.focusPosition(positionOf(table, editorCell));
    fireEvent.keyDown(editorCell, { key: 'Enter' });
    const input = await waitFor(() => within(editorCell).getByRole<HTMLInputElement>('textbox'));
    await waitFor(() => expect(input).toHaveFocus());
    const outside = document.body.appendChild(document.createElement('button'));

    outside.focus();

    expect(outside).toHaveFocus();
    expect(input).toHaveAttribute('tabindex', '-1');
    outside.remove();
  });

  it('returns Escape to the cell of an editor re-engaged after a pointer opened another', async () => {
    const table = await mount();
    const cellA = navigableCells(table.row('1'))[1];
    table.table.keyboardNavigation!.focusPosition(positionOf(table, cellA));
    fireEvent.keyDown(cellA, { key: 'Enter' });
    const inputA = await waitFor(() => within(cellA).getByRole<HTMLInputElement>('textbox'));
    await waitFor(() => expect(inputA).toHaveFocus());
    const handlerA = table.table.editing.forms['1'].activeFields.subject;
    const cellB = navigableCells(table.row('2'))[1];
    fireEvent.mouseDown(cellB, { button: 0 });
    cellB.focus();
    fireEvent.mouseUp(cellB, { button: 0 });
    const editableB = cellB.querySelector<HTMLElement>('.inline-edit--display-field')!;
    activateTableField(table.table, editableB);
    const inputB = await waitFor(() => within(cellB).getByRole<HTMLInputElement>('textbox'));
    inputB.focus();
    fireEvent.mouseDown(inputA, { button: 0 });
    inputA.focus();
    fireEvent.mouseUp(inputA, { button: 0 });
    expect(inputA).toHaveFocus();

    handlerA.handleUserCancel();

    expect(navigableCells(table.row('1'))[1]).toHaveFocus();
  });

  it.each(['Enter', 'pointer'])('returns Escape to the cell of a programmatically opened field entered by %s', async (entry) => {
    const table = await mount({ columns: ['id', 'subject', 'status'], editing: { fields: ['subject', 'status'] } });
    const cellA = navigableCells(table.row('1'))[1];
    table.table.keyboardNavigation!.focusPosition(positionOf(table, cellA));
    fireEvent.keyDown(cellA, { key: 'Enter' });
    const inputA = await waitFor(() => within(cellA).getByRole<HTMLInputElement>('textbox'));
    await waitFor(() => expect(inputA).toHaveFocus());
    const form = table.table.editing.forms['1'];
    const handlerC = (await form.activate('status'))!;
    const cellC = navigableCells(table.row('1'))[2];
    const inputC = within(cellC).getByRole<HTMLInputElement>('textbox');
    await userEvent.tab();
    expect(cellA).toHaveFocus();
    expect(inputC).toHaveAttribute('tabindex', '-1');

    if (entry === 'Enter') {
      fireEvent.keyDown(cellA, { key: 'ArrowRight' });
      fireEvent.keyDown(cellC, { key: 'Enter' });
    } else {
      fireEvent.mouseDown(inputC, { button: 0 });
      inputC.focus();
      fireEvent.mouseUp(inputC, { button: 0 });
    }
    expect(inputC).toHaveFocus();

    handlerC.handleUserCancel();

    expect(navigableCells(table.row('1'))[2]).toHaveFocus();
  });

  it('walks the production controls of a row in order and skips the non-controls', async () => {
    const table = await mount({
      workPackages: [
        { id: '1', children: [{ id: '2' }] },
        { id: '2', ancestors: [{ id: '1' }] },
        { id: '3' },
      ],
      columns: ['id', 'subject', { id: 'relationsOfTypeFollows', relationType: 'follows' }],
      relations: [{ from: '1', to: '3', type: 'follows', reverseType: 'precedes' }],
      showHierarchies: true,
      configuration: { actionsColumnEnabled: true, contextMenuEnabled: true, dragAndDropEnabled: true },
    });
    const parent = table.row('1');
    const idLink = parent.querySelector(':scope > .wp-table--cell-td.id .inline-edit--container')!.appendChild(document.createElement('a'));
    idLink.href = '/work_packages/1';
    idLink.textContent = '#1';
    const trigger = parent.querySelector(':scope > .wp-table--cell-td.subject .inline-edit--container')!.appendChild(document.createElement('a'));
    trigger.href = '#';
    trigger.className = 'inline-edit--display-trigger';
    const toggle = within(parent).getByRole('button', { name: /children_expanded/ });
    const expander = within(parent).getByRole('button', { name: 'js.work_packages.table.relations_button' });
    const menu = within(parent).getByRole('link', { name: 'js.label_open_context_menu' });
    expect(parent.querySelector('.wp-table--drag-and-drop-handle')).not.toBeNull();

    expect(rowControls(parent, table.table)).toEqual([idLink, toggle, expander, menu]);

    const child = table.row('2');
    expect(child.querySelector('.wp-table--leaf-indicator')).not.toBeNull();
    expect(child.querySelector('td.relationsOfTypeFollows button')).toBeNull();
    expect(rowControls(child, table.table)).toEqual([within(child).getByRole('link', { name: 'js.label_open_context_menu' })]);

    table.table.keyboardNavigation!.focusPosition({ key: wpOccurrenceKey('1'), cell: null, desiredColumn: null });
    await userEvent.tab();
    expect(idLink).toHaveFocus();
    await userEvent.tab();
    expect(toggle).toHaveFocus();
    await userEvent.tab();
    expect(expander).toHaveFocus();
    await userEvent.tab();
    expect(menu).toHaveFocus();
    await userEvent.tab();
    expect(insideGrid(table.table.scrollContainer, document.activeElement)).toBe(false);
  });

  it('leaves selection chords inert on a walked control', async () => {
    const table = await mount();
    const cell = navigableCells(table.row('1'))[0];
    const control = cell.appendChild(document.createElement('button'));
    cell.appendChild(document.createElement('button'));
    table.table.keyboardNavigation!.focusPosition(positionOf(table, cell));
    fireEvent.keyDown(cell, { key: 'Enter' });
    expect(control).toHaveFocus();
    const selection = table.selection.getSelectedWorkPackageIds();

    expect(fireEvent.keyDown(control, { key: ' ', shiftKey: true })).toBe(true);
    expect(fireEvent.keyDown(control, { key: 'a', ctrlKey: true })).toBe(true);
    expect(fireEvent.keyDown(control, { key: 'a', metaKey: true })).toBe(true);

    expect(control).toHaveFocus();
    expect(table.selection.getSelectedWorkPackageIds()).toEqual(selection);
  });

  it('restores an explicit tabindex when a parked editor is re-engaged', async () => {
    const table = await mount();
    const cell = navigableCells(table.row('1'))[1];
    table.table.keyboardNavigation!.focusPosition(positionOf(table, cell));
    fireEvent.keyDown(cell, { key: 'Enter' });
    await waitFor(() => expect(table.table.editing.forms['1'].activeFields.subject).toBeDefined());
    const input = within(cell).getByRole<HTMLInputElement>('textbox');
    const extra = input.closest('form')!.appendChild(document.createElement('button'));
    extra.setAttribute('tabindex', '0');
    extra.focus();

    await userEvent.tab();
    expect(cell).toHaveFocus();
    expect(extra).toHaveAttribute('tabindex', '-1');

    fireEvent.keyDown(cell, { key: 'Enter' });

    expect(extra).toHaveAttribute('tabindex', '0');
    expect(extra).not.toHaveAttribute('data-op-original-tabindex');
  });

  it('focuses the input of a parked editor whose field host is not focusable', async () => {
    const table = await mount();
    const cell = navigableCells(table.row('1'))[1];
    table.table.keyboardNavigation!.focusPosition(positionOf(table, cell));
    fireEvent.keyDown(cell, { key: 'Enter' });
    await waitFor(() => expect(table.table.editing.forms['1'].activeFields.subject).toBeDefined());
    const input = within(cell).getByRole<HTMLInputElement>('textbox');
    const host = document.createElement('div');
    host.className = input.className;
    input.className = '';
    input.replaceWith(host);
    host.append(input);
    input.focus();

    await userEvent.tab({ shift: true });
    expect(cell).toHaveFocus();

    fireEvent.keyDown(cell, { key: 'Enter' });

    expect(input).toHaveFocus();
  });

  it('focuses the input of a parked invalid field whose host is not focusable', async () => {
    const table = await mount();
    const cell = navigableCells(table.row('1'))[1];
    table.table.keyboardNavigation!.focusPosition(positionOf(table, cell));
    fireEvent.keyDown(cell, { key: 'Enter' });
    await waitFor(() => expect(table.table.editing.forms['1'].activeFields.subject).toBeDefined());
    const form = table.table.editing.forms['1'];
    const input = within(cell).getByRole<HTMLInputElement>('textbox');
    const host = document.createElement('div');
    host.className = input.className;
    input.className = '';
    input.replaceWith(host);
    host.append(input);
    input.focus();
    await userEvent.tab({ shift: true });
    expect(cell).toHaveFocus();
    form.activeFields.subject.setErrors(['Required']);

    (form as unknown as { focusOnFirstError():void }).focusOnFirstError();

    expect(input).toHaveFocus();
    expect(input).not.toHaveAttribute('tabindex', '-1');
  });

  it('restores a control that was disabled while its editor was parked', async () => {
    const table = await mount();
    const cell = navigableCells(table.row('1'))[1];
    table.table.keyboardNavigation!.focusPosition(positionOf(table, cell));
    fireEvent.keyDown(cell, { key: 'Enter' });
    await waitFor(() => expect(table.table.editing.forms['1'].activeFields.subject).toBeDefined());
    const input = within(cell).getByRole<HTMLInputElement>('textbox');
    const save = input.closest('form')!.appendChild(document.createElement('button'));
    save.disabled = true;
    input.focus();

    await userEvent.tab();
    expect(cell).toHaveFocus();
    fireEvent.keyDown(cell, { key: 'ArrowLeft' });
    fireEvent.keyDown(document.activeElement!, { key: 'ArrowRight' });
    expect(cell).toHaveFocus();
    fireEvent.keyDown(cell, { key: 'Enter' });
    save.disabled = false;

    expect(save).not.toHaveAttribute('tabindex');
  });

  it('keeps the origin of a walk started on a pointer-focused control', async () => {
    const table = await mount();
    const [first, second] = navigableCells(table.row('1'));
    const firstControl = first.appendChild(document.createElement('button'));
    const secondControl = second.appendChild(document.createElement('button'));
    fireEvent.mouseDown(firstControl, { button: 0 });
    firstControl.focus();
    fireEvent.mouseUp(firstControl, { button: 0 });

    fireEvent.keyDown(firstControl, { key: 'Tab' });
    expect(secondControl).toHaveFocus();
    fireEvent.keyDown(secondControl, { key: 'Tab', shiftKey: true });
    expect(firstControl).toHaveFocus();
    fireEvent.keyDown(firstControl, { key: 'Tab' });
    fireEvent.keyDown(secondControl, { key: 'Escape' });

    expect(first).toHaveFocus();
  });

  it('keeps a walk through a refresh that retains its focused control', async () => {
    const table = await mount({ configuration: { actionsColumnEnabled: true } });
    const cell = navigableCells(table.row('1')).at(-1)!;
    cell.append(document.createElement('button'), document.createElement('button'));
    table.table.keyboardNavigation!.focusPosition(positionOf(table, cell));
    fireEvent.keyDown(cell, { key: 'Enter' });
    const control = document.activeElement as HTMLElement;
    expect(cell).toContainElement(control);

    table.table.refreshRows(table.injector.get(States).workPackages.get('1').value!);
    expect(control).toHaveFocus();
    fireEvent.keyDown(control, { key: 'Escape' });

    expect(cell).toHaveFocus();
  });

  it('leaves Shift+Arrow inert on a walked control', async () => {
    const table = await mount();
    const cell = navigableCells(table.row('1'))[0];
    const first = cell.appendChild(document.createElement('button'));
    cell.appendChild(document.createElement('button'));
    table.table.keyboardNavigation!.focusPosition(positionOf(table, cell));
    fireEvent.keyDown(cell, { key: 'Enter' });
    expect(first).toHaveFocus();

    expect(fireEvent.keyDown(first, { key: 'ArrowDown', shiftKey: true })).toBe(true);

    expect(first).toHaveFocus();
    expect(table.selection.getSelectedWorkPackageIds()).toEqual([]);
  });

  it('uses the occurrence key when recording re-entry origin', async () => {
    const table = await mount();
    const cell = navigableCells(table.row('1'))[1];
    table.table.keyboardNavigation!.focusPosition(positionOf(table, cell));
    fireEvent.keyDown(cell, { key: 'Enter' });
    await waitFor(() => expect(table.table.editing.forms['1'].activeFields.subject).toBeDefined());
    table.table.keyboardNavigation!.focusPosition(positionOf(table, cell));
    table.table.keyboardNavigation!.recordPosition({ key: wpOccurrenceKey('2'), cell: 1, desiredColumn: 1 });
    const outside = document.body.appendChild(document.createElement('button'));
    outside.focus();
    cell.focus();

    fireEvent.keyDown(cell, { key: 'Enter' });
    outside.remove();

    expect(table.table.keyboardNavigation!.position).toEqual(positionOf(table, cell));
  });
});

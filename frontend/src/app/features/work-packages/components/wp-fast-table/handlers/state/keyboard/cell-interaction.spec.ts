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
import { navigableCells } from './roving-tabindex';
import { cellTargets } from './cell-interaction';

describe('CellInteraction', () => {
  const harnesses:TableHarness[] = [];

  const mount = async (options:Partial<TableHarnessOptions> = {}) => {
    const table = buildTable({
      workPackages: [{ id: '1' }, { id: '2' }],
      editing: {},
      productionMarkup: true,
      ...options,
      configuration: { keyboardNavigationEnabled: true, ...options.configuration },
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

  it('applies P2 from an owned body-portaled overlay', async () => {
    const table = await mount();
    const cell = navigableCells(table.row('1'))[1];
    table.table.keyboardNavigation!.focusPosition(positionOf(table, cell));
    fireEvent.keyDown(cell, { key: 'Enter' });
    await waitFor(() => expect(table.table.editing.forms['1'].activeFields.subject).toBeDefined());
    const handler = table.table.editing.forms['1'].activeFields.subject;
    const overlay = document.body.appendChild(document.createElement('button'));
    overlay.textContent = 'Close editor';
    overlay.style.width = '100px';
    overlay.style.height = '20px';
    handler.registerOverlay(overlay);
    overlay.focus();
    expect(overlay.checkVisibility()).toBe(true);

    fireEvent.keyDown(overlay, { key: 'Tab' });

    expect(cell).toHaveFocus();
    expect(within(cell).getByRole('textbox')).toHaveAttribute('tabindex', '-1');
    overlay.remove();
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

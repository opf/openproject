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
import { HttpErrorResponse } from '@angular/common/http';
import { HalError } from 'core-app/features/hal/services/hal-error';
import { ErrorResource } from 'core-app/features/hal/resources/error-resource';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { States } from 'core-app/core/states/states.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { WorkPackageViewRelationColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-relation-columns.service';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import {
  buildQuery, buildTable, TableHarness, TableHarnessOptions,
} from './testing/table-harness';
import { navigableCells } from './handlers/state/keyboard/roving-tabindex';
import { buildGroup } from './testing/work-package-fixture';
import { wpOccurrenceKey } from './rendered-occurrence-ledger';

describe('Retaining table editors across renders', () => {
  const harnesses:TableHarness[] = [];

  const mount = async (options:Partial<TableHarnessOptions> = {}) => {
    const table = buildTable({
      workPackages: [{ id: '1' }, { id: '2' }],
      columns: ['id', 'subject', 'priority'],
      editing: { fields: ['subject', 'priority'], types: { priority: 'Priority' } },
      productionMarkup: true,
      ...options,
      configuration: { inlineCreateEnabled: true, ...options.configuration },
    });
    harnesses.push(table);
    await table.render();
    return table;
  };

  const openEditorIn = async (table:TableHarness, row:HTMLTableRowElement, fieldName:string, cellIndex:number) => {
    const workPackageId = row.dataset.workPackageId!;
    const cell = navigableCells(row)[cellIndex];
    table.table.keyboardNavigation.focusPosition(table.table.keyboardNavigation.positionOfCell(cell)!);
    fireEvent.keyDown(cell, { key: 'Enter' });
    await waitFor(() => expect(table.table.editing.forms[workPackageId]?.activeFields[fieldName]).toBeDefined());
    return cell;
  };

  const openEditor = (table:TableHarness, workPackageId:string, fieldName:string, cellIndex:number) =>
    openEditorIn(table, table.row(workPackageId), fieldName, cellIndex);

  afterEach(async () => {
    await Promise.all(harnesses.splice(0).map((table) => table.destroy()));
  });

  describe('deciding what a render retains', () => {
    it('keeps a text editor inside its cell', async () => {
      const table = await mount();
      const cell = await openEditor(table, '1', 'subject', 1);

      table.table.editing.closeUnretainedFields();

      expect(table.table.editing.forms['1'].activeFields.subject).toBeDefined();
      expect(within(cell).getByRole('textbox')).toBeInTheDocument();
    });

    it('closes an editor of a type that does not survive renders', async () => {
      const table = await mount();
      const cell = await openEditor(table, '1', 'priority', 2);

      table.table.editing.closeUnretainedFields();

      expect(table.table.editing.forms['1']).toBeUndefined();
      expect(within(cell).queryByRole('textbox')).not.toBeInTheDocument();
    });

    it('closes a surviving type that registered an overlay', async () => {
      const table = await mount();
      const cell = await openEditor(table, '1', 'subject', 1);
      const overlay = document.body.appendChild(document.createElement('div'));
      onTestFinished(() => overlay.remove());
      table.table.editing.forms['1'].activeFields.subject.registerOverlay(overlay);

      table.table.editing.closeUnretainedFields();

      expect(table.table.editing.forms['1']).toBeUndefined();
      expect(within(cell).queryByRole('textbox')).not.toBeInTheDocument();
    });

    it('closes the inline-create editor', async () => {
      const table = await mount();
      const row = table.addInlineCreateRow();
      const form = Object.values(table.table.editing.forms)[0];
      await form.activate('subject');
      expect(within(row).getByRole('textbox')).toBeInTheDocument();

      table.table.editing.closeUnretainedFields();

      expect(table.table.editing.forms).toEqual({});
      expect(within(row).queryByRole('textbox')).not.toBeInTheDocument();
    });

    it('lets an activation in flight continue after its empty form is retired', async () => {
      const table = await mount();
      const row = table.row('1');
      const workPackage = table.table.states.workPackages.get('1').value!;
      const form = table.table.editing.startEditing(workPackage, row.dataset.classIdentifier!);
      const activation = form.activate('subject');

      table.table.editing.closeUnretainedFields();
      await activation;

      expect(form.activeFields.subject).toBeDefined();
      expect(table.table.editing.forms['1']).toBe(form);
      expect(within(row).getByRole('textbox')).toBeInTheDocument();
    });

    it('keeps a form with one retained field and closes its other field', async () => {
      const table = await mount();
      const subjectCell = await openEditor(table, '1', 'subject', 1);
      const form = table.table.editing.forms['1'];
      await form.activate('priority');
      const priorityCell = navigableCells(table.row('1'))[2];
      expect(within(priorityCell).getByRole('textbox')).toBeInTheDocument();

      table.table.editing.closeUnretainedFields();

      expect(table.table.editing.forms['1']).toBe(form);
      expect(Object.keys(form.activeFields)).toEqual(['subject']);
      expect(within(subjectCell).getByRole('textbox')).toBeInTheDocument();
      expect(within(priorityCell).queryByRole('textbox')).not.toBeInTheDocument();
    });
  });

  const newStatus = { href: '/api/v3/statuses/1' };
  const inProgressStatus = { href: '/api/v3/statuses/2' };
  const groups = [
    { value: 'New', href: newStatus.href, count: 2 },
    { value: 'In progress', href: inProgressStatus.href, count: 1 },
  ];
  const groupedWorkPackages = [
    { id: '1', attributes: { status: newStatus } },
    { id: '2', attributes: { status: newStatus } },
    { id: '3', attributes: { status: inProgressStatus } },
  ];

  const resource = (table:TableHarness, id:string) => table.injector.get(States).workPackages.get(id).value!;

  const subjectCell = (row:HTMLTableRowElement) => row.querySelector<HTMLTableCellElement>('.wp-table--cell-td.subject')!;

  const textbox = (table:TableHarness, workPackageId = '1') => within(subjectCell(table.row(workPackageId))).getByRole<HTMLInputElement>('textbox');

  const redraw = async (table:TableHarness) => {
    const rendered = table.nextRender();
    table.table.redrawTable();
    await rendered;
  };

  const holdDrafts = (table:TableHarness) => {
    const editing = table.injector.get(HalResourceEditingService);
    const stub = editing.changeFor.bind(editing);
    const values = new Map<string, Map<string, unknown>>();
    const changes = new Map<string, ReturnType<typeof stub>>();
    const changeOf = (workPackage:WorkPackageResource) => {
      const id = workPackage.id!;
      const existing = changes.get(id);
      if (existing) return existing;
      const drafts = values.get(id) ?? new Map<string, unknown>();
      values.set(id, drafts);
      const change = Object.defineProperties(stub(workPackage), {
        schema: { value: table.injector.get(SchemaCacheService).of(workPackage) },
        setValue: { value: (key:string, value:unknown) => { drafts.set(key, value); } },
        value: { value: (key:string) => drafts.get(key) },
        contains: { value: (key:string) => drafts.has(key) },
        reset: { value: (key:string) => { drafts.delete(key); } },
        isEmpty: { value: () => drafts.size === 0 },
        changedAttributes: { get: () => Array.from(drafts.keys()) },
      });
      changes.set(id, change);
      return change;
    };
    vi.spyOn(editing, 'changeFor').mockImplementation(changeOf);
    vi.spyOn(editing, 'typedState').mockImplementation(((workPackage:WorkPackageResource) => {
      const change = changes.get(workPackage.id!);
      return { hasValue: () => !!change, value: change };
    }) as unknown as typeof editing.typedState);

    return {
      set: (workPackageId:string, attribute:string, value:unknown) => changeOf(resource(table, workPackageId)).setValue(attribute, value),
      value: (workPackageId:string, attribute:string) => table.table.editing.change(resource(table, workPackageId))?.value(attribute),
    };
  };

  const bindDraft = (drafts:ReturnType<typeof holdDrafts>, input:HTMLInputElement, workPackageId = '1') => {
    input.addEventListener('input', () => drafts.set(workPackageId, 'subject', input.value));
  };

  const tabStops = (table:TableHarness) => Array.from(table.table.scrollContainer.querySelectorAll('[tabindex="0"]'));

  const deferred = <T>() => {
    let resolve!:(value:T) => void;
    let reject!:(error:unknown) => void;
    const promise = new Promise<T>((yes, no) => { resolve = yes; reject = no; });
    return { promise, resolve, reject };
  };

  const validationError = (table:TableHarness, attribute:string) => {
    const errorResource = new ErrorResource(table.injector, {}, true, () => undefined, 'Error');
    vi.spyOn(errorResource, 'getInvolvedAttributes').mockReturnValue([attribute]);
    vi.spyOn(errorResource, 'getMessagesPerAttribute').mockReturnValue({ [attribute]: [`${attribute} is invalid`] });
    return new HalError(new HttpErrorResponse({ status: 422 }), errorResource);
  };

  describe('retaining editors across a render', () => {
    it('decides to keep an editor without creating a changeset', async () => {
      const table = await mount();
      await openEditor(table, '1', 'subject', 1);
      holdDrafts(table);
      const form = table.table.editing.forms['1'];
      expect(table.table.editing.change(form.resource)).toBeUndefined();

      table.table.editing.closeUnretainedFields();

      expect(form.activeFields.subject).toBeDefined();
      expect(table.table.editing.change(form.resource)).toBeUndefined();
    });

    it.each(['forward', 'backward'] as const)('keeps the editor, its draft, focus and selection (%s)', async (direction) => {
      const table = await mount();
      const drafts = holdDrafts(table);
      await openEditor(table, '1', 'subject', 1);
      const row = table.row('1');
      const cell = subjectCell(row);
      const input = textbox(table);
      await waitFor(() => expect(input).toHaveFocus());
      input.value = 'Draft subject';
      drafts.set('1', 'subject', 'Draft subject');
      input.setSelectionRange(1, 3, direction);

      await redraw(table);

      expect(table.row('1')).not.toBe(row);
      expect(subjectCell(table.row('1'))).not.toBe(cell);
      expect(textbox(table)).toBe(input);
      expect(input).toHaveFocus();
      expect(input).toHaveValue('Draft subject');
      expect([input.selectionStart, input.selectionEnd, input.selectionDirection]).toEqual([1, 3, direction]);
      expect(drafts.value('1', 'subject')).toBe('Draft subject');
      expect(table.table.editing.forms['1'].activeFields.subject).toBeDefined();
    });

    it('keeps the width its cell was locked to at activation', async () => {
      const table = await mount({
        workPackages: [{ id: '1', attributes: { description: 'A text long enough to give its column a width of its own' } }, { id: '2' }],
        columns: ['id', 'subject', 'description'],
        editing: { fields: ['subject', 'description'] },
      });
      await openEditor(table, '1', 'description', 2);
      const cell = () => table.row('1').querySelector<HTMLTableCellElement>('.wp-table--cell-td.description')!;
      await waitFor(() => expect(within(cell()).getByRole('textbox')).toHaveFocus());
      const locked = cell().style.width;
      expect(locked).toMatch(/px$/);

      await redraw(table);

      expect(cell().style.width).toBe(locked);
    });

    it('keeps text typed while the render waits for its frame', async () => {
      const table = await mount();
      const drafts = holdDrafts(table);
      await openEditor(table, '1', 'subject', 1);
      const input = textbox(table);
      await waitFor(() => expect(input).toHaveFocus());
      bindDraft(drafts, input);
      const frames = table.holdFrames();
      try {
        table.table.redrawTable();
        await userEvent.keyboard('Typed');
        frames.commit();
      } finally {
        frames.release();
      }

      expect(textbox(table)).toBe(input);
      expect(input).toHaveValue('Typed');
      expect(drafts.value('1', 'subject')).toBe('Typed');
      expect(input).toHaveFocus();
    });

    it('does not submit, park or close when the host moves', async () => {
      const table = await mount();
      await openEditor(table, '1', 'subject', 1);
      const form = table.table.editing.forms['1'];
      const handler = form.activeFields.subject;
      const input = textbox(table);
      await waitFor(() => expect(input).toHaveFocus());
      const submit = vi.spyOn(form, 'submit');
      const deactivate = vi.spyOn(handler, 'deactivate');

      await redraw(table);

      expect(submit).not.toHaveBeenCalled();
      expect(deactivate).not.toHaveBeenCalled();
      expect(table.table.keyboardNavigation.retainsFocus).toBe(true);
      expect(form.activeFields.subject).toBe(handler);
      expect(input).not.toHaveAttribute('data-op-original-tabindex');
      expect(input).not.toHaveAttribute('tabindex', '-1');
      expect(input).toHaveFocus();
    });

    it('retains the editor once across two renders in one frame', async () => {
      const table = await mount();
      await openEditor(table, '1', 'subject', 1);
      const input = textbox(table);
      await waitFor(() => expect(input).toHaveFocus());
      const frames = table.holdFrames();
      try {
        table.table.redrawTable();
        table.table.redrawTable();
        frames.commit();
      } finally {
        frames.release();
      }

      expect(within(subjectCell(table.row('1'))).getAllByRole('textbox')).toEqual([input]);
      expect(input).toHaveFocus();
      await userEvent.keyboard('Still typing');
      expect(input).toHaveValue('Still typing');
      expect(table.table.editing.forms['1'].activeFields.subject).toBeDefined();
    });

    it('retains the editor once across a pending render rebuilt by a group collapse', async () => {
      const table = await mount({ workPackages: groupedWorkPackages, groups });
      await openEditor(table, '1', 'subject', 1);
      const input = textbox(table);
      await waitFor(() => expect(input).toHaveFocus());
      const frames = table.holdFrames();
      try {
        table.table.redrawTable();
        fireEvent.click(table.groupHeader(1).querySelector('.expander')!);
        frames.commit();
      } finally {
        frames.release();
      }

      expect(table.row('3')).not.toBeVisible();
      expect(within(subjectCell(table.row('1'))).getAllByRole('textbox')).toEqual([input]);
      expect(input).toHaveFocus();
      await userEvent.keyboard('Still typing');
      expect(input).toHaveValue('Still typing');
    });

    it('leaves focus on a control outside the table', async () => {
      const table = await mount();
      await openEditor(table, '1', 'subject', 1);
      const input = textbox(table);
      await waitFor(() => expect(input).toHaveFocus());
      const outside = document.body.appendChild(document.createElement('button'));
      onTestFinished(() => outside.remove());
      outside.focus();

      await redraw(table);

      expect(outside).toHaveFocus();
      expect(textbox(table)).toBe(input);
      expect(table.table.editing.forms['1'].activeFields.subject).toBeDefined();
    });
  });

  describe('following the editor to its new cell', () => {
    const subjectMoved = ['id', 'priority', 'subject'];

    const moveSubjectColumn = async (table:TableHarness) => {
      const rendered = table.nextRender();
      table.setColumns(subjectMoved);
      await rendered;
    };

    const openAndMove = async () => {
      const table = await mount();
      await openEditor(table, '1', 'subject', 1);
      const input = textbox(table);
      await waitFor(() => expect(input).toHaveFocus());
      await moveSubjectColumn(table);
      expect(textbox(table)).toBe(input);
      return { table, input, cell: navigableCells(table.row('1'))[2] };
    };

    it('follows the column when it moves', async () => {
      const { table, cell } = await openAndMove();
      const origin = { key: wpOccurrenceKey('1'), cell: 2, desiredColumn: 2 };

      expect(subjectCell(table.row('1'))).toBe(cell);
      expect(table.table.keyboardNavigation.position).toEqual(origin);
      expect(table.table.editing.forms['1'].originFor('subject')).toEqual(origin);
    });

    it('moves only the cursor when the user has since moved elsewhere', async () => {
      const table = await mount();
      const navigation = table.table.keyboardNavigation;
      await openEditor(table, '1', 'subject', 1);
      const input = textbox(table);
      await waitFor(() => expect(input).toHaveFocus());
      const handler = table.table.editing.forms['1'].activeFields.subject;
      fireEvent.keyDown(input, { key: 'Tab' });
      const parkedCell = subjectCell(table.row('1'));
      expect(parkedCell).toHaveFocus();
      fireEvent.keyDown(parkedCell, { key: 'ArrowDown' });
      expect(subjectCell(table.row('2'))).toHaveFocus();
      navigation.focusPosition(navigation.positionOfCell(parkedCell)!);

      await moveSubjectColumn(table);

      const cell = subjectCell(table.row('1'));
      expect(navigation.position).toEqual({ key: wpOccurrenceKey('1'), cell: 2, desiredColumn: 2 });
      expect(cell).toHaveFocus();
      cell.blur();
      await handler.handleUserSubmit();
      expect(table.table.editing.forms['1']?.activeFields.subject).toBeUndefined();
      expect(cell).not.toHaveFocus();
    });

    it('focuses the cell at the new index on Escape and makes it the only Tab stop', async () => {
      const { table, input, cell } = await openAndMove();

      fireEvent.keyDown(input, { key: 'Escape' });

      await waitFor(() => expect(cell).toHaveFocus());
      expect(tabStops(table)).toEqual([cell]);
      expect(table.table.editing.forms['1']?.activeFields.subject).toBeUndefined();
    });

    it.each([false, true])('parks to the cell at the new index on Tab (shift: %s)', async (shiftKey) => {
      const { table, input, cell } = await openAndMove();

      fireEvent.keyDown(input, { key: 'Tab', shiftKey });

      expect(cell).toHaveFocus();
      expect(table.table.editing.forms['1'].activeFields.subject).toBeDefined();
    });

    it('returns focus to the cell at the new index after a successful submit', async () => {
      const { table, cell } = await openAndMove();
      const handler = table.table.editing.forms['1'].activeFields.subject;

      await handler.handleUserSubmit();

      expect(cell).toHaveFocus();
      expect(table.table.editing.forms['1']?.activeFields.subject).toBeUndefined();
    });

    it('follows the row to another group', async () => {
      const table = await mount({ workPackages: groupedWorkPackages, groups });
      await openEditor(table, '1', 'subject', 1);
      const input = textbox(table);
      await waitFor(() => expect(input).toHaveFocus());

      table.querySpace.groups.putValue([
        buildGroup({ value: 'New', href: newStatus.href, count: 1 }, 'status', 0),
        buildGroup({ value: 'In progress', href: inProgressStatus.href, count: 2 }, 'status', 1),
      ]);
      await table.render([
        { id: '2', attributes: { status: newStatus } },
        { id: '1', attributes: { status: inProgressStatus } },
        { id: '3', attributes: { status: inProgressStatus } },
      ]);
      expect(textbox(table)).toBe(input);
      expect(table.groupHeaderOf(table.row('1'))).toBe(table.groupHeader(1));

      fireEvent.keyDown(input, { key: 'Escape' });

      await waitFor(() => expect(navigableCells(table.row('1'))[1]).toHaveFocus());
    });

    describe('with a pending submit', () => {
      it('keeps the focus return after the column moved', async () => {
        const save = deferred<{ resource:WorkPackageResource, wasNew:boolean }>();
        const table = await mount({ editing: { fields: ['subject', 'priority'], types: { priority: 'Priority' }, save: () => save.promise } });
        await openEditor(table, '1', 'subject', 1);
        await waitFor(() => expect(textbox(table)).toHaveFocus());
        const handler = table.table.editing.forms['1'].activeFields.subject;
        const submitted = handler.handleUserSubmit();

        await moveSubjectColumn(table);
        save.resolve({ resource: resource(table, '1'), wasNew: false });
        await submitted;

        expect(navigableCells(table.row('1'))[2]).toHaveFocus();
      });

      it('returns focus to the cell at the new index when the save disabled the input', async () => {
        const save = deferred<{ resource:WorkPackageResource, wasNew:boolean }>();
        const table = await mount({ editing: { fields: ['subject', 'priority'], types: { priority: 'Priority' }, save: () => save.promise } });
        await openEditor(table, '1', 'subject', 1);
        const input = textbox(table);
        await waitFor(() => expect(input).toHaveFocus());
        const handler = table.table.editing.forms['1'].activeFields.subject;
        const submitted = handler.handleUserSubmit();
        input.disabled = true;
        input.blur();

        await moveSubjectColumn(table);
        save.resolve({ resource: resource(table, '1'), wasNew: false });
        await submitted;

        expect(navigableCells(table.row('1'))[2]).toHaveFocus();
      });

      it('keeps the editor focused after a validation error', async () => {
        const save = deferred<{ resource:WorkPackageResource, wasNew:boolean }>();
        const table = await mount({ editing: { fields: ['subject', 'priority'], types: { priority: 'Priority' }, save: () => save.promise } });
        const notice = vi.spyOn(table.injector.get(HalResourceNotificationService), 'handleRawError');
        await openEditor(table, '1', 'subject', 1);
        const input = textbox(table);
        await waitFor(() => expect(input).toHaveFocus());
        const handler = table.table.editing.forms['1'].activeFields.subject;
        const submitted = handler.handleUserSubmit().catch((error:unknown) => error);
        const errorResource = new ErrorResource(table.injector, {}, true, () => undefined, 'Error');
        vi.spyOn(errorResource, 'getInvolvedAttributes').mockReturnValue(['subject']);
        vi.spyOn(errorResource, 'getMessagesPerAttribute').mockReturnValue({ subject: ['Subject is invalid'] });
        const error = new HalError(new HttpErrorResponse({ status: 422 }), errorResource);

        await moveSubjectColumn(table);
        input.blur();
        save.reject(error);

        expect(await submitted).toBe(error);
        await waitFor(() => expect(input).toHaveFocus());
        expect(input).toHaveAttribute('aria-invalid', 'true');
        expect(table.table.editing.forms['1'].activeFields.subject).toBe(handler);
        expect(notice).toHaveBeenCalledWith(error, table.table.editing.forms['1'].resource);
      });
    });

    describe('with two editors whose columns swap', () => {
      type Field = 'subject'|'description';
      const orders:[Field, Field][] = [['subject', 'description'], ['description', 'subject']];
      const twoEditors = (save?:() => Promise<{ resource:WorkPackageResource, wasNew:boolean }>) => ({
        columns: ['id', 'subject', 'description'],
        editing: { fields: ['subject', 'description'], save },
      });

      const cellOf = (table:TableHarness, field:Field) => table.row('1').querySelector<HTMLTableCellElement>(`.wp-table--cell-td.${field}`)!;
      const inputOf = (table:TableHarness, field:Field) => within(cellOf(table, field)).getByRole<HTMLInputElement>('textbox');
      const columnOf = (table:TableHarness, field:Field) => navigableCells(table.row('1')).indexOf(cellOf(table, field));

      const engage = async (table:TableHarness, field:Field) => {
        await openEditor(table, '1', field, columnOf(table, field));
        await waitFor(() => expect(inputOf(table, field)).toHaveFocus());
      };

      const openBoth = async (table:TableHarness, order:[Field, Field], userOn:Field) => {
        await engage(table, order[0]);
        fireEvent.keyDown(inputOf(table, order[0]), { key: 'Tab' });
        await engage(table, order[1]);
        if (userOn !== order[1]) {
          fireEvent.keyDown(inputOf(table, order[1]), { key: 'Tab' });
          await engage(table, userOn);
        }
      };

      const swapColumns = async (table:TableHarness) => {
        const rendered = table.nextRender();
        table.setColumns(['id', 'description', 'subject']);
        await rendered;
      };

      it.each(orders.flatMap(([first, second]) => [[first, second, first], [first, second, second]] as const))(
        'keeps the cursor and Tab stop on the editor the user is in (opened %s, then %s, in %s)',
        async (first, second, userOn) => {
          const table = await mount(twoEditors());
          await openBoth(table, [first, second], userOn);
          const input = inputOf(table, userOn);

          await swapColumns(table);

          const cell = cellOf(table, userOn);
          const column = columnOf(table, userOn);
          expect(inputOf(table, userOn)).toBe(input);
          expect(input).toHaveFocus();
          expect(table.table.keyboardNavigation.position).toEqual({ key: wpOccurrenceKey('1'), cell: column, desiredColumn: column });
          expect(tabStops(table)).toEqual([cell]);

          fireEvent.keyDown(input, { key: 'Escape' });
          await waitFor(() => expect(cell).toHaveFocus());

          fireEvent.keyDown(cell, { key: 'F2' });
          await waitFor(() => expect(table.table.editing.forms['1'].activeFields[userOn]).toBeDefined());
          expect(within(cellOf(table, userOn)).getByRole('textbox')).toHaveFocus();
        },
      );

      it.each(orders)('returns each editor to its own new cell on Escape (opened %s, then %s)', async (...order) => {
        const table = await mount(twoEditors());
        await openBoth(table, order, order[0]);

        await swapColumns(table);

        fireEvent.keyDown(inputOf(table, order[0]), { key: 'Escape' });
        await waitFor(() => expect(cellOf(table, order[0])).toHaveFocus());
        await engage(table, order[1]);
        fireEvent.keyDown(inputOf(table, order[1]), { key: 'Escape' });
        await waitFor(() => expect(cellOf(table, order[1])).toHaveFocus());
      });

      it.each(orders)('returns focus to the submitted editor\'s own new cell (opened %s, then %s)', async (...order) => {
        const save = deferred<{ resource:WorkPackageResource, wasNew:boolean }>();
        const table = await mount(twoEditors(() => save.promise));
        await openBoth(table, order, order[0]);
        const submitted = table.table.editing.forms['1'].activeFields[order[0]].handleUserSubmit();

        await swapColumns(table);
        save.resolve({ resource: resource(table, '1'), wasNew: false });
        await submitted;

        expect(cellOf(table, order[0])).toHaveFocus();
      });

      it.each(orders)('refocuses the submitted editor after a validation error (opened %s, then %s)', async (...order) => {
        const save = deferred<{ resource:WorkPackageResource, wasNew:boolean }>();
        const table = await mount(twoEditors(() => save.promise));
        await openBoth(table, order, order[0]);
        const input = inputOf(table, order[0]);
        const submitted = table.table.editing.forms['1'].activeFields[order[0]].handleUserSubmit().catch((error:unknown) => error);
        const error = validationError(table, order[0]);

        await swapColumns(table);
        input.blur();
        save.reject(error);

        expect(await submitted).toBe(error);
        await waitFor(() => expect(input).toHaveFocus());
      });

      it.each(orders)('follows a parked editor when two parked editors swap columns (opened %s, then %s)', async (...order) => {
        const table = await mount(twoEditors());
        await engage(table, order[0]);
        fireEvent.keyDown(inputOf(table, order[0]), { key: 'Tab' });
        await engage(table, order[1]);
        fireEvent.keyDown(inputOf(table, order[1]), { key: 'Tab' });
        const navigation = table.table.keyboardNavigation;
        navigation.focusPosition(navigation.positionOfCell(cellOf(table, order[0]))!);
        await waitFor(() => expect(cellOf(table, order[0])).toHaveFocus());

        await swapColumns(table);

        const cell = cellOf(table, order[0]);
        await waitFor(() => expect(cell).toHaveFocus());
        expect(tabStops(table)).toEqual([cell]);
        fireEvent.keyDown(cell, { key: 'F2' });
        await waitFor(() => expect(inputOf(table, order[0])).toHaveFocus());
      });
    });

    it('moves a user position resting on the editor\'s old cell while the cursor is elsewhere', async () => {
      const table = await mount({ workPackages: groupedWorkPackages, groups });
      fireEvent.click(table.groupHeader(1).querySelector('.expander')!);
      await waitFor(() => expect(table.row('3')).not.toBeVisible());
      await openEditor(table, '1', 'subject', 1);
      const input = textbox(table);
      await waitFor(() => expect(input).toHaveFocus());
      const navigation = table.table.keyboardNavigation;
      navigation.focusPosition(navigation.positionOfCell(navigableCells(table.row('3'))[1])!);
      expect(input).toHaveFocus();

      await moveSubjectColumn(table);
      fireEvent.keyDown(input, { key: 'Escape' });

      await waitFor(() => expect(subjectCell(table.row('1'))).toHaveFocus());
    });

    it('keeps a remembered work package when only the parked editor\'s column moved', async () => {
      const table = await mount();
      await openEditor(table, '1', 'subject', 1);
      const input = textbox(table);
      await waitFor(() => expect(input).toHaveFocus());
      fireEvent.keyDown(input, { key: 'Tab' });
      await waitFor(() => expect(subjectCell(table.row('1'))).toHaveFocus());
      const navigation = table.table.keyboardNavigation;
      navigation.focusPosition(navigation.positionOfCell(navigableCells(table.row('1'))[0])!);

      navigation.rememberWorkPackageAfterRender('2');
      await moveSubjectColumn(table);

      await waitFor(() => expect(table.row('2')).toHaveFocus());
      expect(textbox(table)).toBe(input);
    });

    describe('when the grouping changes', () => {
      const bug = { href: '/api/v3/types/1' };
      const task = { href: '/api/v3/types/2' };
      const regroupings = [
        {
          name: 'ungrouped to grouped by status',
          options: { workPackages: groupedWorkPackages },
          groupBy: 'status',
          groups,
        },
        {
          name: 'grouped by status to grouped by type',
          options: {
            workPackages: [
              { id: '1', attributes: { status: newStatus, type: bug } },
              { id: '2', attributes: { status: newStatus, type: bug } },
              { id: '3', attributes: { status: inProgressStatus, type: task } },
            ],
            groups,
          },
          groupBy: 'type',
          groups: [
            { value: 'Bug', href: bug.href, count: 2 },
            { value: 'Task', href: task.href, count: 1 },
          ],
        },
      ];

      const regroup = async (table:TableHarness, regrouping:typeof regroupings[number]) => {
        table.querySpace.query.putValue(buildQuery(['id', 'subject', 'priority'], regrouping.groupBy, false, false));
        table.querySpace.groups.putValue(regrouping.groups.map((group, index) => buildGroup(group, regrouping.groupBy, index)));
        await redraw(table);
        expect(table.groupHeaderOf(table.row('1'))?.dataset.groupIdentifier).toContain(regrouping.groupBy);
      };

      describe.each(regroupings)('$name', (regrouping) => {
        it('keeps the cursor and Tab stop on the focused editor\'s cell', async () => {
          const table = await mount(regrouping.options);
          await openEditor(table, '1', 'subject', 1);
          const input = textbox(table);
          await waitFor(() => expect(input).toHaveFocus());

          await regroup(table, regrouping);

          const cell = subjectCell(table.row('1'));
          const navigation = table.table.keyboardNavigation;
          expect(textbox(table)).toBe(input);
          expect(input).toHaveFocus();
          expect(navigation.position).toEqual(navigation.positionOfCell(cell));
          expect(tabStops(table)).toEqual([cell]);

          fireEvent.keyDown(input, { key: 'Escape' });
          await waitFor(() => expect(cell).toHaveFocus());
        });

        it('keeps focus on the parked editor\'s cell', async () => {
          const table = await mount(regrouping.options);
          await openEditor(table, '1', 'subject', 1);
          const input = textbox(table);
          await waitFor(() => expect(input).toHaveFocus());
          fireEvent.keyDown(input, { key: 'Tab' });
          expect(subjectCell(table.row('1'))).toHaveFocus();

          await regroup(table, regrouping);

          expect(textbox(table)).toBe(input);
          expect(subjectCell(table.row('1'))).toHaveFocus();
        });

        it('refocuses the editor after a validation error', async () => {
          const save = deferred<{ resource:WorkPackageResource, wasNew:boolean }>();
          const table = await mount({ ...regrouping.options, editing: { fields: ['subject', 'priority'], types: { priority: 'Priority' }, save: () => save.promise } });
          await openEditor(table, '1', 'subject', 1);
          const input = textbox(table);
          await waitFor(() => expect(input).toHaveFocus());
          const submitted = table.table.editing.forms['1'].activeFields.subject.handleUserSubmit().catch((error:unknown) => error);
          const error = validationError(table, 'subject');

          await regroup(table, regrouping);
          input.blur();
          save.reject(error);

          expect(await submitted).toBe(error);
          await waitFor(() => expect(input).toHaveFocus());
        });
      });
    });
  });

  describe('keeping the fresh cell\'s hierarchy indicator', () => {
    const mountHierarchy = (workPackages:TableHarnessOptions['workPackages'], showHierarchies = true) => mount({
      workPackages, showHierarchies, columns: ['id', 'subject'], editing: { fields: ['subject'] },
    });

    const expectIndicatorToggles = async (table:TableHarness, input:HTMLInputElement) => {
      const cell = subjectCell(table.row('1'));
      expect(cell.querySelectorAll('.wp-table--hierarchy-span')).toHaveLength(1);
      expect(input.closest<HTMLElement>('.wp-table--cell-container')!.style.width).toMatch(/^calc\(/);
      expect(within(cell).getByRole('textbox')).toBe(input);
      expect(table.table.editing.forms['1'].activeFields.subject).toBeDefined();

      fireEvent.keyDown(input, { key: 'Escape' });
      await waitFor(() => expect(table.table.editing.forms['1']?.activeFields.subject).toBeUndefined());

      fireEvent.click(within(subjectCell(table.row('1'))).getByRole('button'));
      await waitFor(() => expect(table.row('2')).not.toBeVisible());
    };

    it('when a leaf gains its first child', async () => {
      const table = await mountHierarchy([{ id: '1' }, { id: '2' }]);
      await openEditor(table, '1', 'subject', 1);
      const input = textbox(table);
      await waitFor(() => expect(input).toHaveFocus());

      await table.render([{ id: '1' }, { id: '2', ancestors: [{ id: '1' }] }]);

      await expectIndicatorToggles(table, input);
    });

    it('when a flat table turns into a hierarchy', async () => {
      const table = await mountHierarchy([{ id: '1' }, { id: '2', ancestors: [{ id: '1' }] }], false);
      await openEditor(table, '1', 'subject', 1);
      const input = textbox(table);
      await waitFor(() => expect(input).toHaveFocus());

      table.injector.get(WorkPackageViewHierarchiesService).setEnabled(true);
      await table.render();

      await expectIndicatorToggles(table, input);
    });
  });

  describe('taking over the fresh cell\'s baseline layout', () => {
    it.each([true, false])('when the baseline comparison changes (shown before: %s)', async (before) => {
      const table = await mount({ baseline: before, workPackages: [{ id: '1', baseline: 'updated' }, { id: '2' }] });
      await openEditor(table, '1', 'subject', 1);
      const input = textbox(table);
      await waitFor(() => expect(input).toHaveFocus());
      const host = () => subjectCell(table.row('1')).querySelector('.inline-edit--container')!;
      const expectLayout = (baseline:boolean) => {
        expect(host().classList.contains('op-table-baseline--container')).toBe(baseline);
        expect(host().classList.contains('wp-table--cell-container')).toBe(!baseline);
      };
      expectLayout(before);
      vi.spyOn(table.injector.get(WorkPackageViewBaselineService), 'isChanged')
        .mockImplementation((workPackage, attribute) => !before && workPackage.id === '1' && attribute === 'subject');

      await redraw(table);

      expect(textbox(table)).toBe(input);
      expectLayout(!before);

      fireEvent.keyDown(input, { key: 'Escape' });
      await waitFor(() => expect(table.table.editing.forms['1']?.activeFields.subject).toBeUndefined());
      expectLayout(!before);
    });
  });

  describe('releasing editors a render cannot keep', () => {
    it('closes the editor when its column is removed, keeping the draft', async () => {
      const table = await mount();
      const drafts = holdDrafts(table);
      await openEditor(table, '1', 'subject', 1);
      drafts.set('1', 'subject', 'Draft subject');

      const rendered = table.nextRender();
      table.setColumns(['id', 'priority']);
      await rendered;

      expect(table.table.editing.forms['1']).toBeUndefined();
      expect(within(table.row('1')).queryByRole('textbox')).not.toBeInTheDocument();
      expect(drafts.value('1', 'subject')).toBe('Draft subject');
    });

    it('closes the editor of a row that is gone and focuses the row that took its place', async () => {
      const table = await mount({ workPackages: [{ id: '1' }, { id: '2' }, { id: '3' }] });
      await openEditor(table, '2', 'subject', 1);
      await waitFor(() => expect(textbox(table, '2')).toHaveFocus());

      await table.render([{ id: '1' }, { id: '3' }]);

      expect(table.table.editing.forms['2']).toBeUndefined();
      expect(document.activeElement?.closest('tr')).toBe(table.row('3'));
    });

    it('closes the editor of a row hidden by a collapsed group', async () => {
      const table = await mount({ workPackages: groupedWorkPackages, groups });
      const drafts = holdDrafts(table);
      await openEditor(table, '1', 'subject', 1);
      await waitFor(() => expect(textbox(table)).toHaveFocus());
      drafts.set('1', 'subject', 'Draft subject');
      const frames = table.holdFrames();
      try {
        table.table.redrawTable();
        fireEvent.click(table.groupHeader(0).querySelector('.expander')!);
        frames.commit();
      } finally {
        frames.release();
      }

      expect(table.table.editing.forms['1']).toBeUndefined();
      expect(drafts.value('1', 'subject')).toBe('Draft subject');
      expect(document.activeElement).toBe(table.groupHeader(0));
    });

    it('closes the editor of a row hidden by a collapsed hierarchy parent', async () => {
      const table = await mount({ workPackages: [{ id: '1' }, { id: '2', ancestors: [{ id: '1' }] }], showHierarchies: true, columns: ['id', 'subject'], editing: { fields: ['subject'] } });
      const drafts = holdDrafts(table);
      await openEditor(table, '2', 'subject', 1);
      await waitFor(() => expect(textbox(table, '2')).toHaveFocus());
      drafts.set('2', 'subject', 'Draft subject');
      const frames = table.holdFrames();
      try {
        table.table.redrawTable();
        table.injector.get(WorkPackageViewHierarchiesService).collapse('1');
        frames.commit();
      } finally {
        frames.release();
      }

      expect(table.row('2')).not.toBeVisible();
      expect(table.table.editing.forms['2']).toBeUndefined();
      expect(drafts.value('2', 'subject')).toBe('Draft subject');
      expect(document.activeElement).toBe(table.row('1'));
    });

    it('closes the editor when its relation-row occurrence is gone although the work package\'s primary row remains', async () => {
      const table = await mount({
        workPackages: [{ id: '1' }, { id: '2' }],
        relations: [{ from: '1', to: '2', type: 'follows', reverseType: 'precedes' }],
        columns: ['id', 'subject', { id: 'relationsOfTypeFollows', relationType: 'follows' }],
        editing: { fields: ['subject'] },
      });
      table.expand('1', 'relationsOfTypeFollows');
      await table.nextRender();
      await openEditorIn(table, table.relationRow('1', '2'), 'subject', 1);

      const rendered = table.nextRender();
      table.injector.get(WorkPackageViewRelationColumnsService).collapse('1');
      await rendered;

      expect(table.table.editing.forms['2']).toBeUndefined();
      expect(within(table.row('2')).queryByRole('textbox')).not.toBeInTheDocument();
      expect(table.tbody.querySelector('.inline-edit--active-field')).toBeNull();
    });

    it('closes a field that registered an overlay during the held frame', async () => {
      const table = await mount();
      await openEditor(table, '1', 'subject', 1);
      const handler = table.table.editing.forms['1'].activeFields.subject;
      const overlay = document.body.appendChild(document.createElement('div'));
      onTestFinished(() => overlay.remove());
      const frames = table.holdFrames();
      try {
        table.table.redrawTable();
        handler.registerOverlay(overlay);
        frames.commit();
      } finally {
        frames.release();
      }

      expect(table.table.editing.forms['1']).toBeUndefined();
      expect(document.querySelector('.inline-edit--active-field')).toBeNull();
      expect(within(subjectCell(table.row('1'))).queryByRole('textbox')).not.toBeInTheDocument();
    });
  });

  describe('deciding by field type and occurrence', () => {
    const mountWith = (type:string) => mount({
      columns: ['id', 'subject', 'estimate'],
      editing: { fields: ['subject', 'estimate'], types: { estimate: type } },
    });
    const estimateCell = (table:TableHarness) => table.row('1').querySelector<HTMLTableCellElement>('.wp-table--cell-td.estimate')!;

    it.each(['Integer', 'Float'])('keeps an editor of type %s through a redraw', async (type) => {
      const table = await mountWith(type);
      await openEditor(table, '1', 'estimate', 2);
      const input = within(estimateCell(table)).getByRole('textbox');
      await waitFor(() => expect(input).toHaveFocus());

      await redraw(table);

      expect(within(estimateCell(table)).getByRole('textbox')).toBe(input);
      expect(input).toHaveFocus();
      expect(table.table.editing.forms['1'].activeFields.estimate).toBeDefined();
    });

    it.each(['Date', 'Formattable'])('closes an editor of type %s on a redraw', async (type) => {
      const table = await mountWith(type);
      await openEditor(table, '1', 'estimate', 2);

      await redraw(table);

      expect(table.table.editing.forms['1']).toBeUndefined();
      expect(within(estimateCell(table)).queryByRole('textbox')).not.toBeInTheDocument();
    });

    it('keeps an editor in a relation row that stays expanded', async () => {
      const table = await mount({
        workPackages: [{ id: '1' }, { id: '2' }],
        relations: [{ from: '1', to: '2', type: 'follows', reverseType: 'precedes' }],
        columns: ['id', 'subject', { id: 'relationsOfTypeFollows', relationType: 'follows' }],
        editing: { fields: ['subject'] },
      });
      table.expand('1', 'relationsOfTypeFollows');
      await table.nextRender();
      await openEditorIn(table, table.relationRow('1', '2'), 'subject', 1);
      const input = within(table.relationRow('1', '2')).getByRole('textbox');
      await waitFor(() => expect(input).toHaveFocus());

      await redraw(table);

      expect(within(table.relationRow('1', '2')).getByRole('textbox')).toBe(input);
      expect(within(table.row('2')).queryByRole('textbox')).not.toBeInTheDocument();
      expect(input).toHaveFocus();
      expect(table.table.editing.forms['2'].activeFields.subject).toBeDefined();
    });

    it('leaves no field active when the table is destroyed with a render pending', async () => {
      const table = await mount();
      await openEditor(table, '1', 'subject', 1);
      const form = table.table.editing.forms['1'];
      const frames = table.holdFrames();
      try {
        table.table.redrawTable();
        await table.destroy();
        expect(() => frames.commit()).not.toThrow();
      } finally {
        frames.release();
      }

      expect(form.activeFields).toEqual({});
      expect(table.table.editing.activeTableFields()).toEqual([]);
    });
  });
});

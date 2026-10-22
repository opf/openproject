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
import { DisplayFieldRenderer } from 'core-app/shared/components/fields/display/display-field-renderer';
import { DisplayFieldService } from 'core-app/shared/components/fields/display/display-field.service';
import { TextDisplayField } from 'core-app/shared/components/fields/display/field-types/text-display-field.module';
import { WorkPackageViewOrderService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-order.service';
import { buildWorkPackage } from '../../../testing/work-package-fixture';
import { buildTable, TableHarness } from '../../../testing/table-harness';
import { QueryColumn, queryColumnTypes } from 'core-app/features/work-packages/components/wp-query/query-column';
import { WorkPackageTableConfiguration, WorkPackageTableConfigurationObject } from 'core-app/features/work-packages/components/wp-table/wp-table-configuration';
import {
  internalBaselineColumn,
  internalContextMenuColumn,
  internalSortColumn,
} from '../../../builders/internal-sort-columns';
import {
  isNavigableColumn,
  navigableCellClassName,
  navigableCells,
  paintRovingTabindex,
} from './roving-tabindex';

class AnchorDisplayField extends TextDisplayField {
  public render(element:HTMLElement, displayText:string):void {
    const link = document.createElement('a');
    link.href = '#';
    link.textContent = displayText;
    element.appendChild(link);
  }
}

class LateLinkDisplayField extends TextDisplayField {
  public render(element:HTMLElement, displayText:string):void {
    const link = document.createElement('a');
    link.textContent = displayText;
    element.appendChild(link);
    setTimeout(() => { link.href = '#'; });
  }
}

describe('roving tabindex', () => {
  let harness:TableHarness|undefined;

  const mount = async (
    keyboardNavigationEnabled:boolean,
    extra:Parameters<typeof buildTable>[0]['configuration'] = {},
    options:Partial<Parameters<typeof buildTable>[0]> = {},
  ) => {
    const status = { name: 'Open', href: '/api/v3/statuses/1' };
    harness = buildTable({
      workPackages: [{ id: '1', attributes: { status } }, { id: '2', attributes: { status } }],
      productionMarkup: true,
      editing: {},
      groups: [{ value: 'Open', href: '/api/v3/statuses/1', count: 2, sums: { estimatedTime: 'PT1H' } as never }],
      configuration: { keyboardNavigationEnabled, ...extra },
      ...options,
    });
    await harness.render();
    return harness;
  };

  const tabbables = (root:HTMLElement) => Array.from(root.querySelectorAll('[tabindex="0"]'));

  const subjectField = (table:TableHarness) => table.row('1').querySelector('td.subject .inline-edit--display-field')!;

  afterEach(async () => {
    await harness?.destroy();
    harness = undefined;
  });

  describe('stray Tab stops', () => {
    it('sweeps a Tab stop a custom element added after the display field rendered', async () => {
      const table = await mount(true);
      const late = document.createElement('span');
      late.setAttribute('tabindex', '0');
      table.row('1').querySelector('td.subject')!.appendChild(late);

      paintRovingTabindex(table.table.scrollContainer, table.row('1'));

      expect(late).toHaveAttribute('tabindex', '-1');
    });

    it('leaves the inline-create button and an open editor input alone', async () => {
      const table = await mount(true);
      const editor = document.createElement('div');
      editor.className = 'inline-edit--active-field';
      const input = document.createElement('input');
      editor.appendChild(input);
      table.row('1').querySelector('td.subject')!.appendChild(editor);
      const button = within(table.container).getByRole('button', { name: 'Create new work package' });

      paintRovingTabindex(table.table.scrollContainer, table.row('2'));

      expect(input).not.toHaveAttribute('tabindex', '-1');
      expect(button).not.toHaveAttribute('tabindex');
      expect(button.closest('tr')).not.toHaveAttribute('tabindex');
    });
  });

  describe('with the flag off', () => {
    it('keeps rows and editable fields tabbable', async () => {
      const table = await mount(false);

      expect(table.row('1')).toHaveAttribute('tabindex', '0');
      expect(subjectField(table)).toHaveAttribute('tabindex', '0');
      expect(subjectField(table)).toHaveAttribute('role', 'button');
      expect(table.container.querySelector(`.${navigableCellClassName}`)).toBeNull();
    });

    it.each([
      ['the BCF list', { dragAndDropEnabled: false }],
      ['an embedded table', { isEmbedded: true }],
    ])('keeps today\'s Tab stops and handles no keys in %s', async (_name, configuration) => {
      harness = buildTable({
        workPackages: [{ id: '1' }, { id: '2' }],
        productionMarkup: true,
        editing: {},
        configuration,
      });
      await harness.render();
      harness.row('1').focus();

      expect(harness.table.configuration.keyboardNavigationEnabled).toBe(false);
      expect(harness.row('1')).toHaveAttribute('tabindex', '0');
      expect(harness.row('2')).toHaveAttribute('tabindex', '0');
      expect(subjectField(harness)).toHaveAttribute('tabindex', '0');
      expect(subjectField(harness)).toHaveAttribute('role', 'button');
      expect(harness.table.keyboardNavigation).toBeNull();
      expect(fireEvent.keyDown(harness.row('1'), { key: 'ArrowDown' })).toBe(true);
      expect(harness.row('1')).toHaveFocus();
    });

    it('leaves the header sort link without a tabindex', async () => {
      const table = await mount(false);

      expect(table.headerCells()[0].querySelector('a')).not.toHaveAttribute('tabindex');
    });
  });

  describe('with the flag on', () => {
    it('leaves the first work package row as the only Tab stop inside the table', async () => {
      const table = await mount(true, { dragAndDropEnabled: true, columnMenuEnabled: true });

      expect(tabbables(table.container)).toEqual([table.row('1')]);
    });

    it('leaves no native Tab stop but the first row, links included', async () => {
      harness = buildTable({
        workPackages: [{ id: '1' }],
        productionMarkup: true,
        configuration: { keyboardNavigationEnabled: true, columnMenuEnabled: true },
      });
      harness.injector.get(DisplayFieldService).addFieldType(AnchorDisplayField, 'text', ['String']);
      await harness.render();

      expect(harness.row('1').querySelector('a[href]')).toHaveAttribute('tabindex', '-1');
      expect(Array.from(harness.container.querySelectorAll('[tabindex="0"], a[href]:not([tabindex="-1"]), button:not([tabindex="-1"])'))
        .filter((element) => !element.closest('tbody[wpInlineCreate]'))).toEqual([harness.row('1')]);
    });

    it('takes a link out of the Tab order when its href is set after render', async () => {
      harness = buildTable({
        workPackages: [{ id: '1' }],
        productionMarkup: true,
        configuration: { keyboardNavigationEnabled: true },
      });
      harness.injector.get(DisplayFieldService).addFieldType(LateLinkDisplayField, 'text', ['String']);
      await harness.render();
      const link = harness.row('1').querySelector('td.subject a')!;

      await waitFor(() => expect(link).toHaveAttribute('href', '#'));
      expect(link).toHaveAttribute('tabindex', '-1');
    });

    it('takes the hierarchy and leaf indicators out of the Tab order', async () => {
      harness = buildTable({
        workPackages: [{ id: '1' }, { id: '2', ancestors: [{ id: '1' }] }],
        showHierarchies: true,
        configuration: { keyboardNavigationEnabled: true },
      });
      await harness.render();
      const indicators = harness.container.querySelectorAll('.wp-table--hierarchy-indicator, .wp-table--leaf-indicator');

      expect(indicators.length).toBeGreaterThan(1);
      indicators.forEach((indicator) => expect(indicator).toHaveAttribute('tabindex', '-1'));
    });

    it('drops the tabindex and button role from editable fields', async () => {
      const table = await mount(true);

      expect(subjectField(table)).not.toHaveAttribute('tabindex');
      expect(subjectField(table)).not.toHaveAttribute('role');
    });

    it('excludes the drag handle cell from the navigable cells', async () => {
      const table = await mount(true, { dragAndDropEnabled: true });
      const cells = navigableCells(table.row('1'));

      expect(cells.length).toBeGreaterThan(0);
      expect(cells.every((cell) => cell.classList.contains(navigableCellClassName))).toBe(true);
      expect(cells.some((cell) => cell.classList.contains('wp-table--sort-td'))).toBe(false);
      expect(table.row('1').querySelectorAll('td')).toHaveLength(cells.length + 1);
    });

    it('marks the header, totals and context menu cells as navigable', async () => {
      const table = await mount(true, { columnMenuEnabled: true });

      expect(table.headerCells().every((cell) => cell.classList.contains(navigableCellClassName))).toBe(true);
      expect(navigableCells(table.totalsRow()).length).toBeGreaterThan(0);
      expect(navigableCells(table.row('1')).at(-1)).toHaveClass('hide-when-print');
    });
  });

  describe('isNavigableColumn', () => {
    const configuration = (flags:WorkPackageTableConfigurationObject) => new WorkPackageTableConfiguration({
      actionsColumnEnabled: false,
      columnMenuEnabled: false,
      ...flags,
    });

    it.each([
      ['the sort column', internalSortColumn, {}, false],
      ['the baseline column', internalBaselineColumn, {}, false],
      ['the context column with both menus off', internalContextMenuColumn, {}, false],
      ['the context column with the actions column on', internalContextMenuColumn, { actionsColumnEnabled: true }, true],
      ['the context column with the column menu on', internalContextMenuColumn, { columnMenuEnabled: true }, true],
      ['a query column', { id: 'subject' } as QueryColumn, {}, true],
      ['a relation column', { id: 'relationsOfTypeFollows', _type: queryColumnTypes.RELATION_OF_TYPE } as QueryColumn, {}, true],
    ])('%s is navigable: %s', (_name, column, flags, expected) => {
      expect(isNavigableColumn(column, configuration(flags))).toBe(expected);
    });
  });

  describe('navigable cell eligibility', () => {
    const groupSumsRow = (table:TableHarness) => table.container.querySelector<HTMLTableRowElement>('tbody.work-package--results-tbody tr.wp-table--sums-row')!;

    it('marks the same cells navigable in body, group sums and totals rows with drag and drop on', async () => {
      const table = await mount(true, { dragAndDropEnabled: true });
      const body = navigableCells(table.row('1'));
      const sums = navigableCells(groupSumsRow(table));
      const totals = navigableCells(table.totalsRow());

      expect(body.length).toBeGreaterThan(0);
      expect(sums).toHaveLength(body.length);
      expect(totals).toHaveLength(body.length);
      expect(groupSumsRow(table).cells[0]).not.toHaveClass(navigableCellClassName);
    });

    it('never marks the drag placeholder before the handle render pass replaces it', async () => {
      const table = await mount(true, { dragAndDropEnabled: true }, {
        beforeAttach: (injector) => {
          vi.spyOn(injector.get(WorkPackageViewOrderService), 'positionsFor').mockReturnValue(new Promise(() => undefined));
        },
      });

      expect(table.row('1').cells[0]).not.toHaveClass(navigableCellClassName);
    });

    it('marks the relation cells of an expanded relation row and takes its row out of the Tab order', async () => {
      const table = await mount(true, {}, {
        columns: ['id', 'subject', { id: 'relationsOfTypeFollows', relationType: 'follows' }],
        relations: [{ from: '1', to: '2', type: 'follows', reverseType: 'precedes' }],
        groups: undefined,
      });
      table.expand('1', 'relationsOfTypeFollows');
      await table.render();
      const relationRow = table.relationRow('1', '2');

      expect(relationRow).toHaveAttribute('tabindex', '-1');
      expect(navigableCells(relationRow)).toHaveLength(navigableCells(table.row('1')).length);
      expect(relationRow.querySelector('td.relationsOfTypeFollows')).toHaveClass(navigableCellClassName);
      expect(relationRow.querySelector('[tabindex="0"]')).toBeNull();
    });

    it('adds nothing when the flag is off', async () => {
      const table = await mount(false, { dragAndDropEnabled: true });

      expect(table.container.querySelector(`.${navigableCellClassName}`)).toBeNull();
      expect(table.container.querySelector('tr.wp-table--relations-additional-row[tabindex]')).toBeNull();
    });
  });

  describe('paintRovingTabindex', () => {
    it.each([
      ['a header cell', (table:TableHarness) => table.headerCells()[1]],
      ['a body row', (table:TableHarness) => table.row('2')],
      ['a body cell', (table:TableHarness) => navigableCells(table.row('2'))[1]],
    ])('marks exactly %s', async (_name, pick) => {
      const table = await mount(true);
      const target = pick(table);

      paintRovingTabindex(table.container, target);

      expect(tabbables(table.container)).toEqual([target]);
      expect(table.row('1')).toHaveAttribute('tabindex', '-1');
      expect(table.headerRow()).toHaveAttribute('tabindex', '-1');
    });

    it('marks nothing when no element is focused', async () => {
      const table = await mount(true);

      paintRovingTabindex(table.container, null);

      expect(tabbables(table.container)).toHaveLength(0);
    });
  });

  describe('DisplayFieldRenderer', () => {
    it('stays tabbable for the details pane by default', async () => {
      const table = await mount(true);
      const span = new DisplayFieldRenderer(table.injector, 'single-view').render(buildWorkPackage({ id: '1' }), 'subject', null);

      expect(span).toHaveAttribute('tabindex', '0');
      expect(span).toHaveAttribute('role', 'button');
    });
  });
});

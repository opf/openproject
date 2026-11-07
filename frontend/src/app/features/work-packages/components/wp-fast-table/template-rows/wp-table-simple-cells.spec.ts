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

import { Component, getDebugNode, Injector, input } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { within } from '@testing-library/dom';
import { buildQuery, FakeDragAndDropService, harnessProviders } from '../testing/table-harness';
import { buildWorkPackage } from '../testing/work-package-fixture';
import { beginTemplateCellEdit, endTemplateCellEdit } from './template-cell-editing';
import { editModeClassName } from 'core-app/shared/components/fields/edit/edit-field.component';
import { IdCellPresenter } from './id-cell-presenter';
import { TemplateRowView, TemplateWorkPackageRow } from './template-row';
import { TextCellPresentation } from './text-cell-presentation';
import { WorkPackageTableRowComponent } from './wp-table-row.component';

const before:TextCellPresentation = {
  attribute: 'subject', displayClasses: 'subject -editable -required', text: '<Original>', title: '<Original>', label: 'Edit Subject <Original>',
};

@Component({
  imports: [WorkPackageTableRowComponent],
  template: '<table><tbody><tr opWpTableRow [row]="row()" [view]="view()"></tr></tbody></table>',
})
class SimpleCellsTestTableComponent {
  readonly row = input.required<TemplateWorkPackageRow>();
  readonly view = input.required<TemplateRowView>();
}

describe.each(['id', 'subject'] as const)('template simple cells with %s as row header', (rowHeader) => {
  let fixture:ComponentFixture<SimpleCellsTestTableComponent>;
  let row:HTMLTableRowElement;
  let idCell:HTMLTableCellElement;
  let subjectCell:HTMLTableCellElement;
  let view:TemplateRowView;

  function setRow(update:Pick<TemplateWorkPackageRow, 'workPackage'|'revision'>):void {
    const row:TemplateWorkPackageRow = {
      kind: 'workPackage',
      key: 'wp:42',
      classIdentifier: 'wp-row-42',
      additionalClasses: [],
      level: 1,
      ...update,
    };
    fixture.componentRef.setInput('row', row);
  }

  function setPresentation(...presentations:TextCellPresentation[]):void {
    view = { ...view, textCell: (_row, column) => presentations.find(({ attribute }) => attribute === column.id) ?? null };
    fixture.componentRef.setInput('view', view);
  }

  function setColumns(...columns:string[]):void {
    view = { ...view, columns: buildQuery(columns, null, false, false).columns };
    fixture.componentRef.setInput('view', view);
    fixture.detectChanges();
  }

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        ...harnessProviders(new FakeDragAndDropService(), { workPackages: [] }),
        { provide: PathHelperService, useValue: { genericWorkPackagePath: (_project:string, id:string, tab:string) => `/work_packages/${id}/${tab}` } },
      ],
    });
    fixture = TestBed.createComponent(SimpleCellsTestTableComponent);
    const idPresenter = new IdCellPresenter(TestBed.inject(Injector));
    view = {
      columns: buildQuery(['id', 'subject'], null, false, false).columns,
      rowHeader,
      rowClasses: () => [],
      actions: () => null,
      contextMenuLabel: '',
      canDrag: () => null,
      placeholder: false,
      idCell: idPresenter.present.bind(idPresenter),
      textCell: () => null,
      buildCell: () => null,
      isEditing: () => false,
    };
    setPresentation(before);
    setRow({ workPackage: buildWorkPackage({ id: '42' }), revision: 0 });
    fixture.detectChanges();
    row = (fixture.nativeElement as HTMLElement).querySelector('tr')!;
    idCell = row.cells[0];
    subjectCell = row.cells[1];
  });

  it('renders simple cell contents in the row view', () => {
    const rowComponent = fixture.debugElement.query(By.directive(WorkPackageTableRowComponent)).componentInstance as WorkPackageTableRowComponent;
    expect(getDebugNode(idCell)?.componentInstance === rowComponent).toBe(true);
    expect(getDebugNode(subjectCell)?.componentInstance === rowComponent).toBe(true);
    expect(getDebugNode(idCell)?.providerTokens).toEqual([]);
    expect(getDebugNode(subjectCell)?.providerTokens).toEqual([]);
    expect(idCell.tagName).toBe(rowHeader === 'id' ? 'TH' : 'TD');
    expect(subjectCell.tagName).toBe(rowHeader === 'subject' ? 'TH' : 'TD');
    expect(row.querySelector('th')).toHaveAttribute('scope', 'row');
  });

  it('keeps the ID link while updating its text, URL and numeric identity', () => {
    const root = idCell;
    setRow({ workPackage: Object.assign(buildWorkPackage({ id: '42' }), { displayId: 'DEMO-7' }), revision: 0 });
    fixture.detectChanges();
    const link = within(root).getByRole('link', { name: 'DEMO-7' });
    expect(link).toHaveAttribute('href', `/work_packages/DEMO-7/activity${window.location.search}`);
    expect(link).toHaveAttribute('data-work-package-id', '42');
    expect(link).toHaveAttribute('data-wp-state', 'show');
    expect(link).toHaveAttribute('tabindex', '-1');
    expect(root).toHaveAttribute('data-row-header-name', 'DEMO-7');
    expect(root.querySelector('.inline-edit--display-field')).toHaveClass('-read-only');

    setRow({ workPackage: Object.assign(buildWorkPackage({ id: '43' }), { displayId: 'DEMO-8' }), revision: 1 });
    fixture.detectChanges();
    expect(within(root).getByRole('link', { name: 'DEMO-8' })).toBe(link);
    expect(link).toHaveAttribute('data-work-package-id', '43');
    expect(root).toHaveAttribute('data-row-header-name', 'DEMO-8');
  });

  it('refreshes the same mutated resource when the row revision changes', () => {
    const workPackage = Object.assign(buildWorkPackage({ id: '42' }), { displayId: 'DEMO-7' });
    setRow({ workPackage, revision: 0 });
    fixture.detectChanges();
    workPackage.displayId = 'DEMO-8';
    setRow({ workPackage, revision: 1 });
    fixture.detectChanges();
    const link = within(idCell).getByRole('link', { name: 'DEMO-8' });
    expect(link).toHaveAttribute('href', `/work_packages/DEMO-8/activity${window.location.search}`);
    expect(link).toHaveAttribute('data-work-package-id', '42');
  });

  it('updates the retained ID link from a new view without replacing the row input', () => {
    const link = within(idCell).getByRole('link', { name: '42' });
    const alternateInjector = Injector.create({
      parent: TestBed.inject(Injector),
      providers: [{ provide: PathHelperService, useValue: { genericWorkPackagePath: (_project:string, id:string, tab:string) => `/other/${id}/${tab}` } }],
    });
    const presenter = new IdCellPresenter(alternateInjector);
    const nextView = { ...view, idCell: presenter.present.bind(presenter) };
    fixture.componentRef.setInput('view', nextView);
    fixture.detectChanges();

    expect(within(idCell).getByRole('link', { name: '42' })).toBe(link);
    expect(link).toHaveAttribute('href', `/other/42/activity${window.location.search}`);
  });

  it('falls back to a numeric ID and leaves new resources without a link', () => {
    setRow({ workPackage: buildWorkPackage({ id: '42' }), revision: 0 });
    fixture.detectChanges();
    expect(within(idCell).getByRole('link', { name: '42' })).toBeTruthy();
    setRow({ workPackage: buildWorkPackage({ id: 'new' }), revision: 1 });
    fixture.detectChanges();
    expect(within(idCell).queryByRole('link')).toBeNull();
    expect(idCell).toHaveAttribute('data-row-header-name', '');
  });

  it('renders escaped text and updates the retained display field', () => {
    const display = subjectCell.querySelector('.inline-edit--display-field');
    expect(display).toHaveTextContent('<Original>');
    expect(display).toHaveClass('-editable', '-required');
    expect(display).toHaveAttribute('aria-label', 'Edit Subject <Original>');
    expect(subjectCell.querySelector('original')).toBeNull();
    setPresentation({ ...before, text: 'After', title: 'After' });
    fixture.detectChanges();
    expect(subjectCell.querySelector('.inline-edit--display-field')).toBe(display);
    expect(display).toHaveTextContent('After');
    expect(subjectCell).toHaveAttribute('data-row-header-name', 'After');
  });

  it('keeps editor and semantic classes across new views and column reorder', () => {
    const slot = beginTemplateCellEdit(subjectCell, 'subject')!;
    slot.innerHTML = '<input aria-label="Subject" value="Unsaved">';
    const input = within(subjectCell).getByRole('textbox', { name: 'Subject' });
    subjectCell.classList.add(editModeClassName, '-pressed');

    setColumns('id', 'subject');
    expect(row.cells[1]).toBe(subjectCell);
    expect(subjectCell).toHaveClass('subject', '-max', editModeClassName, '-pressed');
    expect(within(subjectCell).getByRole('textbox', { name: 'Subject' })).toBe(input);

    setColumns('subject', 'id');
    expect(row.cells[0]).toBe(subjectCell);
    expect(subjectCell).toHaveClass('subject', '-max', editModeClassName, '-pressed');
    expect(within(subjectCell).getByRole('textbox', { name: 'Subject' })).toBe(input);
    expect(input).toHaveValue('Unsaved');
    endTemplateCellEdit(subjectCell, 'subject');
  });

  it('updates owned editability and required classes on the retained display', () => {
    const display = subjectCell.querySelector('.inline-edit--display-field');
    expect(display).toHaveClass('-editable', '-required');

    setPresentation({ ...before, displayClasses: 'subject -read-only' });
    fixture.detectChanges();

    expect(subjectCell.querySelector('.inline-edit--display-field')).toBe(display);
    expect(display).toHaveClass('-read-only');
    expect(display).not.toHaveClass('-editable');
    expect(display).not.toHaveClass('-required');

    setPresentation(before);
    fixture.detectChanges();

    expect(display).toHaveClass('-editable', '-required');
    expect(display).not.toHaveClass('-read-only');
  });

  it('gives the editor an independent container and restores the Angular display after closing', () => {
    const slot = beginTemplateCellEdit(subjectCell, 'subject')!;
    slot.innerHTML = '<input aria-label="Subject" value="Unsaved">';
    const input = within(subjectCell).getByRole('textbox', { name: 'Subject' });
    setPresentation({ ...before, text: 'Refreshed' });
    fixture.detectChanges();
    expect(within(subjectCell).getByRole('textbox', { name: 'Subject' })).toBe(input);
    expect(input).toHaveValue('Unsaved');
    endTemplateCellEdit(subjectCell, 'subject');
    expect(within(subjectCell).queryByRole('textbox')).toBeNull();
    expect(subjectCell.querySelector('.inline-edit--display-field')).toHaveTextContent('Refreshed');
    const second = beginTemplateCellEdit(subjectCell, 'subject')!;
    second.innerHTML = '<input aria-label="Subject">';
    endTemplateCellEdit(subjectCell, 'subject');
    expect(subjectCell.querySelector('.inline-edit--display-field')).toHaveTextContent('Refreshed');
  });

  it('keeps another cell editor open when one field closes', () => {
    view = { ...view, columns: buildQuery(['id', 'subject', 'customField1'], null, false, false).columns };
    setPresentation(before, { ...before, attribute: 'customField1', displayClasses: 'customField1 -editable -required', text: 'Custom field' });
    fixture.detectChanges();

    const customCell = row.cells[2];
    beginTemplateCellEdit(subjectCell, 'subject')!.innerHTML = '<input aria-label="Subject">';
    beginTemplateCellEdit(customCell, 'customField1')!.innerHTML = '<input aria-label="Custom field" value="Unsaved">';
    const input = within(customCell).getByRole('textbox', { name: 'Custom field' });

    setColumns('customField1', 'id', 'subject');
    expect(row.cells[0]).toBe(customCell);
    expect(within(customCell).getByRole('textbox', { name: 'Custom field' })).toBe(input);

    endTemplateCellEdit(subjectCell, 'subject');

    expect(within(subjectCell).queryByRole('textbox')).toBeNull();
    expect(within(customCell).getByRole('textbox', { name: 'Custom field' })).toBe(input);
    expect(input).toHaveValue('Unsaved');
    endTemplateCellEdit(customCell, 'customField1');
    expect(within(customCell).queryByRole('textbox')).toBeNull();
  });

  it('restores the display when a column is removed and added again', () => {
    beginTemplateCellEdit(subjectCell, 'subject')!.innerHTML = '<input aria-label="Subject">';

    setColumns('id');
    setColumns('id', 'subject');

    const replacement = row.cells[1];
    expect(replacement).not.toBe(subjectCell);
    expect(replacement.querySelector('.inline-edit--display-field')).toHaveTextContent('<Original>');
    expect(within(replacement).queryByRole('textbox')).toBeNull();
  });

  it('restores the display when an active cell changes its header role', () => {
    beginTemplateCellEdit(subjectCell, 'subject')!.innerHTML = '<input aria-label="Subject">';
    view = { ...view, rowHeader: rowHeader === 'subject' ? 'id' : 'subject' };
    fixture.componentRef.setInput('view', view);
    fixture.detectChanges();

    const replacement = row.cells[1];
    expect(replacement).not.toBe(subjectCell);
    expect(replacement.querySelector('.inline-edit--display-field')).toHaveTextContent('<Original>');
    expect(within(replacement).queryByRole('textbox')).toBeNull();
  });

  it('restores the display when a column switches to fallback and back', () => {
    beginTemplateCellEdit(subjectCell, 'subject')!.innerHTML = '<input aria-label="Subject">';

    setPresentation();
    fixture.detectChanges();
    setPresentation(before);
    fixture.detectChanges();

    const replacement = row.cells[1];
    expect(replacement).not.toBe(subjectCell);
    expect(replacement.querySelector('.inline-edit--display-field')).toHaveTextContent('<Original>');
    expect(within(replacement).queryByRole('textbox')).toBeNull();
  });
});

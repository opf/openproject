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

import { ComponentFixture, TestBed } from '@angular/core/testing';
import { within } from '@testing-library/dom';
import { WorkPackageTableTextCellComponent } from './wp-table-text-cell.component';
import { templateCellEditors } from './template-cell-editing';
import { TextCellPresentation } from './text-cell-presentation';

const before:TextCellPresentation = { attribute: 'subject', text: '<Original>', title: '<Original>', label: 'Edit Subject <Original>', editable: true, required: true, empty: false };

describe('template text cell', () => {
  let fixture:ComponentFixture<WorkPackageTableTextCellComponent>;
  let cell:HTMLTableCellElement;
  beforeEach(() => {
    fixture = TestBed.createComponent(WorkPackageTableTextCellComponent);
    cell = fixture.nativeElement as HTMLTableCellElement;
    fixture.componentRef.setInput('presentation', before);
    fixture.detectChanges();
  });

  it('renders escaped text and updates the retained display field', () => {
    const display = cell.querySelector('.inline-edit--display-field');
    expect(display).toHaveTextContent('<Original>');
    expect(display).toHaveClass('-editable', '-required');
    expect(display).toHaveAttribute('aria-label', 'Edit Subject <Original>');
    expect(cell.querySelector('original')).toBeNull();
    fixture.componentRef.setInput('presentation', { ...before, text: 'After', title: 'After' });
    fixture.detectChanges();
    expect(cell.querySelector('.inline-edit--display-field')).toBe(display);
    expect(display).toHaveTextContent('After');
    expect(cell).toHaveAttribute('data-row-header-name', 'After');
  });

  it('gives the editor an independent container and restores the Angular display after closing', () => {
    const editor = templateCellEditors.get(cell)!;
    const slot = editor.beginEdit();
    slot.innerHTML = '<input aria-label="Subject" value="Unsaved">';
    const input = within(cell).getByRole('textbox', { name: 'Subject' });
    fixture.componentRef.setInput('presentation', { ...before, text: 'Refreshed' });
    fixture.detectChanges();
    expect(within(cell).getByRole('textbox', { name: 'Subject' })).toBe(input);
    expect(input).toHaveValue('Unsaved');
    editor.endEdit();
    expect(within(cell).queryByRole('textbox')).toBeNull();
    expect(cell.querySelector('.inline-edit--display-field')).toHaveTextContent('Refreshed');
    const second = editor.beginEdit();
    second.innerHTML = '<input aria-label="Subject">';
    editor.endEdit();
    expect(cell.querySelector('.inline-edit--display-field')).toHaveTextContent('Refreshed');
  });
});

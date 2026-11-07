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

import { TestBed } from '@angular/core/testing';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { SimpleChange, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { fireEvent, waitFor, screen } from '@testing-library/dom';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { OpIconComponent } from '../icon/icon.component';
import { AutofocusDirective } from '../../directives/focus/autofocus.directive';
import { EditableToolbarTitleComponent, triggerEditingEvent } from './editable-toolbar-title.component';

describe('EditableToolbarTitleComponent loading title', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [CommonModule, FormsModule],
      declarations: [EditableToolbarTitleComponent, OpIconComponent, AutofocusDirective],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
      ],
    }).compileComponents();
  });

  it('does not flag the title as empty while it is still loading', () => {
    const fixture = TestBed.createComponent(EditableToolbarTitleComponent);
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('input')).not.toHaveClass('-error');
  });

  it('keeps the sizing shim hidden and mirrors the input title', () => {
    const fixture = TestBed.createComponent(EditableToolbarTitleComponent);
    fixture.componentRef.setInput('title', 'Original');
    fixture.detectChanges();
    const shim = fixture.nativeElement.querySelector('.editable-toolbar-title--input-shim') as HTMLElement;
    expect(shim).toHaveTextContent('Original');
    expect(getComputedStyle(shim).visibility).toBe('hidden');
  });

  it('disables in-flight input and renders a fixed small title when editing is unavailable', async () => {
    const fixture = TestBed.createComponent(EditableToolbarTitleComponent);
    fixture.componentRef.setInput('title', 'Original');
    fixture.componentRef.setInput('inFlight', true);
    fixture.detectChanges();
    await fixture.whenStable();
    expect(fixture.nativeElement.querySelector('input')).toBeDisabled();
    fixture.componentRef.setInput('editable', false);
    fixture.componentRef.setInput('smallHeader', true);
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('input')).toBeNull();
    expect(fixture.nativeElement.querySelector('.editable-toolbar-title--fixed')).toHaveTextContent('Original');
    expect(fixture.nativeElement.querySelector('.editable-toolbar-title--fixed')).toHaveClass('-small');
  });

  it('focuses and selects the title when initial focus is requested', async () => {
    const fixture = TestBed.createComponent(EditableToolbarTitleComponent);
    fixture.componentRef.setInput('title', 'Original');
    fixture.componentRef.setInput('initialFocus', true);
    fixture.detectChanges();
    await fixture.whenStable();
    const input = fixture.nativeElement.querySelector('input') as HTMLInputElement;
    await waitFor(() => expect(input).toHaveFocus());
    expect(input.selectionStart).toBe(0);
    expect(input.selectionEnd).toBe('Original'.length);
  });

  it('reports an empty submission when the title has not loaded', () => {
    const fixture = TestBed.createComponent(EditableToolbarTitleComponent);
    const component = fixture.componentInstance;
    component.ngOnChanges({ inputTitle: new SimpleChange(undefined, undefined, true) });
    const empty = vi.fn();
    const save = vi.fn();
    component.onEmptySubmit.subscribe(empty);
    component.onSave.subscribe(save);

    component.save(new Event('submit', { cancelable: true }));

    expect(empty).toHaveBeenCalledOnce();
    expect(save).not.toHaveBeenCalled();
  });

  it('resets an unloaded title without emitting a save', () => {
    const fixture = TestBed.createComponent(EditableToolbarTitleComponent);
    const component = fixture.componentInstance;
    component.selectedTitle = 'Draft';
    const save = vi.fn();
    const empty = vi.fn();
    component.onSave.subscribe(save);
    component.onEmptySubmit.subscribe(empty);

    component.reset();
    component.save(new Event('submit', { cancelable: true }));

    expect(component.inputTitle).toBeUndefined();
    expect(component.selectedTitle).toBe('');
    expect(save).not.toHaveBeenCalled();
    expect(empty).toHaveBeenCalledOnce();
  });

  it('keeps a loaded title editable and trims it on submission', () => {
    const fixture = TestBed.createComponent(EditableToolbarTitleComponent);
    const component = fixture.componentInstance;
    component.inputTitle = 'Original';
    component.ngOnChanges({ inputTitle: new SimpleChange(undefined, 'Original', true) });
    component.selectedTitle = '  Changed  ';
    const save = vi.fn();
    component.onSave.subscribe(save);

    component.save(new Event('submit', { cancelable: true }));

    expect(save).toHaveBeenCalledWith('Changed');
  });
});

describe('EditableToolbarTitleComponent', () => {
  async function render() {
    TestBed.configureTestingModule({
      declarations: [EditableToolbarTitleComponent, AutofocusDirective, OpIconComponent],
      imports: [CommonModule, FormsModule, OpTooltipDirective],
      schemas: [CUSTOM_ELEMENTS_SCHEMA],
    });
    const fixture = TestBed.createComponent(EditableToolbarTitleComponent);
    fixture.componentRef.setInput('title', 'Original title');
    await fixture.whenStable();
    return fixture;
  }

  it('restores the title on Escape and emits the trimmed title on Enter', async () => {
    const fixture = await render();
    const save = vi.fn<(title:string) => void>();
    fixture.componentInstance.onSave.subscribe(save);
    const input = screen.getByRole('textbox');

    fireEvent.input(input, { target: { value: 'Draft' } });
    await screen.findByText('Draft');
    fireEvent.keyDown(input, { key: 'Escape' });
    await waitFor(() => expect(input).toHaveValue('Original title'));
    expect(save).not.toHaveBeenCalled();

    fireEvent.input(input, { target: { value: ' New title ' } });
    fireEvent.keyDown(input, { key: 'Enter' });
    expect(save).toHaveBeenCalledExactlyOnceWith('New title');
    await waitFor(() => expect(input).toBeDisabled());
    await waitFor(() => expect(input).toBeEnabled());
    expect(input).toHaveValue('New title');
  });

  it('responds to a native edit request, then shows an updated read-only title', async () => {
    const fixture = await render();
    const host = fixture.nativeElement as HTMLElement;
    const input = screen.getByRole('textbox');

    fireEvent(host, new CustomEvent(triggerEditingEvent, { detail: 'Suggested title' }));
    await waitFor(() => expect(input).toHaveValue('Suggested title'));
    await waitFor(() => expect(input).toHaveFocus());

    fixture.componentRef.setInput('editable', false);
    fixture.componentRef.setInput('title', 'Read-only title');
    expect(await screen.findByText('Read-only title')).toBeVisible();
    expect(screen.queryByRole('textbox')).not.toBeInTheDocument();
  });
});

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
import { CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { fireEvent } from '@testing-library/dom';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { DeviceService } from 'core-app/core/browser/device.service';
import { OpBasicRangeDatePickerComponent } from './basic-range-date-picker.component';

describe('OpBasicRangeDatePickerComponent on mobile', () => {
  let component:OpBasicRangeDatePickerComponent;
  let fixture:ComponentFixture<OpBasicRangeDatePickerComponent>;
  let valueChange:ReturnType<typeof vi.fn>;

  const input = (id:string) => (fixture.nativeElement as HTMLElement).querySelector<HTMLInputElement>(`#${id}`)!;

  const enterDate = (id:'range-start'|'range-end', date:string) => {
    fireEvent.input(input(id), { target: { value: date } });
  };

  const render = async (value:string[] = []) => {
    fixture = TestBed.createComponent(OpBasicRangeDatePickerComponent);
    component = fixture.componentInstance;
    fixture.componentRef.setInput('id', 'range');
    fixture.componentRef.setInput('value', value);
    fixture.detectChanges();
    await fixture.whenStable();

    valueChange = vi.fn();
    component.valueChange.subscribe(valueChange);
    vi.useFakeTimers();
  };

  beforeEach(async () => {
    await TestBed
      .configureTestingModule({
        declarations: [OpBasicRangeDatePickerComponent],
        imports: [FormsModule],
        providers: [
          { provide: I18nService, useValue: { t: (key:string) => key } },
          { provide: TimezoneService, useValue: {} },
          { provide: DeviceService, useValue: { isMobile: true } },
        ],
        schemas: [CUSTOM_ELEMENTS_SCHEMA],
      })
      .compileComponents();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('emits the range once when start and end are entered in quick succession', async () => {
    await render();

    enterDate('range-start', '2025-01-07');
    enterDate('range-end', '2025-01-08');
    vi.advanceTimersByTime(20);

    expect(component.value).toEqual(['2025-01-07', '2025-01-08']);
    expect(valueChange).toHaveBeenCalledTimes(1);
    expect(valueChange).toHaveBeenCalledWith(['2025-01-07', '2025-01-08']);
  });

  it('emits the range once when end is entered before start', async () => {
    await render();

    enterDate('range-end', '2025-01-08');
    enterDate('range-start', '2025-01-07');
    vi.advanceTimersByTime(20);

    expect(component.value).toEqual(['2025-01-07', '2025-01-08']);
    expect(valueChange).toHaveBeenCalledTimes(1);
    expect(valueChange).toHaveBeenCalledWith(['2025-01-07', '2025-01-08']);
  });

  it('keeps the other date when replacing one end of an existing range', async () => {
    await render(['2025-01-01', '2025-01-31']);

    enterDate('range-end', '2025-01-15');
    vi.advanceTimersByTime(20);

    expect(valueChange).toHaveBeenCalledTimes(1);
    expect(valueChange).toHaveBeenCalledWith(['2025-01-01', '2025-01-15']);
  });

  it('emits each date separately when entered outside the debounce window', async () => {
    await render();

    enterDate('range-start', '2025-01-07');
    vi.advanceTimersByTime(20);
    enterDate('range-end', '2025-01-08');
    vi.advanceTimersByTime(20);

    expect(valueChange).toHaveBeenCalledTimes(2);
    expect(valueChange).toHaveBeenNthCalledWith(1, ['2025-01-07', '']);
    expect(valueChange).toHaveBeenNthCalledWith(2, ['2025-01-07', '2025-01-08']);
  });

  it('serializes the range into the hidden field', async () => {
    await render();

    enterDate('range-start', '2025-01-07');
    enterDate('range-end', '2025-01-08');
    vi.advanceTimersByTime(20);

    expect(input('range')).toHaveAttribute('data-value', '2025-01-07 - 2025-01-08');
  });
});

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

import { CommonModule } from '@angular/common';
import { provideHttpClient } from '@angular/common/http';
import { TestBed } from '@angular/core/testing';
import { FormsModule } from '@angular/forms';
import { By } from '@angular/platform-browser';
import { of, Subject } from 'rxjs';
import moment from 'moment-timezone';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { BannersService } from 'core-app/core/enterprise/banners.service';
import { DeviceService } from 'core-app/core/browser/device.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { QueryOperatorResource } from 'core-app/features/hal/resources/query-operator-resource';
import { SpotFormFieldComponent } from 'core-app/spot/components/form-field/form-field.component';
import { SpotTooltipComponent } from 'core-app/spot/components/tooltip/tooltip.component';
import { EnterpriseBannerFrameComponent } from 'core-app/features/enterprise/enterprise-banner-frame.component';
import { OpDatePickerSheetComponent } from 'core-app/shared/components/datepicker/sheet/date-picker-sheet.component';
import { OpContentLoaderComponent } from 'core-app/shared/components/op-content-loader/op-content-loader.component';
import { ContentLoaderModule } from '@ngneat/content-loader';
import { AutofocusDirective } from 'core-app/shared/directives/focus/autofocus.directive';
import { FocusHelperService } from 'core-app/shared/directives/focus/focus-helper';
import { AlertIconComponent } from '@openproject/octicons-angular';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { OpBasicSingleDatePickerComponent } from 'core-app/shared/components/datepicker/basic-single-date-picker/basic-single-date-picker.component';
import { OpBasicSingleDatetimePickerComponent } from 'core-app/shared/components/datepicker/basic-single-datetime-picker/basic-single-datetime-picker.component';
import { FilterDateTimeValueComponent } from './filter-date-time-value/filter-date-time-value.component';
import { FilterDateTimesValueComponent } from './filter-date-times-value/filter-date-times-value.component';
import { FilterDateValueComponent } from './filter-date-value/filter-date-value.component';
import { OpBaselineComponent } from '../wp-baseline/baseline/baseline.component';
import { OpBaselineLoadingComponent } from '../wp-baseline/baseline-loading/baseline-loading.component';

describe('Filter and baseline template contracts', () => {
  const update = vi.fn();
  const pristine = new Subject<string[]>();

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [CommonModule, FormsModule, ContentLoaderModule, AlertIconComponent],
      declarations: [FilterDateTimeValueComponent, FilterDateTimesValueComponent, FilterDateValueComponent,
        OpBaselineComponent, OpBaselineLoadingComponent, SpotFormFieldComponent, SpotTooltipComponent,
        EnterpriseBannerFrameComponent, OpDatePickerSheetComponent, OpContentLoaderComponent,
        OpBasicSingleDatePickerComponent, OpBasicSingleDatetimePickerComponent, AutofocusDirective],
      providers: [
        provideHttpClient(),
        TimezoneService, PathHelperService, HalResourceService, FocusHelperService,
        { provide: I18nService, useValue: { t: (key:string) => {
          switch (key) {
            case 'date.abbr_day_names': return moment.weekdaysShort();
            case 'date.day_names': return moment.weekdays();
            case 'date.abbr_month_names': return ['', ...moment.monthsShort()];
            case 'date.month_names': return ['', ...moment.months()];
            default: return key;
          }
        } } },
        { provide: DeviceService, useValue: { isMobile: false } },
        { provide: ConfigurationService, useValue: {
          isTimezoneSet: () => true, timezone: () => 'Etc/UTC',
          dateFormatPresent: () => true, dateFormat: () => 'YYYY-MM-DD',
          timeFormatPresent: () => true, timeFormat: () => 'HH:mm', startOfWeek: () => 1,
        } },
        { provide: WeekdayService, useValue: { loadWeekdays: () => of([]), isNonWorkingDay: () => false } },
        { provide: DayResourceService, useValue: { isNonWorkingDay$: () => Promise.resolve(false) } },
        { provide: BannersService, useValue: { allowsTo: () => true, showBannerFor: () => false, trialling: () => false } },
        { provide: WorkPackageViewBaselineService, useValue: {
          nonWorkingDays$: of([]), pristine$: () => pristine, isActive: () => false,
          yesterdayDate: () => '2026-10-28', update, disable: vi.fn(),
        } },
      ],
    }).compileComponents();
    update.mockClear();
  });

  afterEach(() => vi.restoreAllMocks());

  function filter(values:string[], operator = '=') {
    const resource = TestBed.inject(HalResourceService).createHalResourceOfClass(QueryFilterInstanceResource, {
      _type: 'QueryFilterInstance', values,
      _links: {
        filter: { href: '/api/v3/queries/filters/createdAt', title: 'Created at' },
        operator: { href: `/api/v3/queries/operators/${operator}` },
      },
    });
    resource.operator = TestBed.inject(HalResourceService).createHalResourceOfClass(QueryOperatorResource, {
      _links: { self: { href: `/api/v3/queries/operators/${operator}` } },
    });
    return resource;
  }

  it('keeps datetime and date filter controls required and preserves their API values', async () => {
    const fixture = TestBed.createComponent(FilterDateTimeValueComponent);
    fixture.componentRef.setInput('filter', filter(['2026-10-28T08:00:00Z'], '>d'));
    fixture.detectChanges();
    await fixture.whenStable();
    const host = fixture.nativeElement as HTMLElement;
    expect(host.querySelector<HTMLInputElement>('input.spot-input')!.required).toBe(true);
    const datetime = fixture.debugElement.query(By.directive(OpBasicSingleDatetimePickerComponent)).componentInstance as OpBasicSingleDatetimePickerComponent;
    datetime.valueChange.emit('2026-10-29T09:00:00Z');
    expect(fixture.componentInstance.filter.values).toEqual(['2026-10-29T09:00:00Z']);

    fixture.componentRef.setInput('filter', filter(['2026-10-28T08:00:00Z'], '='));
    fixture.detectChanges();
    await fixture.whenStable();
    expect(host.querySelector<HTMLInputElement>('input.spot-input')!.required).toBe(true);
    const date = fixture.debugElement.query(By.directive(OpBasicSingleDatePickerComponent)).componentInstance as OpBasicSingleDatePickerComponent;
    date.valueChange.emit('2026-10-29');
    expect(fixture.componentInstance.filter.values).toEqual(['2026-10-29T00:00:00Z']);
  });

  it('requires the datetime range start and keeps each boundary in order', async () => {
    const fixture = TestBed.createComponent(FilterDateTimesValueComponent);
    fixture.componentRef.setInput('filter', filter(['2026-10-28T08:00:00Z', '2026-10-29T08:00:00Z']));
    fixture.detectChanges();
    await fixture.whenStable();
    const inputs = (fixture.nativeElement as HTMLElement).querySelectorAll<HTMLInputElement>('input.spot-input');
    expect(inputs[0].required).toBe(true);
    expect(inputs[2].required).toBe(false);
    const pickers = fixture.debugElement.queryAll(By.directive(OpBasicSingleDatetimePickerComponent));
    (pickers[0].componentInstance as OpBasicSingleDatetimePickerComponent).valueChange.emit('2026-10-27T08:00:00Z');
    (pickers[1].componentInstance as OpBasicSingleDatetimePickerComponent).valueChange.emit('2026-10-30T08:00:00Z');
    expect(fixture.componentInstance.filter.values).toEqual(['2026-10-27T08:00:00Z', '2026-10-30T08:00:00Z']);
  });

  it('renders missing dates empty and ignores invalid date changes', async () => {
    const fixture = TestBed.createComponent(FilterDateValueComponent);
    fixture.componentRef.setInput('filter', filter([]));
    fixture.detectChanges();
    await fixture.whenStable();
    expect((fixture.nativeElement as HTMLElement).querySelector<HTMLInputElement>('input')!.value).toBe('');
    const picker = fixture.debugElement.query(By.directive(OpBasicSingleDatePickerComponent)).componentInstance as OpBasicSingleDatePickerComponent;
    picker.valueChange.emit('invalid');
    expect(fixture.componentInstance.filter.values).toEqual([]);
    picker.valueChange.emit('2026-10-29');
    expect(fixture.componentInstance.filter.values).toEqual(['2026-10-29']);
  });

  function baseline() {
    const fixture = TestBed.createComponent(OpBaselineComponent);
    fixture.componentRef.setInput('showActionBar', true);
    fixture.detectChanges();
    const host = fixture.nativeElement as HTMLElement;
    const select = host.querySelector<HTMLSelectElement>('select')!;
    return { fixture, host, select };
  }

  it('selects none again when a chosen baseline is cleared', () => {
    const { fixture, host, select } = baseline();
    select.value = 'oneDayAgo';
    select.dispatchEvent(new Event('change'));
    fixture.detectChanges();
    expect(fixture.componentInstance.selectedDates).toEqual(['2026-10-28']);
    host.querySelector<HTMLButtonElement>('button[type="button"]')!.click();
    fixture.detectChanges();
    expect(select.value).toBe('');
    expect(select.options[0].selected).toBe(true);
    fixture.componentInstance.onSave();
    expect(update).toHaveBeenCalledExactlyOnceWith(['PT0S']);
  });

  it('submits the selected baseline and allows an absent selection', () => {
    const { fixture, select } = baseline();
    select.value = 'oneDayAgo';
    select.dispatchEvent(new Event('change'));
    fixture.detectChanges();
    fixture.componentInstance.onSave();
    expect(update).toHaveBeenLastCalledWith(['oneDayAgo@08:00+00:00', 'PT0S']);
    select.value = '';
    select.dispatchEvent(new Event('change'));
    fixture.detectChanges();
    expect(fixture.componentInstance.selectedDates).toEqual(['', '']);
    fixture.componentInstance.onSave();
    expect(update).toHaveBeenLastCalledWith(['PT0S']);
    fixture.componentInstance.dateChange(['invalid']);
    expect(fixture.componentInstance.selectedDates).toEqual(['', '']);
  });
  it('preserves single and ranged date/time input changes and ignores invalid dates', async () => {
    const { fixture, host, select } = baseline();
    select.value = 'aSpecificDate';
    select.dispatchEvent(new Event('change'));
    fixture.detectChanges();
    await fixture.whenStable();
    const date = host.querySelector<HTMLInputElement>('input[name="op-baseline-date"]')!;
    date.value = 'invalid';
    date.dispatchEvent(new Event('input'));
    expect(fixture.componentInstance.selectedDates).toEqual(['', '']);
    date.value = '2026-10-27';
    date.dispatchEvent(new Event('input'));
    const time = host.querySelector<HTMLInputElement>('input[name="op-baseline-time"]')!;
    time.value = '09:30';
    time.dispatchEvent(new Event('change'));
    fixture.componentInstance.onSave();
    expect(update).toHaveBeenLastCalledWith(['2026-10-27T09:30+00:00', 'PT0S']);

    select.value = 'betweenTwoSpecificDates';
    select.dispatchEvent(new Event('change'));
    fixture.detectChanges();
    await fixture.whenStable();
    for (const [name, value, event] of [
      ['op-baseline-from-date', '2026-10-26', 'input'],
      ['op-baseline-to-date', '2026-10-28', 'input'],
      ['op-baseline-from-time', '10:30', 'change'],
      ['op-baseline-to-time', '11:30', 'change'],
    ]) {
      const input = host.querySelector<HTMLInputElement>(`input[name="${name}"]`)!;
      input.value = value;
      input.dispatchEvent(new Event(event));
    }
    fixture.componentInstance.onSave();
    expect(update).toHaveBeenLastCalledWith(['2026-10-26T10:30+00:00', '2026-10-28T11:30+00:00']);
    const sheet = fixture.debugElement.query(By.directive(OpDatePickerSheetComponent)).componentInstance as OpDatePickerSheetComponent;
    sheet.datePickerInstance.destroy();
  });

  it('renders the loading state before the non-working-day collection arrives', () => {
    TestBed.overrideProvider(WorkPackageViewBaselineService, { useValue: {
      nonWorkingDays$: new Subject(), pristine$: () => pristine, isActive: () => false,
    } });
    const fixture = TestBed.createComponent(OpBaselineComponent);
    fixture.detectChanges();
    const host = fixture.nativeElement as HTMLElement;
    expect(host.querySelector('form')).toBeNull();
    expect(host.querySelector('op-baseline-loading')).not.toBeNull();
  });

  it('initializes the selected baseline from the existing timestamps', () => {
    TestBed.overrideProvider(WorkPackageViewBaselineService, { useValue: {
      nonWorkingDays$: of([]), pristine$: () => pristine, isActive: () => true,
      current: ['oneDayAgo@09:45+01:00', 'PT0S'], yesterdayDate: () => '2026-10-28', update,
    } });
    const { fixture, host, select } = baseline();
    expect(select.value).toBe('oneDayAgo');
    expect(fixture.componentInstance.selectedDates).toEqual(['2026-10-28']);
    expect(host.querySelector<HTMLInputElement>('input[type="time"]')!.value).toBe('09:45');
    fixture.componentInstance.onSave();
    expect(update).toHaveBeenCalledExactlyOnceWith(['oneDayAgo@09:45+01:00', 'PT0S']);
  });

});

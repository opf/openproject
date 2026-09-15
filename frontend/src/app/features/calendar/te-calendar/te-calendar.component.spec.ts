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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { NO_ERRORS_SCHEMA } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { FullCalendarModule } from '@fullcalendar/angular';
import { StateService } from '@uirouter/core';
import moment from 'moment';
import { of } from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { BrowserDetector } from 'core-app/core/browser/browser-detector.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { States } from 'core-app/core/states/states.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { OpCalendarService } from 'core-app/features/calendar/op-calendar.service';
import { ColorsService } from 'core-app/shared/components/colors/colors.service';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { TimeEntryCalendarComponent } from './te-calendar.component';

describe('TimeEntryCalendarComponent', () => {
  let fixture:ComponentFixture<TimeEntryCalendarComponent>;
  let element:HTMLElement;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [TimeEntryCalendarComponent],
      imports: [FullCalendarModule],
      schemas: [NO_ERRORS_SCHEMA],
      providers: [
        { provide: I18nService, useValue: { locale: 'en', t: (key:string) => key, toNumber: (value:number) => `${value}` } },
        { provide: ConfigurationService, useValue: { startOfWeek: () => 1, isTimezoneSet: () => false, timezone: () => 'UTC', dateFormatPresent: () => false } },
        { provide: WeekdayService, useValue: { loadWeekdays: () => of([]), isNonWorkingDay: () => false } },
        { provide: DayResourceService, useValue: { requireNonWorkingYears$: () => of([]) } },
        { provide: ApiV3Service, useValue: { time_entries: { list: () => of({ elements: [], createTimeEntry: undefined }) } } },
        {
          provide: TimezoneService,
          useValue: {
            toHours: () => 1,
            formattedDuration: () => '1h',
            formattedISODate: (date:Date) => moment(date).format('YYYY-MM-DD'),
          },
        },
        { provide: BrowserDetector, useValue: { isMobile: false } },
        { provide: States, useValue: {} },
        { provide: StateService, useValue: {} },
        { provide: HalResourceNotificationService, useValue: {} },
        { provide: SchemaCacheService, useValue: {} },
        { provide: ColorsService, useValue: {} },
      ],
    })
      .overrideComponent(TimeEntryCalendarComponent, {
        set: {
          providers: [
            OpCalendarService,
            { provide: HalResourceEditingService, useValue: {} },
            { provide: TurboRequestsService, useValue: {} },
            { provide: PathHelperService, useValue: {} },
          ],
        },
      })
      .compileComponents();

    fixture = TestBed.createComponent(TimeEntryCalendarComponent);
    fixture.componentRef.setInput('projectIdentifier', 'demo');
    fixture.detectChanges();
    element = fixture.nativeElement as HTMLElement;
  });

  const renderWeek = async (displayedDays:boolean[]) => {
    fixture.componentRef.setInput('displayedDays', displayedDays);
    await vi.waitUntil(() => {
      fixture.detectChanges();
      return element.querySelector('.fc-col-header-cell') !== null;
    });
  };

  it('renders the calendar container', () => {
    expect(element.querySelector('.te-calendar--container')).not.toBeNull();
    expect(element.querySelector('full-calendar')).toBeNull();
  });

  it('renders a week grid once the displayed days are known', async () => {
    await renderWeek([true, true, true, true, true, true, true]);
    expect(element.querySelectorAll('.fc-col-header-cell.fc-day')).toHaveLength(7);
  });

  it('hides the days that are not displayed', async () => {
    await renderWeek([true, true, true, true, true, false, false]);
    expect(element.querySelectorAll('.fc-col-header-cell.fc-day')).toHaveLength(5);
  });

  it('closes an open entry popover when the window is resized', () => {
    const popover = document.createElement('div');
    popover.className = 'te-calendar--popover';
    popover.setAttribute('popover', 'manual');
    element.append(popover);
    popover.showPopover();

    window.dispatchEvent(new Event('resize'));

    expect(popover.matches(':popover-open')).toBe(false);
  });
});

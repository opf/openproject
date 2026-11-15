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
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { OpDateTimeComponent } from './op-date-time.component';

describe('OpDateTimeComponent', () => {
  it('renders the formatted date and time', async () => {
    const formattedDatetimeComponents = vi.fn<TimezoneService['formattedDatetimeComponents']>().mockReturnValue(['2026-11-07', '12:30']);
    TestBed.configureTestingModule({
      declarations: [OpDateTimeComponent],
      providers: [{ provide: TimezoneService, useValue: { formattedDatetimeComponents } }],
    });
    const fixture = TestBed.createComponent(OpDateTimeComponent);
    fixture.componentRef.setInput('dateTimeValue', '2026-11-07T12:30:00Z');
    await fixture.whenStable();
    expect(formattedDatetimeComponents).toHaveBeenCalledWith('2026-11-07T12:30:00Z');
    expect(fixture.nativeElement as HTMLElement).toHaveTextContent('2026-11-07 12:30');
  });
});

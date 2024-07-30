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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

/* jshint expr: true */

import { TestBed } from '@angular/core/testing';
import { HttpClientModule } from '@angular/common/http';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';

describe('TimezoneService', () => {
  const TIME = '2013-02-08T09:30:26';
  const DATE = '2013-02-08';
  let timezoneService:TimezoneService;

  const compile = (timezone?:string) => {
    const ConfigurationServiceStub = {
      isTimezoneSet: () => !!timezone,
      timezone: () => timezone,
    };

    TestBed.configureTestingModule({
      imports: [
        HttpClientModule,
      ],
      providers: [
        { provide: I18nService, useValue: {} },
        { provide: ConfigurationService, useValue: ConfigurationServiceStub },
        PathHelperService,
        TimezoneService,
      ],
    });

    timezoneService = TestBed.inject(TimezoneService);
  };

  describe('without time zone set', () => {
    beforeEach(() => {
      compile();
    });

    describe('#parseDatetime', () => {
      it('is UTC', () => {
        const time = timezoneService.parseDatetime(TIME);
        expect(time.utcOffset()).toEqual(0);
        expect(time.format('HH:mm')).toEqual('09:30');
      });

      it('has no time information', () => {
        const time = timezoneService.parseDate(DATE);
        expect(time.format('HH:mm')).toEqual('00:00');
      });
    });
  });

  describe('with time zone set', () => {
    beforeEach(() => {
      compile('America/Vancouver');
    });

    describe('Non-UTC timezone', () => {
      it('is in the given timezone', () => {
        const date = timezoneService.parseDatetime(TIME);
        expect(date.format('HH:mm')).toEqual('01:30');
      });

      it('has local time zone', () => {
        expect(timezoneService.configurationService.timezone()).toEqual('America/Vancouver');
      });
    });
  });
});

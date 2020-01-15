//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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
// See docs/COPYRIGHT.rdoc for more details.
//++

/*jshint expr: true*/

import {TestBed} from '@angular/core/testing';
import {HttpClientModule} from '@angular/common/http';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {ConfigurationService} from 'core-app/modules/common/config/configuration.service';
import {TimezoneService} from 'core-components/datetime/timezone.service';

describe('TimezoneService', function () {

  let TIME = '2013-02-08T09:30:26';
  let DATE = '2013-02-08';
  let timezoneService:TimezoneService;

  let compile = (timezone?:string) => {
    let ConfigurationServiceStub = {
      isTimezoneSet: () => !!timezone,
      timezone: () => timezone
    };

    TestBed.configureTestingModule({
      imports: [
        HttpClientModule
      ],
      providers: [
        { provide: I18nService, useValue: {} },
        { provide: ConfigurationService, useValue: ConfigurationServiceStub },
        PathHelperService,
        TimezoneService,
      ]
    });

    timezoneService = TestBed.get(TimezoneService);
  };

  describe('without time zone set', function () {
    beforeEach(() => {
      compile();
    });

    describe('#parseDatetime', function () {
      it('is UTC', function () {
        var time = timezoneService.parseDatetime(TIME);
        expect(time.utcOffset()).toEqual(0);
        expect(time.format('HH:mm')).toEqual('09:30');
      });

      it('has no time information', function () {
        var time = timezoneService.parseDate(DATE);
        expect(time.format('HH:mm')).toEqual('00:00');
      });
    });
  });

  describe('with time zone set', function () {
    beforeEach(() => {
      compile('America/Vancouver');
    });

    describe('Non-UTC timezone', function () {

      it('is in the given timezone' , function () {
        let date = timezoneService.parseDatetime(TIME);
        expect(date.format('HH:mm')).toEqual('01:30');
      });

      it('has local time zone', function () {
        expect(timezoneService.ConfigurationService.timezone()).toEqual('America/Vancouver');
      });
    });
  });
});

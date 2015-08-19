//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
//++

/*jshint expr: true*/

describe('TimezoneService', function() {

  var TIME = '2013-02-08T09:30:26';
  var DATE = '2013-02-08';
  var TimezoneService;
  var ConfigurationService;
  var isTimezoneSetStub;
  var timezoneStub;

  beforeEach(module('openproject.services', 'openproject.config'));

  beforeEach(inject(function(_TimezoneService_, _ConfigurationService_){
    TimezoneService = _TimezoneService_;
    ConfigurationService = _ConfigurationService_;

    isTimezoneSetStub = sinon.stub(ConfigurationService, 'isTimezoneSet');
    timezoneStub = sinon.stub(ConfigurationService, 'timezone');
  }));

  describe('#parseDatetime', function() {
    it('is UTC', function() {
      var time = TimezoneService.parseDatetime(TIME);
      expect(time.zone()).to.equal(0);
      expect(time.format('HH:mm')).to.eq('09:30');
    });

    describe('Non-UTC timezone', function() {
      var timezone = 'America/Vancouver';
      var date;

      beforeEach(function() {
        isTimezoneSetStub.returns(true);
        timezoneStub.returns(timezone);

        date = TimezoneService.parseDatetime(TIME);
      });

      it('is ' + timezone, function() {
        expect(date.format('HH:mm')).to.eq('01:30');
      });
    });
  });

  describe('#parseDate', function() {
    it('has local time zone', function() {
      var time = TimezoneService.parseDate(DATE);
      expect(time.zone()).to.equal(time.clone().local().zone());
    });

    it('has no time information', function() {
      var time = TimezoneService.parseDate(DATE);
      expect(time.format('HH:mm')).to.eq('00:00');
    });
  });
});

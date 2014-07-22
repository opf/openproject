//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

  var TIME = '05/19/2014 11:49 AM';
  var TimezoneService;
  var ConfigurationService;
  var isTimezoneSetStub;
  var timezone;

  beforeEach(module('openproject.services', 'openproject.config'));

  beforeEach(inject(function(_TimezoneService_, _ConfigurationService_){
    TimezoneService = _TimezoneService_;
    ConfigurationService = _ConfigurationService_;

    isTimezoneSetStub = sinon.stub(ConfigurationService, "isTimezoneSet");
    timezoneStub = sinon.stub(ConfigurationService, "timezone");
  }));

  describe('#parseDate', function() {
    it('is UTC', function() {
      expect(TimezoneService.parseDate(TIME).zone()).to.equal(0);
    });

    describe('Non-UTC timezone', function() {
      var timezone = 'Europe/Berlin';
      var momentStub;
      var dateStub;

      beforeEach(function() {
        isTimezoneSetStub.returns(true);
        timezoneStub.returns(timezone);

        momentStub = sinon.stub(moment, "utc");
        dateStub = sinon.stub();

        momentStub.returns(dateStub);
        dateStub.tz = sinon.spy();

        TimezoneService.parseDate(TIME);
      });

      afterEach(function() {
        momentStub.restore();
      });

      it('is Europe/Berlin', function() {
        expect(dateStub.tz.calledWithExactly(timezone)).to.be.true;
      });
    });
  });
});

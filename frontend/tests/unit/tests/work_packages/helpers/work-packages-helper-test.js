//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
//++

/*jshint expr: true*/

describe('Work packages helper', function() {
  var WorkPackagesHelper, TimezoneService;

  beforeEach(angular.mock.module('openproject.helpers', 'openproject.services'));

  beforeEach(inject(function(_WorkPackagesHelper_, _TimezoneService_) {
    WorkPackagesHelper = _WorkPackagesHelper_;
    TimezoneService = _TimezoneService_;
  }));

  describe('getRowObjectContent', function() {
    var getRowObjectContent;

    beforeEach(function() {
      getRowObjectContent = WorkPackagesHelper.getRowObjectContent;
    });

    describe('with an object', function() {
      it('should return object name', function() {
        var object = {
          assignee: { name: 'user1', subject: 'not this' }
        };

        expect(getRowObjectContent(object, 'assignee')).to.equal('user1');
      });

      it('should return object subject', function() {
        var object = {
          assignee: { subject: 'subject1' }
        };

        expect(getRowObjectContent(object, 'assignee')).to.equal('subject1');
      });

      it('should handle null and emtpy objects', function() {
        expect(getRowObjectContent({ assignee: {}}, 'assignee')).to.equal('');
        expect(getRowObjectContent({}, 'assignee')).to.equal('');
      });
    });

    describe('with a number', function() {
      it('should return the number', function() {
        expect(getRowObjectContent({ number_field: 10 }, 'number_field')).to.equal(10);
      });

      it('should handle missing data', function() {
        expect(getRowObjectContent({}, 'number_field')).to.equal('');
      });
    });

    describe('with an object having a value', function() {
      it('returns the value', function() {
        var object = {
          myObject: { value: 'the value' }
        };

        expect(getRowObjectContent(object, 'myObject')).to.equal('the value');
      });
    });
  });

  describe('formatValue', function() {

    it('should display a currency value', function() {
      expect(WorkPackagesHelper.formatValue(99,     'currency')).to.equal("EUR 99.00");
      expect(WorkPackagesHelper.formatValue(20.99,  'currency')).to.equal("EUR 20.99");
      expect(WorkPackagesHelper.formatValue("20",   'currency')).to.equal("EUR 20.00");
    });

    it('should display empty strings for empty/undefined dates', function() {
      expect(WorkPackagesHelper.formatValue("", 'datetime')).to.equal("");
      expect(WorkPackagesHelper.formatValue(undefined, 'datetime')).to.equal("");
      expect(WorkPackagesHelper.formatValue(null, 'datetime')).to.equal("");
      expect(WorkPackagesHelper.formatValue("", 'date')).to.equal("");
      expect(WorkPackagesHelper.formatValue(undefined, 'date')).to.equal("");
      expect(WorkPackagesHelper.formatValue(null, 'date')).to.equal("");
    });

    it('should display parsed dates and datetimes', function(){
      var datetime = '2014-01-01T00:00:00';
      var localDatetime = TimezoneService.parseDatetime(datetime);
      var expectedDate = TimezoneService.formattedDate(localDatetime);
      var expectedDatetime= TimezoneService.formattedDatetime(localDatetime);
      expect(WorkPackagesHelper.formatValue(datetime, 'date')).to.equal(expectedDate);
      expect(WorkPackagesHelper.formatValue(datetime, 'datetime')).to.equal(expectedDatetime);
    });
  });

});

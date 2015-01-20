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

describe('Work packages helper', function() {
  var WorkPackagesHelper;

  beforeEach(module('openproject.helpers', 'openproject.services'));
  beforeEach(module('openproject.templates', function($provide) {
    var configurationService = {};

    configurationService.isTimezoneSet = sinon.stub();
    configurationService.dateFormatPresent = sinon.stub();
    configurationService.timeFormatPresent = sinon.stub();

    $provide.constant('ConfigurationService', configurationService);
  }));
  beforeEach(inject(function(_WorkPackagesHelper_) {
    WorkPackagesHelper = _WorkPackagesHelper_;
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

    describe('with a custom field', function() {
      it('should return type string custom field', function() {
        var object = {
          custom_values: [ { custom_field_id: 1, value: 'custom field string'} ]
        };

        expect(getRowObjectContent(object, 'cf_1')).to.equal('custom field string');
      });

      it('should return type object custom field', function() {
        var object = {
          custom_values: [ { custom_field_id: 1, value: { name: 'name1' }} ]
        };

        expect(getRowObjectContent(object, 'cf_1')).to.equal('name1');
      });

      it('should handle missing data', function() {
        var object = {
          custom_values: [ { custom_field_id: 1, value: 'whatever'} ]
        };

        expect(getRowObjectContent(object, 'cf_2')).to.equal('');
        expect(getRowObjectContent({}, 'cf_1')).to.equal('');
      });

    });

  });

  describe('formatValue', function() {
    var formatValue;

    beforeEach(function() {
      formatValue = WorkPackagesHelper.formatValue;
    });

    it('should display a currency value', function() {
      expect(formatValue(99,     'currency')).to.equal("EUR 99.00");
      expect(formatValue(20.99,  'currency')).to.equal("EUR 20.99");
      expect(formatValue("20",   'currency')).to.equal("EUR 20.00");
    });

    it('should display empty strings for empty/undefined dates', function() {
      expect(formatValue("", 'datetime')).to.equal("");
      expect(formatValue(undefined, 'datetime')).to.equal("");
      expect(formatValue(null, 'datetime')).to.equal("");
      expect(formatValue("", 'date')).to.equal("");
      expect(formatValue(undefined, 'date')).to.equal("");
      expect(formatValue(null, 'date')).to.equal("");
    });

    var TIME = '2014-01-01T00:00:00';
    var EXPECTED_DATE = '01/01/2014';
    var EXPECTED_DATETIME = '01/01/2014 12:00 AM';

    it('should display parsed dates and datetimes', function(){
      expect(formatValue(TIME, 'date')).to.equal(EXPECTED_DATE);
      expect(formatValue(TIME, 'datetime')).to.equal(EXPECTED_DATETIME);
    });
  });

});

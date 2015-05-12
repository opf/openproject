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

/* jshint ignore:start */

var expect = require('../../../spec_helper.js').expect,
    detailsPaneHelper = require('./details-pane-helper.js'),
    datepicker = detailsPaneHelper.datepicker,
    elements = detailsPaneHelper.elements;


describe('details pane', function() {
  var dateRangePicker;
  describe('date range picker', function() {
    beforeEach(function() {
      detailsPaneHelper.loadPane(819, 'overview');
      dateRangePicker = element(by.css('.inplace-edit.attribute-date'));
    });

    context('read value', function() {
      it('is editable', function() {
        expect(dateRangePicker.$('.inplace-edit--write').isPresent()).to.eventually.be.true;
      });

      it('should be present on page', function(){
        expect(dateRangePicker.isDisplayed()).to.eventually.be.true;
      });

      it('shows date range', function() {
        expect(dateRangePicker.getText()).to.eventually.equal('02/17/2015\n  -  \n04/29/2015');
      });
    });

    context('write value', function() {
      var startDate, endDate,
          startDateDatepicker, endDateDatepicker;

      beforeEach(function() {
        startDate = dateRangePicker.$('.inplace-edit--date-range-start-date');
        endDate = dateRangePicker.$('.inplace-edit--date-range-end-date');
        startDateDatepicker = dateRangePicker.$('.inplace-edit--date-range-start-date-picker');
        endDateDatepicker = dateRangePicker.$('.inplace-edit--date-range-end-date-picker');
      });

      beforeEach(function() {
        dateRangePicker.$('.inplace-edit--read-value').click();
      });

      it('opens start date calendar', function() {
        expect(startDateDatepicker.isDisplayed()).to.eventually.be.true;
      });

      it('opens end date calendar only', function() {
        endDate.click();
        expect(endDateDatepicker.isDisplayed()).to.eventually.be.true;
      });

      it('start date calendar doesn\'t contain buttons', function() {
        var locator = by.css('.inplace-edit--date-range-start-date-picker .ui-datepicker-buttonpane > *');
        elements.count(locator, 0);
      });

      it('end date calendar doesn\'t contain buttons', function() {
        endDate.click();
        var locator = by.css('.inplace-edit--date-range-end-date-picker .ui-datepicker-buttonpane > *');
        elements.count(locator, 0);
      });

      describe('start date', function() {
        it('contains week days displayed', function() {
          var locator = by.css('.inplace-edit--date-range-start-date-picker thead th:not(.ui-datepicker-week-col)');
          expect(startDateDatepicker.$('thead .ui-datepicker-week-col').isPresent()).to.eventually.be.true;
          elements.count(locator, 7);
        });

        it('contains year week numbers displayed', function() {
          var locator = by.css('.inplace-edit--date-range-start-date-picker tbody tr .ui-datepicker-week-col');
          expect(startDateDatepicker.$('tbody .ui-datepicker-week-col').isPresent()).to.eventually.be.true;
          elements.notCount(locator, 0);
        });
      });

      describe('end date', function() {
        beforeEach(function(){
          endDate.click();
        });

        it('contains week days displayed', function() {
          var locator = by.css('.inplace-edit--date-range-end-date-picker thead th:not(.ui-datepicker-week-col)');
          expect(endDateDatepicker.$('thead .ui-datepicker-week-col').isPresent()).to.eventually.be.true;
          elements.count(locator, 7);
        });

        it('contains year week numbers displayed', function() {
          var locator = by.css('.inplace-edit--date-range-end-date-picker tbody tr .ui-datepicker-week-col');
          expect(endDateDatepicker.$('tbody .ui-datepicker-week-col').isPresent()).to.eventually.be.true;
          elements.notCount(locator, 0);
        });
      });

      it('shows date range in input', function() {
        datepicker.expectedDate(startDate, '10/23/2014');
        datepicker.expectedDate(endDate, '12/27/2014');
      });

      describe('validation', function() {
        it('validates valid start date', function() {
          datepicker.validation(startDate, '10/24/2014', '10/24/2014');
        });

        it('validates valid end date', function() {
          datepicker.validation(endDate, '11/27/2014', '11/27/2014');
        });

        it('doesn\'t validate invalid start date', function() {
          datepicker.validation(startDate, '13/24/2014', '10/23/2014');
        });

        it('doesn\'t validate invalid end date', function() {
          datepicker.validation(endDate, '11/40/2014', '12/27/2014');
        });

        it('validates empty start date', function() {
          datepicker.validation(startDate, '', 'no start date');
        });

        it('validates empty end date', function() {
          datepicker.validation(endDate, '', 'no end date');
        });
      });

      describe('range selection', function() {
        it('changes start date by clicking on calendar', function() {
          datepicker.clickingDate(dateRangePicker, startDate, '9').then(function() {
            datepicker.expectedDate(startDate, '12/09/2014');
            datepicker.expectedDate(endDate, '12/17/2014');
          });
        });

        it('changes end date by clicking on calendar', function() {
          datepicker.clickingDate(dateRangePicker, startDate, '17').then(function() {
            datepicker.expectedDate(startDate, '09/23/2014');
            datepicker.expectedDate(endDate, '12/17/2014');
          });
        });
      });
    });
  });

  describe('date range picker with start null date', function() {
    beforeEach(function() {
      detailsPaneHelper.loadPane(823, 'overview');
      dateRangePicker = element(by.css('.inplace-edit.attribute-date'));
    });

    context('read value', function() {
      it('should be present on page', function(){
        expect(dateRangePicker.isDisplayed()).to.eventually.be.true;
      });

      it('shows date range', function() {
        expect(dateRangePicker.getText()).to.eventually.equal('no start date\n  -  \n12/27/2014');
      });
    });

    context('write value', function() {
      var startDate, endDate;

      beforeEach(function() {
        startDate = dateRangePicker.$('.inplace-edit--date-range-start-date');
        endDate = dateRangePicker.$('.inplace-edit--date-range-end-date');
      });

      beforeEach(function() {
        dateRangePicker.$('.inplace-edit--read-value').click();
      });

      it('opens calendar on click', function() {
        startDate.click();
        expect($('.ui-datepicker').isDisplayed()).to.eventually.be.true;
      });

      it('shows date range in input', function() {
        datepicker.expectedDate(startDate, 'no start date');
        datepicker.expectedDate(endDate, '12/27/2014');
      });

      describe('range selection', function() {
        it('changes start date by clicking on calendar', function() {
          datepicker.clickingDate(dateRangePicker, startDate, '9').then(function() {
            datepicker.expectedDate(startDate, '12/09/2014');
            datepicker.expectedDate(endDate, '12/17/2014');
          });
        });

        it('changes end date by clicking on calendar', function() {
          datepicker.clickingDate(dateRangePicker, endDate, '17').then(function() {
            datepicker.expectedDate(startDate, '09/23/2014');
            datepicker.expectedDate(endDate, '12/17/2014');
          });
        });
      });
    });
  });

  describe('date range picker with due null date', function() {
    beforeEach(function() {
      detailsPaneHelper.loadPane(824, 'overview');
      dateRangePicker = element(by.css('.inplace-edit.attribute-date'));
    });

    context('read value', function() {
      it('should be present on page', function(){
        expect(dateRangePicker.isDisplayed()).to.eventually.be.true;
      });

      it('shows date range', function() {
        expect(dateRangePicker.getText()).to.eventually.equal('10/23/2014\n  -  \nno end date');
      });
    });

    context('write value', function() {
      var startDate, endDate;

      beforeEach(function() {
        startDate = dateRangePicker.$('.inplace-edit--date-range-start-date');
        endDate = dateRangePicker.$('.inplace-edit--date-range-end-date');
      });

      beforeEach(function() {
        dateRangePicker.$('.inplace-edit--read-value').click();
      });

      it('opens calendar on click', function() {
        startDate.click();
        expect($('.ui-datepicker').isDisplayed()).to.eventually.be.true;
      });

      it('shows date range in input', function() {
        datepicker.expectedDate(startDate, '0/23/2014');
        datepicker.expectedDate(endDate, 'no end date');
      });

      describe('range selection', function() {
        it('changes start date by clicking on calendar', function() {
          datepicker.clickingDate(dateRangePicker, startDate, '9').then(function() {
            datepicker.expectedDate(startDate, '12/09/2014');
            datepicker.expectedDate(endDate, '12/17/2014');
          });
        });

        it('changes end date by clicking on calendar', function() {
          datepicker.clickingDate(dateRangePicker, endDate, '17').then(function() {
            datepicker.expectedDate(startDate, '09/23/2014');
            datepicker.expectedDate(endDate, '12/17/2014');
          });
        });
      });
    });
  });

  describe('date range picker with children', function() {
    beforeEach(function() {
      detailsPaneHelper.loadPane(825, 'overview');
      dateRangePicker = element(by.css('.inplace-edit.attribute-date'));
    });

    it('not editable', function() {
      expect(dateRangePicker.$('.inplace-edit--write').isPresent()).to.eventually.be.false;
    });
  });
});
/* jshint ignore:end */

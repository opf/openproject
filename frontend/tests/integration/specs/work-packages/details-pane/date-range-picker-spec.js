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

  var normalizeString = function(string) {
    return string.replace(/\r?\n|\r/g, "").replace(/  /g, " ")
  };

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
        var read_value = dateRangePicker.$('.inplace-edit--read-value');
        var text = read_value.getText().then(function(value) { return normalizeString(value) } );

        expect(text).to.eventually.equal('02/17/2015 - 04/29/2015');
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
        elements.count(locator, 2);
      });

      it('end date calendar doesn\'t contain buttons', function() {
        endDate.click();
        var locator = by.css('.inplace-edit--date-range-end-date-picker .ui-datepicker-buttonpane > *');
        elements.count(locator, 2);
      });

      describe('today button', function() {
        var todayBtn;
        beforeEach(function() {
          todayBtn = startDateDatepicker.$('.ui-datepicker-current');
        });

        it('is displayed', function() {
          expect(
            startDateDatepicker
            .$('.ui-datepicker-current')
            .isDisplayed()).to.eventually.be.true;
        });

        it('changes date to current day', function() {
          var currentDate = new Date(),
              dateStr = 
                currentDate.getFullYear() + '-' + 
                ("0" + (currentDate.getMonth() + 1)).slice(-2) + '-' + 
                ("0" + currentDate.getDate()).slice(-2);
          todayBtn.click();
          datepicker.expectedDate(startDate, dateStr);
        });
      });

      describe('done button', function() {
        var doneBtn;
        beforeEach(function() {
          doneBtn = startDateDatepicker.$('.ui-datepicker-done');
        });

        it('is displayed', function() {
          expect(
            doneBtn
            .isDisplayed()).to.eventually.be.true;
        });

        it('it closes editing', function() {
          doneBtn.click();
          browser.waitForAngular();
          expect(
            dateRangePicker
            .$('.inplace-edit--read')
            .isDisplayed()).to.eventually.be.true;
          expect(
            dateRangePicker
            .$('.inplace-edit--write')
            .isDisplayed()).to.eventually.be.false;
        });
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
        datepicker.expectedDate(startDate, '2015-02-17');
        datepicker.expectedDate(endDate, '2015-04-29');
      });

      describe('switching date', function() {
        describe('end date',function() {
          it('changes when typed start date is greater', function() {
            datepicker.validation(startDate, '2015-05-30', '2015-05-30');
            datepicker.expectedDate(endDate, '2015-05-30');
          });

          it('does not change when typed start date is lower', function() {
            datepicker.validation(startDate, '2015-04-28', '2015-04-28');
            datepicker.expectedDate(endDate, '2015-04-29');
          });

          it('does not change when typed start date is equal', function() {
            datepicker.validation(startDate, '2015-04-29', '2015-04-29');
            datepicker.expectedDate(endDate, '2015-04-29');
          });

          it('changes when selected start date is greater', function() {
            datepicker.selectMonth(startDateDatepicker, 5, 2015).then(function() {
              datepicker.clickDate(startDateDatepicker, startDate, '30').then(function() { 
                datepicker.expectedDate(startDate, '2015-05-30');
                datepicker.expectedDate(endDate, '2015-05-30');
              });
            });
          });

          it('does not change when selected start date is lower', function() {
            datepicker.selectMonth(startDateDatepicker, 4).then(function() {
              datepicker.clickDate(startDateDatepicker, startDate, '28').then(function() { 
                datepicker.expectedDate(startDate, '2015-04-28');
                datepicker.expectedDate(endDate, '2015-04-29');
              });
            });
          });

          it('does not change when selected start date is equal', function() {
            datepicker.selectMonth(startDateDatepicker, 5).then(function() {
              datepicker.clickDate(startDateDatepicker, startDate, '29').then(function() { 
                datepicker.expectedDate(startDate, '2015-05-29');
                datepicker.expectedDate(endDate, '2015-05-29');
              });
            });
          });
        });

        describe('start date',function() {
          beforeEach(function() {
            endDate.click();
          });

          it('does not change when typed end date is greater', function() {
            datepicker.validation(endDate, '2015-05-30', '2015-05-30');
            datepicker.expectedDate(startDate, '2015-02-17');
          });

          it('changes when typed end date is lower', function() {
            datepicker.validation(endDate, '2015-02-16', '2015-02-16');
            datepicker.expectedDate(startDate, '2015-02-16');
          });

          it('does not change when typed start date is equal', function() {
            datepicker.validation(endDate, '2015-02-17', '2015-02-17');
            datepicker.expectedDate(startDate, '2015-02-17');
          });

          it('does not change when selected end date is greater', function() {
            datepicker.selectMonthAndYear(endDateDatepicker, 5, 2015).then(function() {
              datepicker.clickDate(endDateDatepicker, endDate, '30').then(function() { 
                datepicker.expectedDate(startDate, '2015-02-17');
                datepicker.expectedDate(endDate, '2015-05-30');
              });
            });
          });

          it('changes when selected end date is lower', function() {
            datepicker.selectMonth(endDateDatepicker, 2).then(function() {
              datepicker.clickDate(endDateDatepicker, endDate, '16').then(function() { 
                datepicker.expectedDate(startDate, '2015-02-16');
                datepicker.expectedDate(endDate, '2015-02-16');
              });
            });
          });

          it('does not change when selected start date is equal', function() {
            datepicker.selectMonthAndYear(endDateDatepicker, 2, 2015).then(function() {
              datepicker.clickDate(endDateDatepicker, endDate, '17').then(function() { 
                datepicker.expectedDate(startDate, '2015-02-17');
                datepicker.expectedDate(endDate, '2015-02-17');
              });
            });
          });
        });
      });

      describe('validation', function() {
        it('validates valid start date', function() {
          datepicker.validation(startDate, '2014-10-24', '2014-10-24');
        });

        it('validates valid end date', function() {
          datepicker.validation(endDate, '2014-11-27', '2014-11-27');
        });

        it('doesn\'t validate invalid start date', function() {
          datepicker.validation(startDate, '2014-13-27', '2015-02-17');
        });

        it('doesn\'t validate invalid end date', function() {
          datepicker.validation(endDate, '2014-11-40', '2015-04-29');
        });

        it('validates empty start date', function() {
          datepicker.validation(startDate, '', '');
        });

        it('validates empty end date', function() {
          datepicker.validation(endDate, '', '');
        });
      });

      describe('range selection', function() {
        it('changes start date by clicking on calendar', function() {
          startDate.click();
          datepicker.selectMonthAndYear(startDateDatepicker, 12, 2014);
          datepicker.clickDate(startDateDatepicker, startDate, '9').then(function() {
            datepicker.expectedDate(startDate, '2014-12-09');
            datepicker.expectedDate(endDate, '2015-04-29');
          });
        });

        it('changes end date by clicking on calendar', function() {
          datepicker.clickDate(endDateDatepicker, endDate, '17').then(function() {
            datepicker.expectedDate(startDate, '2015-02-17');
            datepicker.expectedDate(endDate, '2015-04-17');
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
        var read_value = dateRangePicker.$('.inplace-edit--read-value');
        var text = read_value.getText().then(function(value) { return normalizeString(value) });

        expect(text).to.eventually.equal('no start date - 12/27/2014');
      });
    });

    context('write value', function() {
      var startDate, endDate;

      beforeEach(function() {
        startDate = dateRangePicker.$('.inplace-edit--date-range-start-date');
        endDate = dateRangePicker.$('.inplace-edit--date-range-end-date');
        startDateDatepicker = dateRangePicker.$('.inplace-edit--date-range-start-date-picker');
        endDateDatepicker = dateRangePicker.$('.inplace-edit--date-range-end-date-picker');
      });

      beforeEach(function() {
        dateRangePicker.$('.inplace-edit--read-value').click();
      });

      it('opens calendar on click', function() {
        startDate.click();
        expect($('.ui-datepicker').isDisplayed()).to.eventually.be.true;
      });

      it('shows date range in input', function() {
        datepicker.expectedDate(startDate, '');
        datepicker.expectedDate(endDate, '2014-12-27');
      });

      describe('range selection', function() {
        it('changes start date by clicking on calendar', function() {
          startDate.click();
          datepicker.selectMonthAndYear(startDateDatepicker, 12, 2014);
          datepicker.clickDate(startDateDatepicker, startDate, '9').then(function() {
            datepicker.expectedDate(startDate, '2014-12-09');
            datepicker.expectedDate(endDate, '2014-12-27');
          });
        });

        it('changes end date by clicking on calendar', function() {
          endDate.click();
          datepicker.selectMonthAndYear(endDateDatepicker, 12, 2014);
          datepicker.clickDate(endDateDatepicker, endDate, '17').then(function() {
            datepicker.expectedDate(startDate, '');
            datepicker.expectedDate(endDate, '2014-12-17');
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
        var read_value = dateRangePicker.$('.inplace-edit--read-value');
        var text = read_value.getText().then(function(value) { return normalizeString(value) });

        expect(text).to.eventually.equal('10/23/2014 - no end date');
      });
    });

    context('write value', function() {
      var startDate, endDate;

      beforeEach(function() {
        startDate = dateRangePicker.$('.inplace-edit--date-range-start-date');
        endDate = dateRangePicker.$('.inplace-edit--date-range-end-date');
        startDateDatepicker = dateRangePicker.$('.inplace-edit--date-range-start-date-picker');
        endDateDatepicker = dateRangePicker.$('.inplace-edit--date-range-end-date-picker');
      });

      beforeEach(function() {
        dateRangePicker.$('.inplace-edit--read-value').click();
      });

      it('opens calendar on click', function() {
        startDate.click();
        expect($('.ui-datepicker').isDisplayed()).to.eventually.be.true;
      });

      it('shows date range in input', function() {
        datepicker.expectedDate(startDate, '2014-10-23');
        datepicker.expectedDate(endDate, '');
      });

      describe('range selection', function() {
        it('changes start date by clicking on calendar', function() {
          datepicker.clickDate(startDateDatepicker, startDate, '9').then(function() {
            datepicker.expectedDate(startDate, '2014-10-09');
            datepicker.expectedDate(endDate, '');
          });
        });

        it('changes end date by clicking on calendar', function() {
          endDate.click()
          datepicker.selectMonthAndYear(endDateDatepicker, 12, 2014);
          datepicker.clickDate(endDateDatepicker, endDate, '17').then(function() {
            datepicker.expectedDate(startDate, '2014-10-23');
            datepicker.expectedDate(endDate, '2014-12-17');
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

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

var expect = require('../../../../spec_helper.js').expect,
  detailsPaneHelper = require('../details-pane-helper.js'),
  datepicker = detailsPaneHelper.datepicker,
  elements = detailsPaneHelper.elements;


describe('details pane', function() {
  describe('custom fields', function() {
    var dateInput, datePicker;
    describe('date editable', function() {
      beforeEach(function() {
        detailsPaneHelper.loadPane(819, 'overview');
        dateInput = element(by.css('.inplace-edit.attribute-customField9'));
      });

      context('read value', function() {
        it('is editable', function() {
          expect(dateInput.$('.inplace-edit--write').isPresent()).to.eventually.be.true;
        });

        it('should be present on page', function() {
          expect(dateInput.isDisplayed()).to.eventually.be.true;
        });

        it('shows date range', function() {
          var read_value = dateInput.$('.inplace-edit--read-value');
          expect(read_value.getText()).to.eventually.equal('04/12/2015');
        });
      });

      context('write value', function() {
        var date;

        beforeEach(function() {
          dateInput.$('.inplace-edit--read-value').click();
          datePicker = element(by.css('.inplace-edit .inplace-edit--date-picker'));
          date = dateInput.$('input.inplace-edit--date');
        });

        it('opens calendar on click', function() {
          date.click();
          expect($('.ui-datepicker').isDisplayed()).to.eventually.be.true;
        });

        it('shows date in input', function() {
          datepicker.expectedDate(date, '2015-04-12');
        });

        it('contains week days displayed', function() {
          var locator = by.css('.inplace-edit--date-picker thead th:not(.ui-datepicker-week-col)');
          expect(dateInput.$('thead .ui-datepicker-week-col').isPresent()).to.eventually.be.true;
          elements.count(locator, 7);
        });

        it('contains year week numbers displayed', function() {
          var locator = by.css('.inplace-edit--date-picker tbody tr .ui-datepicker-week-col');
          expect(dateInput.$('tbody .ui-datepicker-week-col').isPresent()).to.eventually.be.true;
          elements.notCount(locator, 0);
        });

        describe('validation', function() {
          it('validates valid date', function() {
            datepicker.validation(date, '2015-04-12', '2015-04-12');
          });

          it('doesn\'t validate invalid date', function() {
            datepicker.validation(date, '2014-13-24', '2015-04-12');
          });

          it('validates empty date', function() {
            datepicker.validation(date, '', '');
          });
        });

        describe('date selection', function() {
          it('changes date by clicking on calendar', function() {
            datepicker.selectMonthAndYear(dateInput, 4, 2015);
            datepicker.clickDate(dateInput, date, '9').then(function() {
              datepicker.expectedDate(date, '2015-04-09');
            });
          });
        });
      });
    });
  });
});
/* jshint ignore:end */


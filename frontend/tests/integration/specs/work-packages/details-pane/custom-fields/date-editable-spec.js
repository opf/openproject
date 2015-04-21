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
    detailsPaneHelper = require('../details-pane-helper.js');


describe('details pane', function() {
  describe('custom fields', function() {
    var datePicker;
    describe('date editbale', function() {
      beforeEach(function() {
        detailsPaneHelper.loadPane(819, 'overview');
        datePicker = element(by.css('.inplace-edit.attribute-customField9'));
      });

      context('read value', function() {
        it('should be present on page', function(){
          expect(datePicker.isDisplayed()).to.eventually.be.true;
        });

        it('shows date range', function() {
          expect(datePicker.getText()).to.eventually.equal('04/12/2015');
        });
      });

      context('write value', function() {
        var date;

        beforeEach(function() {
          date = datePicker.$('input.inplace-edit--date');
        });

        beforeEach(function() {
          datePicker.$('.inplace-edit--read-value').click();
        });

        it('opens calendar on click', function() {
          date.click();
          expect($('.ui-datepicker').isDisplayed()).to.eventually.be.true;
        });

        it('shows date in input', function() {
          date.getText(function(text) {
            expect(text).to.equal('04/12/2015');
          });
        });

        describe('validation', function() {
          it('validates valid date', function() {
            date.clear();
            date.sendKeys('04/12/2015');
            date.getText(function(text) {
              expect(text).to.equal('04/12/2015');
            });
          });

          it('doesn\'t validate invalid date', function() {
            date.clear();
            date.sendKeys('13/24/2014');
            date.getText(function(text) {
              expect(text).to.equal('04/12/2015');
            });
          });

          it('validates empty date', function() {
            date.clear();
            date.getText(function(text) {
              expect(text).to.equal('no start date');
            });
          });
        });

        describe('date selection', function() {
          it('changes date by clicking on calendar', function() {
            date.click();
            element.all(by.css('a.ui-state-default')).filter(function(elem) {
              return elem.getText().then(function(text) {
                return text.indexOf('9') !== -1;
              });
            }).then(function(filteredElements) {
              filteredElements[0].click();
              date.getText(function(text) {
                expect(text).to.equal('04/09/2015');
              });
            });
          });
        });
      });
    });
  });
});
/* jshint ignore:end */

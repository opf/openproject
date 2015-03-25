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
    detailsPaneHelper = require('./details-pane-helper.js');


describe('details pane', function() {
  var dateRangePicker;  
  describe('date range picker', function() {
    beforeEach(function() {
      detailsPaneHelper.loadPane(819, 'overview');
      dateRangePicker = element(by.css('.inplace-edit.type-daterange'));
    });

    context('read value', function() {
      it('should be present on page', function(){
        expect(dateRangePicker.isDisplayed()).to.eventually.be.true;
      });

      it('shows date range', function() {
        expect(dateRangePicker.getText()).to.eventually.equal('10/23/2014\n-\n12/27/2014');
      });
    });

    context('write value', function() {
      var startDate, endDate;

      beforeEach(function() {
        startDate = dateRangePicker.$('input.start');
        endDate = dateRangePicker.$('input.end');
      });

      beforeEach(function() {
        dateRangePicker.$('.inplace-edit--read-value').click();
      });

      it('opens calendar on click', function() {
        startDate.click();
        expect($('.ui-datepicker').isDisplayed()).to.eventually.be.true;
      });

      it('shows date range in input', function() {
        startDate.getText(function(text) {
          expect(text).to.equal('10/23/2014');
        });
        endDate.getText(function(text) {
          expect(text).to.equal('12/27/2014');
        });
      });

      describe('validation', function() {
        it('validates valid start date', function() {
          startDate.clear();
          startDate.sendKeys('10/24/2014');
          startDate.getText(function(text) {
            expect(text).to.equal('10/24/2014');
          });
        });

        it('validates valid end date', function() {
          endDate.clear();
          endDate.sendKeys('11/27/2014');
          endDate.getText(function(text) {
            expect(text).to.equal('11/27/2014');
          });
        });

        it('doesn\'t validate invalid start date', function() {
          startDate.clear();
          startDate.sendKeys('13/24/2014');
          startDate.getText(function(text) {
            expect(text).to.equal('10/23/2014');
          });
        });

        it('doesn\'t validate invalid end date', function() {
          endDate.clear();
          endDate.sendKeys('11/40/2014');
          endDate.getText(function(text) {
            expect(text).to.equal('12/27/2014');
          });
        });

        it('validates empty start date', function() {
          startDate.clear();
          startDate.getText(function(text) {
            expect(text).to.equal('no start date');
          });
        });

        it('validates empty end date', function() {
          endDate.clear();
          endDate.getText(function(text) {
            expect(text).to.equal('no end date');
          });
        });
      });

      describe('range selection', function() {
        it('changes start date by clicking on calendar', function() {
          startDate.click();
          element.all(by.css('a.ui-state-default')).filter(function(elem){
            return elem.getText().then(function(text) {
              return text.indexOf('9') !== -1;
            });
          }).then(function(filteredElements) {
            filteredElements[0].click();
            startDate.getText(function(text) {
              expect(text).to.equal('12/09/2014');
            });
            endDate.getText(function(text) {
              expect(text).to.equal('12/17/2014');
            });
          });
        });

        it('changes end date by clicking on calendar', function() {
          endDate.click();
          element.all(by.css('a.ui-state-default')).filter(function(elem){
            return elem.getText().then(function(text) {
              return text.indexOf('17') !== -1;
            });
          }).then(function(filteredElements) {
            filteredElements[0].click();
            startDate.getText(function(text) {
              expect(text).to.equal('09/23/2014');
            });
            endDate.getText(function(text) {
              expect(text).to.equal('12/17/2014');
            });
          });
        });
      });
    });
  });

  describe('date range picker with start null date', function() {
    beforeEach(function() {
      detailsPaneHelper.loadPane(823, 'overview');
      dateRangePicker = element(by.css('.inplace-edit.type-daterange'));
    });

    context('read value', function() {
      it('should be present on page', function(){
        expect(dateRangePicker.isDisplayed()).to.eventually.be.true;
      });

      it('shows date range', function() {
        expect(dateRangePicker.getText()).to.eventually.equal('no start date\n-\n12/27/2014');
      });
    });

    context('write value', function() {
      var startDate, endDate;

      beforeEach(function() {
        startDate = dateRangePicker.$('input.start');
        endDate = dateRangePicker.$('input.end');
      });

      beforeEach(function() {
        dateRangePicker.$('.inplace-edit--read-value').click();
      });

      it('opens calendar on click', function() {
        startDate.click();
        expect($('.ui-datepicker').isDisplayed()).to.eventually.be.true;
      });

      it('shows date range in input', function() {
        startDate.getText(function(text) {
          expect(text).to.equal('no start date');
        });
        endDate.getText(function(text) {
          expect(text).to.equal('12/27/2014');
        });
      });

      describe('range selection', function() {
        it('changes start date by clicking on calendar', function() {
          startDate.click();
          element.all(by.css('a.ui-state-default')).filter(function(elem){
            return elem.getText().then(function(text) {
              return text.indexOf('9') !== -1;
            });
          }).then(function(filteredElements) {
            filteredElements[0].click();
            startDate.getText(function(text) {
              expect(text).to.equal('12/09/2014');
            });
            endDate.getText(function(text) {
              expect(text).to.equal('12/17/2014');
            });
          });
        });

        it('changes end date by clicking on calendar', function() {
          endDate.click();
          element.all(by.css('a.ui-state-default')).filter(function(elem){
            return elem.getText().then(function(text) {
              return text.indexOf('17') !== -1;
            });
          }).then(function(filteredElements) {
            filteredElements[0].click();
            startDate.getText(function(text) {
              expect(text).to.equal('09/23/2014');
            });
            endDate.getText(function(text) {
              expect(text).to.equal('12/17/2014');
            });
          });
        });
      });
    });
  });

  describe('date range picker with due null date', function() {
    beforeEach(function() {
      detailsPaneHelper.loadPane(824, 'overview');
      dateRangePicker = element(by.css('.inplace-edit.type-daterange'));
    });

    context('read value', function() {
      it('should be present on page', function(){
        expect(dateRangePicker.isDisplayed()).to.eventually.be.true;
      });

      it('shows date range', function() {
        expect(dateRangePicker.getText()).to.eventually.equal('10/23/2014\n-\nno end date');
      });
    });

    context('write value', function() {
      var startDate, endDate;

      beforeEach(function() {
        startDate = dateRangePicker.$('input.start');
        endDate = dateRangePicker.$('input.end');
      });

      beforeEach(function() {
        dateRangePicker.$('.inplace-edit--read-value').click();
      });

      it('opens calendar on click', function() {
        startDate.click();
        expect($('.ui-datepicker').isDisplayed()).to.eventually.be.true;
      });

      it('shows date range in input', function() {
        startDate.getText(function(text) {
          expect(text).to.equal('10/23/2014');
        });
        endDate.getText(function(text) {
          expect(text).to.equal('no end date');
        });
      });

      describe('range selection', function() {
        it('changes start date by clicking on calendar', function() {
          startDate.click();
          element.all(by.css('a.ui-state-default')).filter(function(elem){
            return elem.getText().then(function(text) {
              return text.indexOf('9') !== -1;
            });
          }).then(function(filteredElements) {
            filteredElements[0].click();
            startDate.getText(function(text) {
              expect(text).to.equal('12/09/2014');
            });
            endDate.getText(function(text) {
              expect(text).to.equal('12/17/2014');
            });
          });
        });

        it('changes end date by clicking on calendar', function() {
          endDate.click();
          element.all(by.css('a.ui-state-default')).filter(function(elem){
            return elem.getText().then(function(text) {
              return text.indexOf('17') !== -1;
            });
          }).then(function(filteredElements) {
            filteredElements[0].click();
            endDate.getText(function(text) {
              expect(text).to.equal('09/23/2014');
            });
            endDate.getText(function(text) {
              expect(text).to.equal('12/17/2014');
            });
          });
        });
      });
    });
  });
});
/* jshint ignore:end */

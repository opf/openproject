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

var expect = require('../../../spec_helper.js').expect, 
    detailsPaneHelper = require('./details-pane-helper.js');


describe('details pane', function() {
  var dateRangePicker;

  beforeEach(function() {
    detailsPaneHelper.loadPane(819, 'overview');
    dateRangePicker = $('.inplace-editor.type-daterange');
  });
  
  describe('date range picker', function() {
    context('read value', function() {
      it('should be present on page', function(){
        expect(dateRangePicker.isPresent()).to.eventually.be.true;
      });

      it('shows date range', function() {
        expect(dateRangePicker.getText()).to.eventually.equal("10/23/2014 - 12/27/2014");
      });
    });

    context('write value', function() {
      beforeEach(function() {
        dateRangePicker.$('.ined-read-value').click();
      });

      it('opens calendar on click', function() {
        expect(dateRangePicker.$('.ui-datepicker').isDisplayed()).to.eventually.be.true;
      });

      it('shows date range in input', function() {
        dateRangePicker.$("[ng-model='daterange']").getText(function(text) {
          expect(text).to.equal("10/23/2014 - 12/27/2014");
        });
      });

      describe('range selection', function() {
        it('changes start date by clicking on calendar', function() {
          element.all(by.css("a.ui-state-default")).filter(function(elem, index){
            return elem.getText().then(function(text) {
              return text.indexOf('9') !== -1;
            });
          }).then(function(filteredElements) {
            filteredElements[0].click();
            dateRangePicker.$("[ng-model='daterange']").getText(function(text) {
              expect(text).to.equal("12/09/2014 - 12/27/2014");
            });
          });
        });

        it('changes end date by clicking on calendar', function() {
          element.all(by.css("a.ui-state-default")).filter(function(elem, index){
            return elem.getText().then(function(text) {
              return text.indexOf('17') !== -1;
            });
          }).then(function(filteredElements) {
            filteredElements[0].click();
            dateRangePicker.$("[ng-model='daterange']").getText(function(text) {
              expect(text).to.equal("09/23/2014 - 12/17/2014");
            });
          });
        });

        xit('doesn\'t change start date month by clicking on calendar', function() {
          element.all(by.css('.ui-datepicker-next')).then(function(elem) {
            elem[0].click().then(function() {
              dateRangePicker.$("[ng-model='daterange']").getText(function(text) {
                expect(text).to.equal("09/23/2014 - 12/17/2015");
              });
            });
          });
        });
      });
    });
  });
});

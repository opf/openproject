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
  WorkPackageDetailsPane = require('../../../pages/work-package-details-pane.js');

function loadPane(workPackageId, paneName) {
  var page = new WorkPackageDetailsPane(workPackageId, paneName);
  page.get();
  return browser.waitForAngular();
}

function showAll() {
  $('.panel-toggler a').click();
}

function behaveLikeEmbeddedDropdown(name, correctValue) {
  context('behaviour', function() {
    var editor = $('.inplace-edit.attribute-' + name);

    before(function() {
      loadPane(819, 'overview');
      showAll();
    });

    describe('read state', function() {
      it('should render a span with value', function() {
        expect(
          editor
          .$('.inplace-edit--read-value')
          .getText()
        ).to.eventually.equal(correctValue);
      });
    });

    describe('edit state', function() {
      before(function() {
        editor.$('.inplace-editing--trigger-link').click();
      });

      context('dropdown', function() {
        it('should be rendered', function() {
          expect(
            editor
            .$('.select2-container').isDisplayed()
          ).to.eventually.be.true;
        });

        it('should have the correct value', function() {
          expect(
            editor
            .$('.select2-choice .select2-chosen span')
            .getText()
          ).to.eventually.equal(correctValue);
        });
      });
    });
  });
}

var elements = {
  count: function(locator, expected) {
    element.all(locator).count().then(function(count) {
      expect(count).to.equal(expected);
    });
  },
  notCount: function(locator, expected) {
    element.all(locator).count().then(function(count) {
      expect(count).to.not.equal(expected);
    });
  }
};

var datepicker = {
  clickDate: function datepickerSpec(calendar, dateInput, selectDate) {
    dateInput.click();
    return calendar.all(by.css('.ui-datepicker-calendar a.ui-state-default'))
          .filter(function(elem) {
      return elem.getText().then(function(text) {
        return text.indexOf(selectDate) !== -1;
      });
    }).then(function(filteredElements) {
      filteredElements[0].click();
    });
  },
  selectMonth: function(calendar, monthNumber) {
    return calendar.$('.ui-datepicker-month > option[value="' + (monthNumber - 1) + '"]').click();
  },
  selectYear: function(calendar, yearNumber) {
    return calendar.$('.ui-datepicker-year > option[value="' + yearNumber + '"]').click();
  },
  selectMonthAndYear: function(calendar, monthNumber, yearNumber) {
    return datepicker.selectMonth(calendar, monthNumber).then(function() {
      datepicker.selectYear(calendar, yearNumber);
    });
  },
  expectedDate: function expectedDate(dateInput, expected) {
    dateInput.getAttribute('value').then(function(text) {
      expect(text).to.equal(expected);
    });
  },
  validation: function validation(dateInput, sended, expected) {
    dateInput.clear();
    dateInput.sendKeys(sended);
    datepicker.expectedDate(dateInput, expected);
  }
};

module.exports = {
  loadPane: loadPane,
  showAll: showAll,
  behaveLikeEmbeddedDropdown: behaveLikeEmbeddedDropdown,
  datepicker: datepicker,
  elements: elements
};


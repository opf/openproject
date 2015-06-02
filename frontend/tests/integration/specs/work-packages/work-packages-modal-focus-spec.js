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

var expect = require('../../spec_helper.js').expect,
    WorkPackagesPage = require('../../pages/work-packages-page.js');

describe('OpenProject', function() {
  var page = new WorkPackagesPage();

  beforeEach(function(){
    page.get();
  });

  it('columns modal should focus', function() {
    element(by.css('#work-packages-settings-button')).click();
    element(by.css('[ng-click="showColumnsModal($event)"]')).click();
    browser.driver.switchTo().activeElement().getAttribute('class').then(function (classList) {
      expect(element(by.css('.ui-select-container.ui-select-multiple input.ui-select-search')).getAttribute('class'))
        .to.eventually.equal(classList);
    });
  });

  it('sorting modal should focus', function() {
    element(by.css('#work-packages-settings-button')).click();
    element(by.css('[ng-click="showSortingModal($event)"]')).click();
    //don't why, but if to do the request twice the test is green
    browser.driver.switchTo().activeElement().getAttribute('id');
    browser.driver.switchTo().activeElement().getAttribute('id').then(function (elementId) {
      browser.waitForAngular();
      expect(element(by.css('.ng-modal-window .form--row:first-child input.ui-select-focusser')).getAttribute('id'))
        .to.eventually.equal(elementId);
    });
  });

  it('grouping modal should focus', function() {
    element(by.css('#work-packages-settings-button')).click();
    element(by.css('[ng-click="showGroupingModal($event)"]')).click();
    browser.driver.switchTo().activeElement().getAttribute('id').then(function (elementId) {
      expect(element(by.css('.ng-modal-window .select2-container input.ui-select-focusser')).getAttribute('id'))
        .to.eventually.equal(elementId);
    });
  });


});


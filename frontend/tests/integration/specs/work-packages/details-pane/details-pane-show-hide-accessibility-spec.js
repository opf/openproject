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

/*jshint expr: true*/
describe('OpenProject', function () {
  describe('accessibility', function () {
    beforeEach(function () {
      detailsPaneHelper.loadPane(819, 'overview');
    });
    describe('...', function () {
      beforeEach(function () {
        $('.attributes-group.ng-scope:nth-child(1) .inplace-edit--read-value').click();
        //element(by.css('.attributes-group.ng-scope:nth-child(1) textarea'));

        // tab through all the elements in the inplace edit control
        // Save
        browser.actions().sendKeys(protractor.Key.TAB).perform();
        // Save and send
        browser.actions().sendKeys(protractor.Key.TAB).perform();
        // Cancel
        browser.actions().sendKeys(protractor.Key.TAB).perform();
      });

      it('show all / hide all should be accessible in one tab', function () {
        browser.actions().sendKeys(protractor.Key.TAB).perform();

        return expect(browser.driver.switchTo().activeElement().getText())
          .to.eventually.equal('Show all');
      });
    });
  });
});

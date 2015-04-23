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

  beforeEach(function() {
    page.get();
    browser.waitForAngular();
  });

  it('should show work packages title', function() {
    page.get();

    expect(page.getSelectableTitle().getText()).to.eventually.equal('WORK PACKAGES');
  });

  it('should show work packages', function() {
    page.get();

    page.getTableHeaders().getText().then(function(text) {
      expect(text).to.include.members([
        '',
        'ID',
        'TYPE',
        'STATUS',
        'SUBJECT',
        'ASSIGNEE'
      ]);
    });
  });

  describe('click', function() {
    context('with Ctrl', function() {
      var newWindowHandle;
      
      beforeEach(function() {
        var link = element(by.css('[title="16923"]'));
        browser.actions()
          .mouseMove(link)
          .sendKeys(protractor.Key.CONTROL)
          .click()
          .perform();
      });

      it('opens new tab', function() {
        browser.getAllWindowHandles().then(function (handles) {
          newWindowHandle = handles[1];
          browser.switchTo().window(newWindowHandle).then(function () {
            expect(browser.getCurrentUrl()).to.eventually.contain('/work_packages/16923');
          });
        });
      });
    });
  });
});

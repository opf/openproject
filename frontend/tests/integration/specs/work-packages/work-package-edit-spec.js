// -- copyright
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
// ++

var expect = require('../../spec_helper.js').expect,
    WorkPackageShowPage = require('../../pages/work-package-show-page.js');

describe('Work package edit', function() {
  var page = new WorkPackageShowPage(),
      expectFocusEquals = function (id) {
        var activeId = browser.driver.switchTo().activeElement().getId();
        expect(activeId).to.eventually.deep.equal(id);
      };

  describe('when clicking edit button on show page', function () {
    beforeEach(function () {
      page.get();
      page.editButton.isPresent().then(function () {
        page.editButton.click();
      })
    });

    it('should focus the subject field when used', function() {
      page.focusElement.getId().then(expectFocusEquals);
    });

    it('should show multiple editable input fields', function() {
      expect(page.editableFields.count()).to.eventually.be.above(1);
    });

    it('should show the edit actions', function () {
      expect(page.editActions.container.isDisplayed()).to.eventually.be.true;
    });

    it('should keep the user input when switching to overview mode', function () {
      var val = 'my_value';
      page.focusElement.sendKeys(val);

      page.overviewButton.click().then(function () {
        page.focusElement.isPresent().then(function () {
          expect(page.focusElement.getAttribute('value')).to.eventually.equal(val);
        });
      });
    });

    describe('when triggering the edit actions', function () {
      it('should cancel editing when the cancel button is clicked', function () {
        page.editActions.cancel.click();
        expect(page.editableFields.count()).to.eventually.equal(0);
      });
    });
  });
});

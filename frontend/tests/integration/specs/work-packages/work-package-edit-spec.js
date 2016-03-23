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
      }, val = 'my_value';

  describe('when clicking edit button on show page', function () {
    var expectBetweenViews = function () {
      it('should show the edit actions', function () {
        expect(page.editActions.container.isDisplayed()).to.eventually.be.true;
      });

      it('should disable the add-work-package button', function () {
        expect(page.toolBar.addWorkPackage.isEnabled()).to.eventually.be.false;
      });

      it('should disable the list view button', function () {
        expect(page.toolBar.listView.isEnabled()).to.eventually.be.false;
      });
    };

    beforeEach(function () {
      page.get();
      page.toolBar.edit.isPresent().then(function () {
        page.toolBar.edit.click();
      });
    });

    it('should focus the subject field when used', function() {
      page.focusElement.getId().then(expectFocusEquals);
    });

    it('should show multiple editable input fields', function() {
      expect(page.editableFields.count()).to.eventually.be.above(1);
    });

    it('should hide the edit button', function () {
      expect(page.toolBar.edit.isDisplayed()).to.eventually.be.false;
    });

    it('should disable the watch/unwatch button button', function () {
      expect(page.toolBar.watch.isEnabled()).to.eventually.be.false;
    });

    it('should disable the drop-down-menu button', function () {
      expect(page.toolBar.dropDown.isEnabled()).to.eventually.be.false;
    });

    expectBetweenViews();

    describe('when switching to overview mode', function () {
      beforeEach(function () {
        page.focusElement.sendKeys(val);
        page.descriptionInput.clear();
        browser.wait(page.toolBar.overview.click);
      });

      it('should keep the user input', function () {
        page.focusElement.isPresent().then(function () {
          expect(page.focusElement.getAttribute('value')).to.eventually.equal(val);
        });
      });

      it('should keep empty user input', function () {
        page.descriptionInput.isPresent().then(function () {
          expect(page.descriptionInput.getAttribute('value')).to.eventually.equal('');
        })
      });

      it('should disable the filter-toggle button', function () {
        expect(page.toolBar.filter.isEnabled()).to.eventually.be.false;
      });

      it('should disable the settings button', function () {
        expect(page.toolBar.settings.isEnabled()).to.eventually.be.false;
      });

      expectBetweenViews();

      describe('when clicking on a work package in the list view', function () {
        var confirm, url;

        beforeEach(function () {
          browser.getCurrentUrl().then(function (currentUrl) {
            url = currentUrl;
          });

          page.listViewWorkPackage.click();
          $('#work-package-820 .wp-table--details-link').click().then(function () {
            confirm = browser.switchTo().alert();
          });
        });

        it('should show a confirmation dialog', function () {
          expect(protractor.ExpectedConditions.alertIsPresent()()).to.eventually.be.true;
          confirm.dismiss();
        });

        it('should change the route when the confirmation is accepted', function () {
          confirm.accept().then(function () {
            browser.getCurrentUrl().then(function (newUrl) {
              expect(newUrl).to.not.equal(url);
            })
          });
        });

        it('should change nothing when the confirmation is dismissed', function () {
          confirm.dismiss().then(function () {
            browser.getCurrentUrl().then(function (newUrl) {
              expect(newUrl).to.equal(url);
            })
          });
        });
      });
    });

    describe('when triggering the cancel action', function () {
      beforeEach(function () {
        page.editActions.cancel.click();
      });

      it('should cancel editing', function () {
        expect(page.editableFields.count()).to.eventually.equal(0);
      });

      it('should reset user input', function () {
        expect(page.focusElementValue.getText()).to.eventually.not.equal(val);
      });
    });
  });

  describe('when visiting the work package edit routes', function () {
    it('should should open the details view in edit mode', function () {
      browser.get('/work_packages/' + page.wpId + '/edit');
      expect(page.editableFields.isDisplayed()).to.eventually.be.ok;
    });
  })
});

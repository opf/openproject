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
    expect($$('.focus-input').count()).to.eventually.be.above(1);
  });

  it('should reset previously edited fields without focusing one', function() {
    page.editButton.click();
    page.editButton.getId().then(expectFocusEquals);
  });
});

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

var expect = require('../../../../spec_helper.js').expect,
    detailsPaneHelper = require('../details-pane-helper.js');

describe('Details pane', function() {
  describe('relations tab', function() {
    context('has parent', function() {
      var parentsSlide;
      beforeEach(function () {
        detailsPaneHelper.loadPane(819, 'relations');
        parentsSlide = element(by.css('[handler="wpParent"] [execute-on-enter]'));
        parentsSlide.click();
        browser.waitForAngular();
      });

      xit('shows', function() {
        element(by.repeater('relation in handler.relations')).then(function(relation) {
          expect(relation).to.be.defined;
        });
      });
    });

    context('does not have parent', function() {
      var parentsSlide;
      beforeEach(function () {
        detailsPaneHelper.loadPane(822, 'relations');
        parentsSlide = element(by.css('[handler="wpParent"] [execute-on-enter]'));
        parentsSlide.click();
        browser.waitForAngular();
      });

      it('shows "No relation exists"', function() {
        element.all(by.repeater('relation in handler.relations')).count().then(function(count) {
          expect(count).to.eq(0);
        });
      });
    });
  });
});

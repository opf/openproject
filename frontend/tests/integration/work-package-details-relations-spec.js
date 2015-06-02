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

var chai = require('chai');
var chaiAsPromised = require('chai-as-promised');

chai.use(chaiAsPromised);
var expect = chai.expect;


var WorkPackageDetailsPane = require('./pages/work-package-details-pane.js');

describe('OpenProject', function() {
  function loadPane(workPackageId) {
    var page = new WorkPackageDetailsPane(workPackageId, 'relations');
    page.get();
    browser.waitForAngular();
  }

  describe('details pane', function() {
    beforeEach(function() {
      loadPane(819);
    });

    it('opens relations tab', function() {
      $('[ui-sref="work-packages.list.details.relations({})"]')
      .getAttribute('class')
      .then(function(classes) {
        expect(classes.split(' ')).to.contain('selected');
      });
    });

    describe('relations tab', function() {
      var toggleAccordeon = function(titleName) {
        getAccordeon(titleName).click();
      },
      getAccordeon = function(titleName) {
        return $('.relation[title="' + titleName + '"]');
      };

      beforeEach(function(){
        toggleAccordeon('Parent');
      });

      it('focuses on disabled button', function() {
        $('.relation[title="Parent"] button')
        .getAttribute('disabled')
        .then(function(disabled){
          expect(disabled).to.be.equal('true');
        });
      });
    });
  });
});

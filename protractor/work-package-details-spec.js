//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
    var page = new WorkPackageDetailsPane(819, 'overview');

    it('should show work packages details pane', function() {
        page.get();
        expect(page.pane.isPresent()).to.eventually.be.true;
    });

    describe('editable subject', function() {
        var page;
        context('work package with update link', function() {
            beforeEach(function() {
                page = new WorkPackageDetailsPane(819, 'overview');
                page.get();
            });
            it('should render an editable subject', function() {
                expect($("h2 .inplace-editor").isPresent()).to.eventually.be.true;
            });
        });
        context('work package without update link', function() {
            beforeEach(function() {
                page = new WorkPackageDetailsPane(820, 'overview');
                page.get();
            });
            it('should not render an editable subject', function() {
                expect($("h2 .inplace-editor").isPresent()).to.eventually.be.false;
            });
        });
    });

});

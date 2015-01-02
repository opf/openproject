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

/*jshint expr: true*/

describe('WorkPackagesTableHelper', function() {
  var WorkPackagesTableHelper;

  beforeEach(module('openproject.workPackages.helpers', 'openproject.services'));
  beforeEach(module('openproject.templates', function($provide) {
    var configurationService = {};

    configurationService.isTimezoneSet = sinon.stub().returns(false);

    $provide.constant('ConfigurationService', configurationService);
  }));
  beforeEach(inject(function(_WorkPackagesTableHelper_) {
    WorkPackagesTableHelper = _WorkPackagesTableHelper_;
  }));

  describe('getSelectedRows', function() {
    var rows = [];

    describe('when rows are empty', function() {
      it('returns an array', function() {
        expect(WorkPackagesTableHelper.getSelectedRows(rows)).to.be.an.instanceof(Array);
      });
    });

    describe('when no rows are checked', function() {
      var rows = [{checked: false, object: {}}];

      it('returns an array', function() {
        expect(WorkPackagesTableHelper.getSelectedRows(rows)).to.be.an.instanceof(Array);
      });

      it('returns an empty array', function() {
        expect(WorkPackagesTableHelper.getSelectedRows(rows)).to.be.empty;
      });
    });

    describe('when one among many row is selected', function() {
      var workPackage = Factory.build('PlanningElement');
      var checkedRow = {checked: true, object: workPackage};

      var rows = [{object: {}}, checkedRow];

      it('returns the selected row', function() {
        expect(WorkPackagesTableHelper.getSelectedRows(rows)).to.deep.equal(new Array(checkedRow));
      });
    });
  });

  describe('getWorkPackagesFromRows', function() {
    var workPackage = Factory.build('PlanningElement');
    var rows = new Array({object: workPackage});

    it('returns the work package object', function() {
      expect(WorkPackagesTableHelper.getWorkPackagesFromRows(rows)).to.deep.equal([workPackage]);
    });
  });

  describe('mapColumnNamesToColumns', function() {
    // What do we even need this helper for at the moment?

    var columns = [{ name: 'cheese' },
      { name: 'biscuits' },
      { name: 'grapes' },
      { name: 'wine' },
      { name: 'pandas' }];
    var identifiers = ['cheese', 'wine'];

    it('should get the columns for the names given', function() {
      var selectedColumns = WorkPackagesTableHelper.mapIdentifiersToColumns(columns, identifiers);
      expect(selectedColumns).to.deep.equal([{ name: 'cheese' }, { name: 'wine' }]);
    });

  });

});

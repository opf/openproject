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

describe('WorkPackageContextMenuHelper', function() {
  var PERMITTED_CONTEXT_MENU_ACTIONS = ['edit', 'log_time', 'update', 'move'];
  var WorkPackageContextMenuHelper;
  var stateParams = {};

  beforeEach(module('openproject.workPackages.helpers', 'openproject.models', 'openproject.api', 'openproject.layout','openproject.services'));

  beforeEach(module('openproject.templates', function($provide) {
    var configurationService = {};

    configurationService.isTimezoneSet = sinon.stub().returns(false);

    $provide.constant('$stateParams', stateParams);
    $provide.constant('ConfigurationService', configurationService);
  }));

  beforeEach(inject(function(_WorkPackageContextMenuHelper_) {
    WorkPackageContextMenuHelper = _WorkPackageContextMenuHelper_;
  }));

  describe('getPermittedActions', function() {

    var actions = ['edit', 'log_time', 'update', 'move'];
    var actionLinks = {
      edit: '/work_packages/123/edit',
      log_time: '/work_packages/123/time_entries/new',
      move: '/work_packages/move/new?ids%5B%5D=123',
      delete: '/work_packages/bulk?ids%5B%5D=123&method=delete'
    };

    var permittedAction = actions[0],
        notPermittedAction = actions[1];

    var workPackage = Factory.build('PlanningElement', {
      _actions: new Array(permittedAction),
      _links: actionLinks
    });

    describe('when an array with a single work package is passed as an argument', function() {
      var workPackages = new Array(workPackage);

      it('returns the link of a listed action', function() {
        var permittedActions = WorkPackageContextMenuHelper.getPermittedActions(workPackages, PERMITTED_CONTEXT_MENU_ACTIONS);
        expect(permittedActions).to.have.property(permittedAction);
        expect(permittedActions[permittedAction]).to.equal('/work_packages/123/edit');
      });

      it('does not return the link of an action which is not listed', function() {
        var permittedActions = WorkPackageContextMenuHelper.getPermittedActions(workPackages, PERMITTED_CONTEXT_MENU_ACTIONS);
        expect(permittedActions).not.to.have.property(notPermittedAction);
      });
    });

    describe('when more than one work package is passed as an argument', function() {
      var anotherPermittedAction = actions[3],
          anotherWorkPackage = Factory.build('PlanningElement', {
            _actions: [permittedAction, anotherPermittedAction],
            _links: actionLinks
          });
      var workPackages = [anotherWorkPackage, workPackage];

      beforeEach(inject(function(_WorkPackagesTableService_) {
        var WorkPackagesTableService = _WorkPackagesTableService_;
        WorkPackagesTableService.setBulkLinks({
          edit: '/work_packages/bulk/edit'
        });
      }));

      it('returns the link of an action listed for all work packages', function() {
        expect(WorkPackageContextMenuHelper.getPermittedActions(workPackages)).to.have.property(permittedAction);
      });

      it('does not return the action if it is not permitted on all work packages', function() {
        expect(WorkPackageContextMenuHelper.getPermittedActions(workPackages)).not.to.have.property(anotherPermittedAction);
      });

      it('links to the bulk action and passes all work package ids', function() {
        var key = encodeURIComponent('ids[]');
        var queryString = key + '=' + anotherWorkPackage.id + '&' + key + '=' + workPackage.id;

        expect(WorkPackageContextMenuHelper.getPermittedActions(workPackages)[permittedAction]).to.equal('/work_packages/bulk/edit?' + queryString);
      });
    });
  });
});

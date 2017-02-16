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

import {WorkPackageViewButtonController} from './wp-view-button.directive';

var expect = chai.expect;

describe('wpViewButton directive', () => {
  var $state:any, scope:any;
  var controller:WorkPackageViewButtonController;

  beforeEach(angular.mock.module(
    'openproject.wpButtons', 'openproject.templates', 'openproject.config'));

  beforeEach(angular.mock.inject(($compile:ng.ICompileService, $rootScope:ng.IRootScopeService,
      _$state_:ng.ui.IStateService) => {

    var html = '<wp-view-button next-wp-func-="nextWp"' +
      ' work-package-id="workPackageId"></wp-view-button>';

    var element = angular.element(html);

    $state = _$state_;

    scope = $rootScope.$new();

    $compile(element)(scope);
    scope.$digest();

    controller = element.controller('wpViewButton');
  }));

  describe('openWorkPackageShowView()', () => {
    var sGo:any, sIs:any;
    beforeEach(() => {
      sGo = sinon.stub($state, 'go');
      sIs = sinon.stub($state, 'is');
    });

    it('should redirect to work-packages.show by default', () => {
      scope.workPackageId = 123;
      scope.$digest();

      controller.openWorkPackageShowView();

      expect(sGo.calledWith('work-packages.show.activity')).to.be.true;
    });

    it('should redirect to show create when in list create', () => {
      sIs.withArgs('work-packages.list.new').returns(true);
      $state.params.type = 'something';

      controller.openWorkPackageShowView();

      expect(sGo.calledWith('work-packages.new', $state.params)).to.be.true;
    });
  });
});

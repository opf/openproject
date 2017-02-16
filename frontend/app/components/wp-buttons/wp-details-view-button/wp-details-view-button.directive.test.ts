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

import {WorkPackageDetailsViewButtonController} from './wp-details-view-button.directive';
import {KeepTabService} from '../../wp-panels/keep-tab/keep-tab.service';

var expect = chai.expect;

describe('wpListViewButton directive', () => {
  var $state:any, scope:any;
  var keepTab:KeepTabService;
  var controller:WorkPackageDetailsViewButtonController;

  beforeEach(angular.mock.module('openproject.wpButtons', 'openproject.templates',
    'openproject.config'));

  beforeEach(angular.mock.inject(($compile:any, $rootScope:any, _$state_:any, _keepTab_:any) => {
    var html = '<wp-details-view-button></wp-details-view-button>';

    var element = angular.element(html);

    $state = _$state_;
    keepTab = _keepTab_;

    scope = $rootScope.$new();

    $compile(element)(scope);
    scope.$digest();

    controller = element.controller('wpDetailsViewButton');
  }));

  describe('when using openDetailsView()', () => {
    var go:any;

    beforeEach(() => {
      go = sinon.stub($state, 'go');
      controller.openDetailsView();
    });

    it("should redirect user to 'work-packages.list'", () => {
      expect(go.withArgs(keepTab.currentDetailsState).calledOnce).to.be.true;
    });
  });
});

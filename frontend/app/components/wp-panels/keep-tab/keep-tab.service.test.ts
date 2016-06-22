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

import {KeepTabService} from './keep-tab.service';

var expect = chai.expect;

describe('keepTab service', () => {
  var $state:ng.ui.IStateService;
  var $rootScope:ng.IRootScopeService;
  var keepTab:KeepTabService;

  var defaults = {
    showTab: 'work-packages.show.activity',
    detailsTab: 'work-packages.list.details.overview'
  };

  beforeEach(angular.mock.module('openproject.wpButtons'));

  beforeEach(angular.mock.inject((_$state_, _$rootScope_, _keepTab_) => {
    $state = _$state_;
    $rootScope = _$rootScope_;
    keepTab = _keepTab_;
  }));

  describe('when initially invoked, or when an unsupported route is opened', () => {
    it('should have the correct default value for the currentShowTab', () => {
      expect(keepTab.currentShowTab).to.eq(defaults.showTab);
    });

    it('should have the correct default value for the currentDetailsTab', () => {
      expect(keepTab.currentDetailsTab).to.eq(defaults.detailsTab);
    });
  });

  describe('when opening a show route', () => {
    beforeEach(() => {
      var includes = sinon.stub($state, 'includes');
      includes.withArgs('work-packages.show.*').returns(true);
      includes.withArgs('work-packages.list.details.*').returns(false);

      $state.current.name = 'new-show-route';
      $rootScope.$emit('$stateChangeSuccess');
    });

    it('should update the currentShowTab value', () => {
      expect(keepTab.currentShowTab).to.eq('new-show-route');
    });

    it('should keep the previous value of currentDetailsTab', () => {
      expect(keepTab.currentDetailsTab).to.eq(defaults.detailsTab);
    });

    it('should propagate the previous change', () => {
      var cb = sinon.spy();

      var expected = {
        show: 'new-show-route',
        details: keepTab.currentDetailsTab
      }

      keepTab.observable.subscribe(cb);
      expect(cb).to.have.been.calledWith(expected);
    });
  });

  describe('when opening a details route', () => {
    beforeEach(() => {
      var includes = sinon.stub($state, 'includes');
      includes.withArgs('work-packages.list.details.*').returns(true);
      includes.withArgs('work-packages.show.*').returns(false);

      $state.current.name = 'new-details-route';
      $rootScope.$emit('$stateChangeSuccess');
    });

    it('should update the currentShowTab value', () => {
      expect(keepTab.currentDetailsTab).to.eq('new-details-route');
    });

    it('should keep the previous value of currentDetailsTab', () => {
      expect(keepTab.currentShowTab).to.eq(defaults.showTab);
    });

    it('should propagate the previous and next change', () => {
      var cb = sinon.spy();

      var expected = {
        details: 'new-details-route',
        show: keepTab.currentShowTab
      }

      keepTab.observable.subscribe(cb);
      expect(cb).to.have.been.calledWith(expected);

      $rootScope.$emit('$stateChangeSuccess');

      expect(cb).to.have.been.calledTwice;
    });

  });
});

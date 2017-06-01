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

  beforeEach(angular.mock.inject((_$state_:any, _$rootScope_:any, _keepTab_:any) => {
    $state = _$state_;
    $rootScope = _$rootScope_;
    keepTab = _keepTab_;
  }));

  describe('when initially invoked, or when an unsupported route is opened', () => {
    it('should have the correct default value for the currentShowTab', () => {
      expect(keepTab.currentShowState).to.eq(defaults.showTab);
      expect(keepTab.currentShowTab).to.eq('activity');
    });

    it('should have the correct default value for the currentDetailsTab', () => {
      expect(keepTab.currentDetailsState).to.eq(defaults.detailsTab);
      expect(keepTab.currentDetailsTab).to.eq('overview');
    });
  });

  describe('when opening a show route', () => {
    var includes:any;

    beforeEach(() => {
      includes = sinon.stub($state, 'includes');
      includes.withArgs('work-packages.show.*').returns(true);
      includes.withArgs('work-packages.list.details.*').returns(false);

      $state.current.name = 'work-packages.show.relations';
      $rootScope.$emit('$stateChangeSuccess');
    });

    it('should update the currentShowTab value', () => {
      expect(keepTab.currentShowState).to.eq('work-packages.show.relations');
    });

    it('should also update the value of currentDetailsTab', () => {
      expect(keepTab.currentDetailsState).to.eq('work-packages.list.details.relations');
    });

    it('should propagate the previous change', () => {
      var cb = sinon.spy();

      var expected = {
        active: 'relations',
        show: 'work-packages.show.relations',
        details: 'work-packages.list.details.relations'
      }

      keepTab.observable.subscribe(cb);
      expect(cb).to.have.been.calledWith(expected);
    });

    it('should correctly change when switching back', () => {
      includes.withArgs('work-packages.show.*').returns(false);
      includes.withArgs('work-packages.list.details.*').returns(true);

      $state.current.name = 'work-packages.list.details.overview';
      $rootScope.$emit('$stateChangeSuccess');


      expect(keepTab.currentShowState).to.eq('work-packages.show.activity');
      expect(keepTab.currentShowTab).to.eq('activity');
      expect(keepTab.currentDetailsState).to.eq('work-packages.list.details.overview');
      expect(keepTab.currentDetailsTab).to.eq('overview');
    });
  });

  describe('when opening show#activity', () => {
    beforeEach(() => {
      var includes = sinon.stub($state, 'includes');
      includes.withArgs('work-packages.show.*').returns(true);
      includes.withArgs('work-packages.list.details.*').returns(false);

      $state.current.name = 'work-packages.show.activity';
      $rootScope.$emit('$stateChangeSuccess', $state.current);
    });

    it('should set the tab to overview', () => {
      expect(keepTab.currentDetailsState).to.eq('work-packages.list.details.overview');
    });
  });

  describe('when opening a details route', () => {
    beforeEach(() => {
      var includes = sinon.stub($state, 'includes');
      includes.withArgs('work-packages.list.details.*').returns(true);
      includes.withArgs('work-packages.show.*').returns(false);

      $state.current.name = 'work-packages.list.details.activity';
      $rootScope.$emit('$stateChangeSuccess');
    });

    it('should update the currentShowTab value', () => {
      expect(keepTab.currentDetailsState).to.eq('work-packages.list.details.activity');
      expect(keepTab.currentDetailsTab).to.eq('activity');
    });

    it('should also update the value of currentDetailsTab', () => {
      expect(keepTab.currentShowState).to.eq('work-packages.show.activity');
      expect(keepTab.currentShowTab).to.eq('activity');
    });

    it('should propagate the previous and next change', () => {
      var cb = sinon.spy();

      var expected = {
        active: 'activity',
        details: 'work-packages.list.details.activity',
        show: 'work-packages.show.activity'
      };

      keepTab.observable.subscribe(cb);
      expect(cb).to.have.been.calledWith(expected);

      $rootScope.$emit('$stateChangeSuccess');

      expect(cb).to.have.been.calledTwice;
    });

  });
});

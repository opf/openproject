// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {KeepTabService} from './keep-tab.service';

describe('keepTab service', () => {
  let callback:(transition:any) => void;
  let includes = (path:string) => false;
  let $state:any;
  let $transitions:any;
  let keepTab:KeepTabService;
  let defaults:any;

  beforeEach(() => {
    $state = {
      current: {
        name: 'whatever',
      },
      includes: includes
    };

    $transitions = {
      onSuccess: (criteria:any, cb:(transition:any) => void) => callback = cb
    };

    keepTab = new KeepTabService($state, $transitions);

    defaults = {
      showTab: 'work-packages.show.activity',
      detailsTab: 'work-packages.partitioned.list.details.overview'
    };
  });

  describe('when initially invoked, or when an unsupported route is opened', () => {
    it('should have the correct default value for the currentShowTab', () => {
      expect(keepTab.currentShowState).toEqual(defaults.showTab);
      expect(keepTab.currentShowTab).toEqual('activity');
    });

    it('should have the correct default value for the currentDetailsTab', () => {
      expect(keepTab.currentDetailsState).toEqual(defaults.detailsTab);
      expect(keepTab.currentDetailsTab).toEqual('overview');
    });
  });

  describe('when opening a show route', () => {
    var currentPathPrefix = 'work-packages.show.*';

    beforeEach(() => {
      spyOn($state, 'includes').and.callFake((path:string) => {
        return path === currentPathPrefix;
      });

      $state.current.name = 'work-packages.show.relations';
      keepTab.updateTabs();
    });

    it('should update the currentShowTab value', () => {
      expect(keepTab.currentShowState).toEqual('work-packages.show.relations');
    });

    it('should also update the value of currentDetailsTab', () => {
      expect(keepTab.currentDetailsState).toEqual('work-packages.partitioned.list.details.relations');
    });

    it('should propagate the previous change', () => {
      var cb = jasmine.createSpy();

      var expected = {
        active: 'relations',
        show: 'work-packages.show.relations',
        details: 'work-packages.partitioned.list.details.relations'
      }

      keepTab.observable.subscribe(cb);
      expect(cb).toHaveBeenCalledWith(expected);
    });

    it('should correctly change when switching back', () => {
      currentPathPrefix = 'work-packages.partitioned.list.details.*';

      $state.current.name = 'work-packages.partitioned.list.details.overview';
      keepTab.updateTabs();

      expect(keepTab.currentShowState).toEqual('work-packages.show.activity');
      expect(keepTab.currentShowTab).toEqual('activity');
      expect(keepTab.currentDetailsState).toEqual('work-packages.partitioned.list.details.overview');
      expect(keepTab.currentDetailsTab).toEqual('overview');
    });
  });

  describe('when opening show#activity', () => {
    beforeEach(() => {
      spyOn($state, 'includes').and.callFake((path:string) => {
        return path === 'work-packages.show.*';
      });

      $state.current.name = 'work-packages.show.activity';
      keepTab.updateTabs('work-packages.show.activity');
    });

    it('should set the tab to overview', () => {
      expect(keepTab.currentDetailsState).toEqual('work-packages.partitioned.list.details.overview');
    });
  });

  describe('when opening a details route', () => {
    beforeEach(() => {
      spyOn($state, 'includes').and.callFake((path:string) => {
        return path === 'work-packages.partitioned.list.details.*';
      });

      $state.current.name = 'work-packages.partitioned.list.details.activity';
      keepTab.updateTabs();
    });

    it('should update the currentShowTab value', () => {
      expect(keepTab.currentDetailsState).toEqual('work-packages.partitioned.list.details.activity');
      expect(keepTab.currentDetailsTab).toEqual('activity');
    });

    it('should also update the value of currentDetailsTab', () => {
      expect(keepTab.currentShowState).toEqual('work-packages.show.activity');
      expect(keepTab.currentShowTab).toEqual('activity');
    });

    it('should propagate the previous and next change', () => {
      var cb = jasmine.createSpy();

      var expected = {
        active: 'activity',
        details: 'work-packages.partitioned.list.details.activity',
        show: 'work-packages.show.activity'
      };

      keepTab.observable.subscribe(cb);
      expect(cb).toHaveBeenCalledWith(expected);

      keepTab.updateTabs();

      expect(cb.calls.count()).toEqual(2);
    });

  });
});

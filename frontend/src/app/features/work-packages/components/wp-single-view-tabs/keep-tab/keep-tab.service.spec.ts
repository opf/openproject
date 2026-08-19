//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { TestBed } from '@angular/core/testing';
import {
  StateService,
  TransitionService,
  UIRouterGlobals,
} from '@uirouter/core';
import { KeepTabService } from './keep-tab.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';

describe('keepTab service', () => {
  let callback:(transition:any) => void;
  const includes = (path:string) => false;
  let $state:any;
  let $transitions:any;
  let uiRouterGlobals:any;
  let pathHelper:any;
  let currentProject:any;
  let keepTab:KeepTabService;
  let defaults:any;

  beforeEach(() => {
    $state = {
      current: {
        name: 'whatever',
      },
      includes,
    };

    $transitions = {
      onSuccess: (criteria:any, cb:(transition:any) => void) => callback = cb,
    };

    uiRouterGlobals = {
      params: { tabIdentifier: 'activity' },
    };

    TestBed.configureTestingModule({
      providers: [
        KeepTabService,
        /* eslint-disable @typescript-eslint/no-unsafe-assignment */
        { provide: StateService, useValue: $state },
        { provide: UIRouterGlobals, useValue: uiRouterGlobals },
        { provide: TransitionService, useValue: $transitions },
        { provide: PathHelperService, useValue: pathHelper },
        { provide: CurrentProjectService, useValue: currentProject },
        /* eslint-enable @typescript-eslint/no-unsafe-assignment */
      ],
    });

    keepTab = TestBed.inject(KeepTabService);

    defaults = {
      showTab: 'work-packages.show.tabs',
      detailsTab: 'work-packages.partitioned.list.details.tabs',
    };
  });

  describe('when initially invoked, or when an unsupported route is opened', () => {
    it('should have the correct default value for the currentShowTab', () => {
      expect(keepTab.currentShowTab).toEqual('activity');
    });

    it('should have the correct default value for the currentDetailsTab', () => {
      expect(keepTab.currentDetailsTab).toEqual('overview');
    });
  });

  describe('when opening a show route', () => {
    let currentPathPrefix = 'work-packages.show.*';

    beforeEach(() => {
      vi.spyOn($state, 'includes').mockImplementation((path:string) => path === currentPathPrefix);

      $state.current.name = 'work-packages.show.tabs';
      uiRouterGlobals.params.tabIdentifier = 'relations';
      keepTab.updateTabs();
    });

    it('should update the currentShowTab value', () => {
      expect(keepTab.currentShowTab).toEqual('relations');
    });

    it('should also update the value of currentDetailsTab', () => {
      expect(keepTab.currentShowTab).toEqual('relations');
    });

    it('should propagate the previous change', () => {
      const cb = vi.fn();

      const expected = {
        active: 'relations',
        show: 'relations',
        details: 'relations',
      };

      keepTab.observable.subscribe(cb);

      expect(cb).toHaveBeenCalledWith(expected);
    });

    it('should correctly change when switching back', () => {
      currentPathPrefix = '**.details.*';

      uiRouterGlobals.params.tabIdentifier = 'overview';
      keepTab.updateTabs();

      expect(keepTab.currentShowTab).toEqual('activity');
      expect(keepTab.currentDetailsTab).toEqual('overview');
    });
  });

  describe('when opening show#activity', () => {
    beforeEach(() => {
      vi.spyOn($state, 'includes').mockImplementation((path:string) => path === 'work-packages.show.*');

      uiRouterGlobals.params.tabIdentifier = 'activity';
      $state.current.name = 'work-packages.show.tabs';
      keepTab.updateTabs('activity');
    });

    it('should set the tab to overview', () => {
      expect(keepTab.currentDetailsTab).toEqual('overview');
    });
  });

  describe('when opening a details route', () => {
    beforeEach(() => {
      vi.spyOn($state, 'includes').mockImplementation((path:string) => path === '**.details.*');

      uiRouterGlobals.params.tabIdentifier = 'activity';
      $state.current.name = 'work-packages.partitioned.list.details.tabs';
      keepTab.updateTabs();
    });

    it('should update the currentShowTab value', () => {
      expect(keepTab.currentDetailsTab).toEqual('activity');
    });

    it('should also update the value of currentDetailsTab', () => {
      expect(keepTab.currentShowTab).toEqual('activity');
    });

    it('should propagate the previous and next change', () => {
      const cb = vi.fn();

      const expected = {
        active: 'activity',
        details: 'activity',
        show: 'activity',
      };

      keepTab.observable.subscribe(cb);

      expect(cb).toHaveBeenCalledWith(expected);

      keepTab.updateTabs();

      expect(vi.mocked(cb).mock.calls.length).toEqual(2);
    });
  });
});

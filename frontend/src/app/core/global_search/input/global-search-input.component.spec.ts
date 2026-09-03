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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { MeetingResource } from 'core-app/features/hal/resources/meeting-resource';
import { WikiPageResource } from 'core-app/features/hal/resources/wiki-page-resource';
import {
  GlobalSearchInputComponent,
  lastUpdatedRange,
  searchResultMatchesType,
} from './global-search-input.component';

describe('lastUpdatedRange', () => {
  const now = new Date(2026, 8, 5, 14, 30);
  const startOfToday = new Date(2026, 8, 5);

  it('does not add a range for any time', () => {
    expect(lastUpdatedRange('any_time', now)).toBeUndefined();
  });

  it('uses the local start of today for today', () => {
    expect(lastUpdatedRange('today', now)).toEqual([
      startOfToday.toISOString(),
      '',
    ]);
  });

  it('bounds yesterday between two local midnights', () => {
    expect(lastUpdatedRange('yesterday', now)).toEqual([
      new Date(2026, 8, 4).toISOString(),
      startOfToday.toISOString(),
    ]);
  });

  it('includes today in the rolling day presets', () => {
    expect(lastUpdatedRange('past_7_days', now)?.[0]).toBe(
      new Date(2026, 7, 30).toISOString(),
    );
    expect(lastUpdatedRange('past_30_days', now)?.[0]).toBe(
      new Date(2026, 7, 7).toISOString(),
    );
  });
});

describe('searchResultMatchesType', () => {
  const workPackage = Object.create(WorkPackageResource.prototype) as WorkPackageResource;
  const meeting = Object.create(MeetingResource.prototype) as MeetingResource;
  const wikiPage = Object.create(WikiPageResource.prototype) as WikiPageResource;

  it('shows every resource in the all tab', () => {
    expect([workPackage, meeting, wikiPage].every((item) => searchResultMatchesType('all', item))).toBe(true);
  });

  it('shows only work packages in the work packages tab', () => {
    expect(searchResultMatchesType('work_packages', workPackage)).toBe(true);
    expect(searchResultMatchesType('work_packages', meeting)).toBe(false);
    expect(searchResultMatchesType('work_packages', wikiPage)).toBe(false);
  });

  it('shows only the selected content type in the other tabs', () => {
    expect(searchResultMatchesType('meetings', meeting)).toBe(true);
    expect(searchResultMatchesType('meetings', wikiPage)).toBe(false);
    expect(searchResultMatchesType('wiki_pages', wikiPage)).toBe(true);
    expect(searchResultMatchesType('wiki_pages', meeting)).toBe(false);
  });
});

// followItem is verified through the prototype against a stand-in context, avoiding
// a real component instance whose many injected dependencies this branch never uses.
describe('GlobalSearchInputComponent#followItem', () => {
  let wpPathArgs:string[];
  let context:Pick<
    GlobalSearchInputComponent,
    'wpPath'|'selectedItem'|'isWorkPackage'|'isMeeting'|'isWikiPage'
  >;

  function callFollowItem(item:Parameters<GlobalSearchInputComponent['followItem']>[0]):void {
    GlobalSearchInputComponent.prototype.followItem.call(context, item);
  }

  beforeEach(() => {
    wpPathArgs = [];
    context = {
      wpPath: (id:string):string => {
        wpPathArgs.push(id);
        // A fragment keeps followItem's window.location assignment from navigating the runner.
        return '#stub';
      },
      selectedItem: undefined,
      isWorkPackage: (item):item is WorkPackageResource => item instanceof WorkPackageResource,
      isMeeting: (_item):_item is MeetingResource => false,
      isWikiPage: (_item):_item is WikiPageResource => false,
    };
  });

  describe('when item is a work package resource', () => {
    // Build a real WorkPackageResource off its prototype and feed it a HAL $source,
    // so followItem exercises the production displayId getter rather than a stub.
    function buildWorkPackage(source:{ id:number, displayId?:string }):WorkPackageResource {
      const item = Object.create(WorkPackageResource.prototype) as WorkPackageResource;
      item.$source = source;
      return item;
    }

    it('is recognised as a HalResource', () => {
      expect(buildWorkPackage({ id: 42 }) instanceof HalResource).toBe(true);
    });

    describe('in semantic mode (source carries a semantic displayId)', () => {
      let item:WorkPackageResource;

      beforeEach(() => {
        item = buildWorkPackage({ id: 42, displayId: 'PROJ-42' });
      });

      it('navigates via the semantic displayId, not the numeric id', () => {
        callFollowItem(item);
        expect(wpPathArgs).toEqual(['PROJ-42']);
        expect(wpPathArgs).not.toContain('42');
      });

      it('sets selectedItem to the item', () => {
        callFollowItem(item);
        expect(context.selectedItem).toBe(item);
      });
    });

    describe('in classic mode (source has only the numeric id)', () => {
      it('falls back to the numeric id through displayId', () => {
        callFollowItem(buildWorkPackage({ id: 42 }));
        expect(wpPathArgs).toEqual(['42']);
      });
    });
  });

  describe('when item is undefined', () => {
    it('does nothing', () => {
      callFollowItem(undefined);
      expect(wpPathArgs).toEqual([]);
    });
  });
});

describe('GlobalSearchInputComponent#onFocusOut', () => {
  it('keeps the search open when focus moves to the project scope selector', () => {
    const componentElement = document.createElement('div');
    const projectScopeSelect = document.createElement('select');
    componentElement.append(projectScopeSelect);

    let setOpenCalled = false;
    const context = {
      elementRef: { nativeElement: componentElement },
      ngSelectComponent: {
        ngSelectInstance: {
          isOpen: {
            set: (_value:boolean):void => {
              setOpenCalled = true;
            },
          },
        },
      },
    };
    const event = { relatedTarget: null } as unknown as FocusEvent;
    const mouseDownEvent = new MouseEvent('mousedown');

    GlobalSearchInputComponent.prototype.onProjectScopeMouseDown.call(
      context as unknown as GlobalSearchInputComponent,
      mouseDownEvent,
    );

    GlobalSearchInputComponent.prototype.onFocusOut.call(
      context as unknown as GlobalSearchInputComponent,
      event,
    );

    expect(setOpenCalled).toBe(false);
  });
});

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

import { createEnvironmentInjector, EnvironmentInjector } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { EMPTY, of, Subject } from 'rxjs';
import { States } from 'core-app/core/states/states.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackagesFullViewComponent } from '../../wp-full-view/wp-full-view.component';
import { WorkPackageSplitViewComponent } from '../../wp-split-view/wp-split-view.component';
import { WorkPackagesViewBase } from '../work-packages-view.base';
import { WorkPackageCreateComponent } from '../../../components/wp-new/wp-create.component';
import { WorkPackageInlineCreateComponent } from '../../../components/wp-inline-create/wp-inline-create.component';
import { WorkPackageViewSelectionService } from './wp-view-selection.service';
import { WorkPackageViewSelectionGesturesService } from './wp-view-selection-gestures.service';
import { WorkPackageViewFocusService, WPFocusState } from './wp-view-focus.service';

function fromPrototype<T extends object>(prototype:T, properties:Record<string, unknown>):T {
  return Object.assign(Object.create(prototype) as T, properties);
}

describe('WorkPackageViewFocusService', () => {
  let selection:WorkPackageViewSelectionService;
  let focus:WorkPackageViewFocusService;
  let states:States;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        States,
        IsolatedQuerySpace,
        WorkPackageViewSelectionService,
        WorkPackageViewSelectionGesturesService,
        WorkPackageViewFocusService,
        { provide: OPContextMenuService, useValue: { close: () => undefined } },
      ],
    });
    selection = TestBed.inject(WorkPackageViewSelectionService);
    focus = TestBed.inject(WorkPackageViewFocusService);
    states = TestBed.inject(States);
  });

  const rows:RenderedWorkPackage[] = ['1', '2', '3', '4'].map((id) => ({
    workPackageId: id, classIdentifier: `wp-row-${id}`, hidden: false,
  }));

  it('never selects through an ordinary focus update', () => {
    focus.updateFocus('2');
    expect(selection.isEmpty).toBe(true);
  });

  it('initializes selection only when empty and publishes it before focus', () => {
    const membersAtFocus:string[][] = [];
    focus.live$().subscribe(() => membersAtFocus.push(selection.getSelectedWorkPackageIds()));
    focus.initializeSelectionAndFocus('1');
    focus.initializeSelectionAndFocus('2');
    expect(selection.getSelectedWorkPackageIds()).toEqual(['1']);
    expect(membersAtFocus).toEqual([['1'], ['1']]);
  });

  it('keeps a deliberate empty selection through focus and ranges from its anchor', () => {
    const gestures = TestBed.inject(WorkPackageViewSelectionGesturesService);
    gestures.handleClick('2', rows, {});
    gestures.handleClick('2', rows, { ctrlKey: true });
    focus.updateFocus('3');
    expect(selection.isEmpty).toBe(true);
    gestures.handleClick('4', rows, { shiftKey: true });
    expect(selection.getSelectedWorkPackageIds()).toEqual(['2', '3', '4']);
  });

  it('selects a created work package after the last member was toggled off', () => {
    const gestures = TestBed.inject(WorkPackageViewSelectionGesturesService);
    gestures.handleClick('2', rows, {});
    gestures.handleClick('2', rows, { ctrlKey: true });
    focus.initializeSelectionAndFocus('3', false, false);
    expect(selection.getSelectedWorkPackageIds()).toEqual(['3']);
    expect(focus.isFocused('3')).toBe(true);
  });

  it('leaves a batch untouched when a work package is created into it', () => {
    const gestures = TestBed.inject(WorkPackageViewSelectionGesturesService);
    gestures.handleClick('1', rows, {});
    gestures.handleClick('3', rows, { shiftKey: true });
    focus.initializeSelectionAndFocus('4');
    expect(selection.getSelectedWorkPackageIds()).toEqual(['1', '2', '3']);
    gestures.handleClick('2', rows, { shiftKey: true });
    expect(selection.getSelectedWorkPackageIds()).toEqual(['1', '2']);
  });

  it('initializes a detail scope without touching the list scope', () => {
    const gestures = TestBed.inject(WorkPackageViewSelectionGesturesService);
    gestures.handleClick('2', rows, {});
    gestures.handleClick('2', rows, { ctrlKey: true });

    const detailInjector = createEnvironmentInjector(
      [IsolatedQuerySpace, WorkPackageViewSelectionService, WorkPackageViewFocusService],
      TestBed.inject(EnvironmentInjector),
    );
    const detailSelection = detailInjector.get(WorkPackageViewSelectionService);
    detailInjector.get(WorkPackageViewFocusService).initializeSelectionAndFocus('2', false);

    expect(detailSelection.getSelectedWorkPackageIds()).toEqual(['2']);
    expect(selection.isEmpty).toBe(true);
    gestures.handleClick('4', rows, { shiftKey: true });
    expect(selection.getSelectedWorkPackageIds()).toEqual(['2', '3', '4']);
    detailInjector.destroy();
  });

  describe.each([false, true])('initialization with existing selection: %s', (alreadySelected) => {
    let expected:string[];
    let observed:WPFocusState[];
    let observedMembers:string[][];
    const workPackage = {
      id: '2', displayId: 'PROJ-2', project: { id: '1', identifier: 'proj' },
      $links: { project: { href: '/api/v3/projects/1' } },
      __initialized_at: 123,
    } as unknown as WorkPackageResource;

    beforeEach(() => {
      const initial = alreadySelected ? ['1'] : [];
      selection.initializeSelection(initial);
      if (!alreadySelected) {
        const gestures = TestBed.inject(WorkPackageViewSelectionGesturesService);
        gestures.handleClick('3', rows, {});
        gestures.handleClick('3', rows, { ctrlKey: true });
      }
      expected = initial.length ? initial : ['2'];
      observed = [];
      observedMembers = [];
      focus.live$().subscribe((state) => {
        observedMembers.push(selection.getSelectedWorkPackageIds());
        observed.push(state);
      });
    });

    function focusResult() {
      return {
        members: selection.getSelectedWorkPackageIds(),
        atFocus: observedMembers,
        states: observed,
        rangeAfter: rangeAfterInitialization(),
      };
    }

    function rangeAfterInitialization():string[] {
      const gestures = TestBed.inject(WorkPackageViewSelectionGesturesService);
      gestures.handleClick('4', rows, { shiftKey: true });
      return selection.getSelectedWorkPackageIds();
    }

    function expectedFocus(navigate = true) {
      return {
        members: expected,
        atFocus: [expected],
        states: [{ workPackageId: '2', focusAfterRender: false, navigate }],
        rangeAfter: ['4'],
      };
    }

    function singleViewProperties() {
      return {
        workPackage,
        workPackageId: 'PROJ-2',
        wpTableSelection: selection,
        wpTableFocus: focus,
        apiV3Service: { projects: { id: () => ({ requireAndStream: () => of({}) }) } },
        projectsResourceService: { requireEntity: () => EMPTY },
        cdRef: { detectChanges: () => undefined },
        storeService: { hasNotifications$: of(false), setFilters: () => undefined },
        authorisationService: { initModelAuth: () => undefined },
        PathHelper: { workPackagePath: () => '/work_packages/PROJ-2' },
        keepTab: { observable: EMPTY },
        untilDestroyed: () => (source:unknown) => source,
        recentItemsService: { add: () => undefined },
        currentUserService: {
          hasCapabilities$: () => of(false),
          isLoggedInAndHasCapabalities$: () => of(false),
        },
      };
    }

    it('selects before full-view init emits focus', () => {
      const component = fromPrototype(WorkPackagesFullViewComponent.prototype, singleViewProperties());
      (component as unknown as { init():void }).init();
      expect(focusResult()).toEqual(expectedFocus());
    });

    it('selects before split-view init emits focus', () => {
      const component = fromPrototype(WorkPackageSplitViewComponent.prototype, singleViewProperties());
      (component as unknown as { init():void }).init();
      expect(focusResult()).toEqual(expectedFocus());
    });

    it('selects the newly created work package open in details before focusing', () => {
      states.workPackages.get('2').putValue(workPackage);
      const component = fromPrototype(WorkPackagesViewBase.prototype, {
        states,
        wpTableFocus: focus,
        urlParams: { currentDetailsRouteParams: () => ({ routingId: 'PROJ-2' }) },
      });
      const caller = component as unknown as {
        focusNewlyCreatedWorkPackageIfOpenInDetails(events:{ eventType:string, id:string }[]):void;
      };
      caller.focusNewlyCreatedWorkPackageIfOpenInDetails([{ eventType: 'created', id: '2' }]);
      expect(focusResult()).toEqual(expectedFocus(false));
    });

    it('selects after the save transition before emitting focus', async () => {
      const transition = Promise.resolve();
      const component = fromPrototype(WorkPackageCreateComponent.prototype, {
        routedFromAngular: true,
        successState: 'work-packages.partitioned.list.details',
        $state: { go: () => transition },
        wpTableSelection: selection,
        wpViewFocus: focus,
        notificationService: { showSave: () => undefined },
      });
      component.onSaved({ savedResource: workPackage, isInitial: true });
      expect(observed).toEqual([]);
      await transition;
      expect(focusResult()).toEqual(expectedFocus());
    });

    it('selects inline creation before emitting focus', () => {
      const created = new Subject<WorkPackageResource>();
      const component = fromPrototype(WorkPackageInlineCreateComponent.prototype, {
        currentWorkPackage: workPackage,
        wpCreate: { onNewWorkPackage: () => created },
        untilDestroyed: () => (source:unknown) => source,
        resetRow: () => undefined,
        table: { configuration: { isEmbedded: false } },
        wpTableSelection: selection,
        wpTableFocus: focus,
        wpInlineCreate: { newInlineWorkPackageCreated: new Subject<string>() },
        cdRef: { detectChanges: () => undefined },
      });
      (component as unknown as { registerCreationCallback():void }).registerCreationCallback();
      created.next(workPackage);
      created.complete();
      expect(focusResult()).toEqual(expectedFocus());
    });
  });
});

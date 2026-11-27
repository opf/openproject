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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Component, NO_ERRORS_SCHEMA } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { screen, waitFor } from '@testing-library/dom';
import { EMPTY, Observable, of, Subject } from 'rxjs';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HAL_NEW_RESOURCE_ID } from 'core-app/features/hal/helpers/is-new-resource';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { WorkPackageViewFocusService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { AutofocusDirective } from 'core-app/shared/directives/focus/autofocus.directive';
import { FocusHelperService } from 'core-app/shared/directives/focus/focus-helper';
import { WorkPackageCreateService } from '../wp-new/wp-create.service';
import { WorkPackageTableConfigurationObject } from '../wp-table/wp-table-configuration';
import { runMutation } from '../wp-fast-table/testing/table-harness';
import { buildWorkPackage } from '../wp-fast-table/testing/work-package-fixture';
import { WorkPackageTableEditingContext } from '../wp-fast-table/wp-table-editing';
import { WorkPackageInlineCreateComponent } from './wp-inline-create.component';
import { WorkPackageInlineCreateService } from './wp-inline-create.service';

@Component({
  template: '<button type="button">Cancel reference</button>',
  standalone: false,
})
class ReferenceStubComponent {}

describe('WorkPackageInlineCreateComponent', () => {
  const mount = ({
    created = EMPTY,
    focus = {},
    configuration = {},
    stopEditing = vi.fn(),
  }:{ created?:Observable<WorkPackageResource>, focus?:Partial<WorkPackageViewFocusService>, configuration?:WorkPackageTableConfigurationObject, stopEditing?:WorkPackageTableEditingContext['stopEditing'] } = {}) => {
    TestBed.configureTestingModule({
      declarations: [WorkPackageInlineCreateComponent, ReferenceStubComponent, AutofocusDirective],
      schemas: [NO_ERRORS_SCHEMA],
      providers: [
        {
          provide: WorkPackageInlineCreateService,
          useValue: {
            canAdd: of(true),
            canReference: of(true),
            referenceComponentClass: ReferenceStubComponent,
            buttonTexts: { create: 'Create new child', reference: 'Add existing' },
            newInlineWorkPackageCreated: new Subject<string>(),
          },
        },
        {
          provide: WorkPackageCreateService,
          useValue: {
            onNewWorkPackage: () => created,
            cancelCreation: () => undefined,
            createOrContinueWorkPackage: () => new Promise(() => undefined),
          },
        },
        { provide: WorkPackageViewColumnsService, useValue: { updates$: () => EMPTY } },
        { provide: WorkPackageViewFocusService, useValue: focus },
        { provide: HalResourceEditingService, useValue: {} },
        { provide: AuthorisationService, useValue: {} },
        { provide: SchemaCacheService, useValue: {} },
        { provide: IsolatedQuerySpace, useValue: {} },
        { provide: I18nService, useValue: { t: (key:string) => key } },
      ],
    });

    const fixture = TestBed.createComponent(WorkPackageInlineCreateComponent);
    fixture.componentRef.setInput('table', {
      configuration,
      mutate: runMutation,
      keyboardNavigation: { rememberWorkPackageAfterRender: () => undefined },
      editing: { stopEditing },
    });
    fixture.componentRef.setInput('colspan', 3);
    fixture.detectChanges();
    return fixture;
  };

  afterEach(() => TestBed.resetTestingModule());

  function adoptCreation(fixture:ComponentFixture<WorkPackageInlineCreateComponent>, workPackage:WorkPackageResource):void {
    (fixture.componentInstance as unknown as { currentWorkPackage:WorkPackageResource }).currentWorkPackage = workPackage;
  }

  it.each([
    ['selects', 'enabled', true, 1],
    ['does not select', 'disabled', false, 0],
  ])('%s a created work package when selection is %s', (_verb, _state, selectionEnabled, calls) => {
    const created = new Subject<WorkPackageResource>();
    const focus = { initializeSelectionAndFocus: vi.fn() };
    const fixture = mount({ created, focus, configuration: { isEmbedded: false, selectionEnabled } });
    const workPackage = Object.assign(buildWorkPackage({ id: '7' }), { __initialized_at: 1 });
    adoptCreation(fixture, workPackage);

    created.next(workPackage);

    expect(focus.initializeSelectionAndFocus).toHaveBeenCalledTimes(calls);
  });

  it('names the create and reference triggers by their own texts', () => {
    mount();

    expect(screen.getByRole('button', { name: 'Create new child' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Add existing' })).toBeInTheDocument();
  });

  it('returns focus to the create trigger after the create row resets', async () => {
    const fixture = mount();
    fixture.componentInstance.hideRow();

    fixture.componentInstance.resetRow();

    await waitFor(() => expect(screen.getByRole('button', { name: 'Create new child' })).toHaveFocus());
  });

  it('renders no trigger row while its button row is hidden', () => {
    const fixture = mount();

    fixture.componentRef.setInput('buttonRowHidden', true);
    fixture.detectChanges();

    expect(screen.queryByRole('button')).not.toBeInTheDocument();
  });

  it.each([
    ['asks the host to return focus', true, 1],
    ['keeps focus on its own trigger', false, 0],
  ])('%s after the create row resets (button row hidden: %s)', async (_verb, buttonRowHidden, calls) => {
    const fixture = mount();
    fixture.componentRef.setInput('buttonRowHidden', buttonRowHidden);
    const returnFocus = vi.fn();
    fixture.componentInstance.returnFocus.subscribe(returnFocus);
    fixture.componentInstance.hideRow();

    fixture.componentInstance.resetRow();

    await waitFor(() => expect(fixture.componentInstance.mode()).toBe('inactive'));
    expect(returnFocus).toHaveBeenCalledTimes(calls);
  });

  it('focuses the create trigger once when its button row returns after a handoff', async () => {
    const fixture = mount();
    fixture.componentRef.setInput('buttonRowHidden', true);
    fixture.detectChanges();

    fixture.componentInstance.focusCreateTrigger();
    fixture.componentRef.setInput('buttonRowHidden', false);
    fixture.detectChanges();

    await waitFor(() => expect(screen.getByRole('button', { name: 'Create new child' })).toHaveFocus());

    const focus = vi.spyOn(TestBed.inject(FocusHelperService), 'focus');
    fixture.componentRef.setInput('buttonRowHidden', true);
    fixture.detectChanges();
    fixture.componentRef.setInput('buttonRowHidden', false);
    fixture.detectChanges();

    expect(screen.getByRole('button', { name: 'Create new child' })).toBeInTheDocument();
    expect(focus).not.toHaveBeenCalled();
  });

  it('returns focus to the reference trigger when the reference row is cancelled from within', async () => {
    const fixture = mount();
    fixture.componentInstance.handleReferenceClick();
    screen.getByRole('button', { name: 'Cancel reference' }).focus();

    fixture.componentInstance.resetRow();

    await waitFor(() => expect(screen.getByRole('button', { name: 'Add existing' })).toHaveFocus());
  });

  it('leaves focus where the user moved it before the create row reset settles', async () => {
    const fixture = mount();
    const returnFocus = vi.fn();
    fixture.componentInstance.returnFocus.subscribe(returnFocus);
    const focus = vi.spyOn(TestBed.inject(FocusHelperService), 'focus');
    fixture.componentInstance.hideRow();

    fixture.componentInstance.resetRow();
    const elsewhere = document.createElement('button');
    document.body.append(elsewhere);
    elsewhere.focus();

    await waitFor(() => expect(fixture.componentInstance.mode()).toBe('inactive'));
    expect(focus).not.toHaveBeenCalled();
    expect(returnFocus).not.toHaveBeenCalled();
    expect(elsewhere).toHaveFocus();
    elsewhere.remove();
  });

  it('reports itself occupied once when the reference row opens', () => {
    const fixture = mount();
    const occupied = vi.fn();
    fixture.componentInstance.occupiedChange.subscribe(occupied);

    fixture.componentInstance.handleReferenceClick();

    expect(occupied.mock.calls).toEqual([[true]]);
    expect(fixture.componentInstance.occupied()).toBe(true);
  });

  it('reports itself unoccupied once the reset settles', async () => {
    const fixture = mount();
    fixture.componentInstance.handleReferenceClick();
    const occupied = vi.fn();
    fixture.componentInstance.occupiedChange.subscribe(occupied);

    fixture.componentInstance.resetRow();

    await waitFor(() => expect(fixture.componentInstance.mode()).toBe('inactive'));
    expect(occupied.mock.calls).toEqual([[false]]);
  });

  describe('after saving from an empty table', () => {
    const saved = Object.assign(buildWorkPackage({ id: '7' }), { __initialized_at: 1 });

    function saveFromEmptyTable() {
      const created = new Subject<WorkPackageResource>();
      const fixture = mount({ created });
      fixture.componentRef.setInput('buttonRowHidden', true);
      fixture.detectChanges();
      fixture.componentInstance.handleReferenceClick();
      fixture.componentInstance.hideRow();
      fixture.componentInstance.focusTarget = 'create';
      adoptCreation(fixture, saved);
      const returnFocus = vi.fn();
      fixture.componentInstance.returnFocus.subscribe(returnFocus);
      created.next(saved);
      return { fixture, returnFocus };
    }

    it('stays occupied and offers a focused Create trigger until results render', async () => {
      const { fixture, returnFocus } = saveFromEmptyTable();

      await waitFor(() => expect(screen.getByRole('button', { name: 'Create new child' })).toHaveFocus());

      expect(fixture.componentInstance.occupied()).toBe(true);
      expect(returnFocus).not.toHaveBeenCalled();
    });

    it('hands the trigger and its focus back to the host once results render', async () => {
      const { fixture, returnFocus } = saveFromEmptyTable();
      await waitFor(() => expect(screen.getByRole('button', { name: 'Create new child' })).toHaveFocus());

      fixture.componentInstance.resultsRendered();
      fixture.detectChanges();

      expect(fixture.componentInstance.occupied()).toBe(false);
      expect(screen.queryByRole('button', { name: 'Create new child' })).not.toBeInTheDocument();
      expect(returnFocus).toHaveBeenCalledTimes(1);
    });

    it.each([
      [1, 0],
      [0, 1],
    ])('settles once when %s results render before the reset: focus return %s times', async (count, calls) => {
      const { fixture, returnFocus } = saveFromEmptyTable();

      fixture.componentInstance.resultsRendered();
      if (count > 0) {
        fixture.componentRef.setInput('buttonRowHidden', false);
        fixture.detectChanges();
      }

      await waitFor(() => expect(fixture.componentInstance.mode()).toBe('inactive'));
      expect(fixture.componentInstance.occupied()).toBe(false);
      expect(returnFocus).toHaveBeenCalledTimes(calls);
    });

    it('gives the blankslate back while another create starts during the wait', async () => {
      const { fixture } = saveFromEmptyTable();
      await waitFor(() => expect(screen.getByRole('button', { name: 'Create new child' })).toBeInTheDocument());

      fixture.componentInstance.handleAddRowClick();

      expect(fixture.componentInstance.occupied()).toBe(false);
    });

    it('asks for focus return when results remove its trigger before the autofocus lands', () => {
      vi.useFakeTimers();
      try {
        const { fixture, returnFocus } = saveFromEmptyTable();
        vi.advanceTimersByTime(50);
        expect(screen.getByRole('button', { name: 'Create new child' })).toBeInTheDocument();

        fixture.componentInstance.resultsRendered();

        expect(returnFocus).toHaveBeenCalledTimes(1);
      } finally {
        vi.useRealTimers();
      }
    });

    it('asks for focus return when another create displaces its focused stand-in trigger', async () => {
      const { fixture, returnFocus } = saveFromEmptyTable();
      await waitFor(() => expect(screen.getByRole('button', { name: 'Create new child' })).toHaveFocus());

      fixture.componentInstance.handleAddRowClick();

      expect(returnFocus).toHaveBeenCalledTimes(1);
    });

    it('leaves focus alone once its stand-in autofocus has landed and the user moved away', async () => {
      const { fixture, returnFocus } = saveFromEmptyTable();
      await waitFor(() => expect(screen.getByRole('button', { name: 'Create new child' })).toHaveFocus());
      screen.getByRole('button', { name: 'Create new child' }).blur();

      fixture.componentInstance.resultsRendered();

      expect(returnFocus).not.toHaveBeenCalled();
    });

    it('forgets the pending save once a new create row is cancelled', async () => {
      const { fixture, returnFocus } = saveFromEmptyTable();
      await waitFor(() => expect(fixture.componentInstance.mode()).toBe('inactive'));

      fixture.componentInstance.handleAddRowClick();
      fixture.componentInstance.hideRow();
      fixture.componentInstance.resetRow();

      await waitFor(() => expect(fixture.componentInstance.mode()).toBe('inactive'));
      expect(returnFocus).toHaveBeenCalledTimes(1);
      expect(fixture.componentInstance.occupied()).toBe(false);
    });
  });

  it.each([
    ['not showing while its button row is hidden', false, false],
    ['showing while an open row stands in for its hidden button row', true, true],
  ])('reports %s', async (_state, occupied, expected) => {
    const fixture = mount();
    const showing = vi.fn();
    fixture.componentInstance.showing.subscribe(showing);
    fixture.componentRef.setInput('buttonRowHidden', true);
    fixture.detectChanges();

    if (occupied) fixture.componentInstance.handleReferenceClick();

    await waitFor(() => expect(showing).toHaveBeenLastCalledWith(expected));
  });

  it('leaves focus where the user moved it during the autofocus delay', async () => {
    const fixture = mount();
    fixture.componentRef.setInput('buttonRowHidden', true);
    fixture.detectChanges();
    const elsewhere = document.createElement('button');
    document.body.append(elsewhere);

    fixture.componentInstance.focusCreateTrigger();
    fixture.componentRef.setInput('buttonRowHidden', false);
    fixture.detectChanges();
    elsewhere.focus();
    await new Promise((resolve) => { setTimeout(resolve, 50); });

    expect(elsewhere).toHaveFocus();
    elsewhere.remove();
  });

  it('reports nothing once destroyed while occupied', () => {
    const fixture = mount();
    fixture.componentInstance.handleReferenceClick();
    const warn = vi.spyOn(console, 'warn');

    fixture.destroy();

    expect(warn).not.toHaveBeenCalled();
  });

  it('stops editing the new work package when the create row resets', () => {
    const stopEditing = vi.fn();
    const fixture = mount({ stopEditing });

    fixture.componentInstance.resetRow();

    expect(stopEditing).toHaveBeenCalledWith(HAL_NEW_RESOURCE_ID);
  });
});

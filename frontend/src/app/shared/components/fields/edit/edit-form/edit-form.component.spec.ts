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
import { StateService, Transition, TransitionService } from '@uirouter/core';
import * as Turbo from '@hotwired/turbo';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { EditingPortalService } from 'core-app/shared/components/fields/edit/editing-portal/editing-portal-service';
import { EditFieldHandler } from 'core-app/shared/components/fields/edit/editing-portal/edit-field-handler';
import { EditFormRoutingService } from 'core-app/shared/components/fields/edit/edit-form/edit-form-routing.service';
import { EditFormComponent } from 'core-app/shared/components/fields/edit/edit-form/edit-form.component';
import { GlobalEditFormChangesTrackerService } from 'core-app/shared/components/fields/edit/services/global-edit-form-changes-tracker/global-edit-form-changes-tracker.service';
import { vi } from 'vitest';

describe('EditFormComponent', () => {
  let onBeforeCallback:(transition:Transition) => unknown;

  afterEach(() => {
    vi.restoreAllMocks();
  });

  beforeEach(async () => {
    await TestBed
      .configureTestingModule({
        declarations: [
          EditFormComponent,
        ],
        providers: [
          {
            provide: TransitionService,
            useValue: {
              onBefore: vi.fn((_criteria:unknown, callback:(transition:Transition) => unknown) => {
                onBeforeCallback = callback;
                return vi.fn();
              }),
            },
          },
          { provide: ConfigurationService, useValue: { warnOnLeavingUnsaved: vi.fn().mockReturnValue(true) } },
          { provide: EditingPortalService, useValue: {} },
          { provide: StateService, useValue: {} },
          { provide: I18nService, useValue: { t: vi.fn().mockReturnValue('Leave edit mode?') } },
          { provide: EditFormRoutingService, useValue: { blockedTransition: vi.fn().mockReturnValue(true) } },
          {
            provide: GlobalEditFormChangesTrackerService,
            useValue: {
              addToActiveForms: vi.fn(),
              removeFromActiveForms: vi.fn(),
            },
          },
        ],
      })
      .compileComponents();
  });

  it('restores a canceled browser Back transition without navigating forward', () => {
    const fixture = TestBed.createComponent(EditFormComponent);
    const component = fixture.componentInstance;
    const urlRouterUpdate = vi.fn();
    const transition = {
      options: vi.fn().mockReturnValue({ source: 'url' }),
      from: vi.fn().mockReturnValue({ name: 'work-packages.partitioned.split' }),
      params: vi.fn().mockReturnValue({ workPackageId: '46' }),
      router: {
        stateService: {
          href: vi.fn().mockReturnValue('/work_packages/details/46/overview'),
        },
        urlRouter: {
          update: urlRouterUpdate,
        },
      },
    } as unknown as Transition;
    const turboPush = vi.spyOn(
      Turbo.session.history,
      'push',
    ).mockImplementation(() => undefined);
    const historyForward = vi.spyOn(window.history, 'forward');
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(false);
    const cancel = vi.spyOn(component, 'cancel');

    component.activeFields = {
      description: {} as EditFieldHandler,
    };

    expect(onBeforeCallback(transition)).toBe(false);
    expect(confirm).toHaveBeenCalledWith('Leave edit mode?');
    expect(cancel).not.toHaveBeenCalled();
    expect(turboPush).toHaveBeenCalledOnce();
    expect(turboPush.mock.calls[0][0].pathname).toBe('/work_packages/details/46/overview');
    expect(urlRouterUpdate).toHaveBeenCalledWith(true);
    expect(historyForward).not.toHaveBeenCalled();
  });
});

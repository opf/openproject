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

import { ChangeDetectorRef, ElementRef } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { BehaviorSubject, of, Subject } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { DeviceService } from 'core-app/core/browser/device.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import {
  OpEditingPortalChangesetToken,
  OpEditingPortalHandlerToken,
  OpEditingPortalSchemaToken,
} from 'core-app/shared/components/fields/edit/edit-field.component';
import { DatePickerEditFieldComponent } from './date-picker-edit-field.component';

class TestDateField extends DatePickerEditFieldComponent {}

describe('DatePickerEditFieldComponent', () => {
  let resolveForm:() => void;
  let modalService:{ show:ReturnType<typeof vi.fn>, activeModalInstance$:BehaviorSubject<unknown> };

  const build = () => {
    const modal = { closingEvent: new Subject<void>(), element: document.createElement('div'), closeMe: vi.fn() };
    modalService = { show: vi.fn(() => of(modal)), activeModalInstance$: new BehaviorSubject<unknown>(null) };
    const changeset = {
      projectedResource: {},
      schema: { ofProperty: () => ({}), mappedName: (name:string) => name, isMilestone: false },
      getForm: () => new Promise<void>((resolve) => { resolveForm = resolve; }),
      state: null,
    };
    const handler = { fieldName: 'startDate', registerOverlay: vi.fn(() => () => undefined), deactivate: vi.fn(), inEditMode: false };
    TestBed.configureTestingModule({
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: ElementRef, useValue: new ElementRef(document.createElement('div')) },
        { provide: OpEditingPortalChangesetToken, useValue: changeset },
        { provide: OpEditingPortalSchemaToken, useValue: {} },
        { provide: OpEditingPortalHandlerToken, useValue: handler },
        { provide: ChangeDetectorRef, useValue: { markForCheck: () => undefined, detectChanges: () => undefined } },
        { provide: PathHelperService, useValue: {} },
        { provide: OpModalService, useValue: modalService },
        { provide: TimezoneService, useValue: {} },
        { provide: DeviceService, useValue: {} },
      ],
    });
    return TestBed.runInInjectionContext(() => new TestDateField());
  };

  afterEach(() => TestBed.resetTestingModule());

  it('opens the modal once while it is already open', async () => {
    const field = build();
    field.onInputFocused();
    resolveForm();
    await Promise.resolve();
    expect(modalService.show).toHaveBeenCalledTimes(1);

    field.onInputFocused();
    resolveForm();
    await Promise.resolve();

    expect(modalService.show).toHaveBeenCalledTimes(1);
  });

  it('does not open the modal after the field is destroyed', async () => {
    const field = build();
    field.onInputFocused();
    field.ngOnDestroy();
    resolveForm();
    await Promise.resolve();

    expect(modalService.show).not.toHaveBeenCalled();
  });
});

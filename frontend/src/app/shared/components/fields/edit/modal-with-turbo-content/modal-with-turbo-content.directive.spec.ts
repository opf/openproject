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
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { ResourceChangeset } from '../../changeset/resource-changeset';
import { ModalWithTurboContentDirective } from './modal-with-turbo-content.directive';
import { ModalCreateResponse } from './modal-create-response';

describe('Turbo modal output integration', () => {
  function setup() {
    const element = document.createElement('turbo-frame');
    const push = vi.fn();
    const detectChanges = vi.fn();
    TestBed.configureTestingModule({
      providers: [
        { provide: ElementRef, useValue: new ElementRef(element) },
        { provide: ChangeDetectorRef, useValue: { detectChanges } },
        ...[ApiV3Service, I18nService, HalEventsService, ToastService].map((provide) => ({ provide, useValue: {} })),
      ],
    });
    const directive = TestBed.runInInjectionContext(() => new ModalWithTurboContentDirective());
    const resource = Object.create(HalResource.prototype) as HalResource;
    Object.defineProperty(resource, 'id', { value: 'new' });
    const change = Object.create(ResourceChangeset.prototype) as ResourceChangeset;
    change.push = push;
    directive.resource = resource;
    directive.change = change;
    directive.ngAfterViewInit();
    return { directive, element, push, detectChanges };
  }

  const responses:ModalCreateResponse[] = [
    { duration: 2, startDate: '2026-10-29', dueDate: '2026-10-30', includeNonWorkingDays: false, scheduleManually: true },
    { duration: null, startDate: null, dueDate: null, includeNonWorkingDays: false, scheduleManually: true },
    { estimatedTime: 'PT2H', remainingTime: 'PT1H', percentageDone: 50 },
    { estimatedTime: null, remainingTime: null, percentageDone: null },
  ];

  it.each(responses)('emits the decoded Rails payload %j before pushing the changeset', async (response) => {
    const { directive, element, push, detectChanges } = setup();
    const emitted:ModalCreateResponse[] = [];
    directive.successfulCreate.subscribe((value) => {
      expect(push).not.toHaveBeenCalled();
      emitted.push(value);
    });
    element.dispatchEvent(new CustomEvent('turbo:submit-end', {
      detail: { fetchResponse: { succeeded: true, response: new Response(JSON.stringify(response)) } },
    }));
    await vi.waitFor(() => expect(push).toHaveBeenCalledOnce());
    expect(emitted).toEqual([response]);
    expect(detectChanges).toHaveBeenCalledOnce();
    directive.ngOnDestroy();
  });

  it('removes the cancellation listener on destruction', () => {
    const { directive } = setup();
    const cancel = vi.fn();
    directive.cancel.subscribe(cancel);
    document.dispatchEvent(new Event('cancelModalWithTurboContent'));
    expect(cancel).toHaveBeenCalledOnce();
    directive.ngOnDestroy();
    document.dispatchEvent(new Event('cancelModalWithTurboContent'));
    expect(cancel).toHaveBeenCalledOnce();
  });
});

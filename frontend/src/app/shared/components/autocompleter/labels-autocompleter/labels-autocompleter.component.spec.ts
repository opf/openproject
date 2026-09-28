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

import { NO_ERRORS_SCHEMA } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { provideHttpClient, withInterceptorsFromDi, withXhr } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { NgSelectModule } from '@ng-select/ng-select';
import { States } from 'core-app/core/states/states.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { LabelsAutocompleterComponent } from './labels-autocompleter.component';

describe('LabelsAutocompleterComponent', () => {
  let component:LabelsAutocompleterComponent;
  let httpMock:HttpTestingController;
  let toast:{ addError:ReturnType<typeof vi.fn> };
  let halNotification:{ handleRawError:ReturnType<typeof vi.fn> };

  const i18nStub = { t: (key:string) => key };

  beforeEach(async () => {
    toast = { addError: vi.fn() };
    halNotification = { handleRawError: vi.fn() };

    await TestBed.configureTestingModule({
      declarations: [LabelsAutocompleterComponent],
      imports: [NgSelectModule],
      schemas: [NO_ERRORS_SCHEMA],
      providers: [
        States,
        provideHttpClient(withXhr(), withInterceptorsFromDi()),
        provideHttpClientTesting(),
        { provide: I18nService, useValue: i18nStub },
        { provide: ToastService, useValue: toast },
        { provide: HalResourceNotificationService, useValue: halNotification },
      ],
    }).compileComponents();

    component = TestBed.createComponent(LabelsAutocompleterComponent).componentInstance;
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  function pendingRequest() {
    return httpMock.expectOne((req) => req.method === 'POST' && req.url.endsWith('/labels'));
  }

  it('does not offer to create a blank term', () => {
    expect(component.createLabel('   ')).toBeUndefined();
  });

  it('resolves with the created label on success', async () => {
    const promise = component.createLabel('Urgent');

    pendingRequest().flush({ id: 5, name: 'Urgent', _links: { self: { href: '/api/v3/labels/5' } } });

    await expect(promise).resolves.toEqual({ id: 5, name: 'Urgent', href: '/api/v3/labels/5' });
  });

  it('shows a specific message and rejects on a 403', async () => {
    const promise = component.createLabel('Urgent');

    pendingRequest().flush({ _type: 'Error' }, { status: 403, statusText: 'Forbidden' });

    await expect(promise).rejects.toBeTruthy();
    expect(toast.addError).toHaveBeenCalledWith('js.autocompleter.create_label_forbidden');
    expect(halNotification.handleRawError).not.toHaveBeenCalled();
  });

  it('delegates other errors to the generic handler', async () => {
    const promise = component.createLabel('Urgent');

    pendingRequest().flush({ _type: 'Error' }, { status: 422, statusText: 'Unprocessable Entity' });

    await expect(promise).rejects.toBeTruthy();
    expect(halNotification.handleRawError).toHaveBeenCalled();
    expect(toast.addError).not.toHaveBeenCalled();
  });

  it('ignores a second call while a request is in flight, then allows a retry', async () => {
    const first = component.createLabel('Urgent');
    const second = component.createLabel('Urgent');

    expect(second).toBeUndefined();

    pendingRequest().flush({ id: 5, name: 'Urgent', _links: { self: { href: '/api/v3/labels/5' } } });
    await first;

    const retry = component.createLabel('Urgent');
    expect(retry).toBeDefined();
    pendingRequest().flush({ id: 5, name: 'Urgent', _links: { self: { href: '/api/v3/labels/5' } } });
    await retry;
  });

  it('resets the in-flight flag after an error so a retry can be sent', async () => {
    const first = component.createLabel('Urgent');
    pendingRequest().flush({ _type: 'Error' }, { status: 500, statusText: 'Internal Server Error' });
    await expect(first).rejects.toBeTruthy();

    const retry = component.createLabel('Urgent');
    expect(retry).toBeDefined();
    pendingRequest().flush({ id: 5, name: 'Urgent', _links: { self: { href: '/api/v3/labels/5' } } });
    await retry;
  });

  it('assigns addTag on init without throwing change-detection errors', () => {
    const fixture = TestBed.createComponent(LabelsAutocompleterComponent);
    expect(() => fixture.detectChanges()).not.toThrow();
    expect(typeof fixture.componentInstance.addTag).toBe('function');
  });
});

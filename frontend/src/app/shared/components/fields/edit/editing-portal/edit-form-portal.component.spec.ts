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

import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { ApplicationRef, EventEmitter, Type } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { fireEvent, screen, waitFor, within } from '@testing-library/dom';
import { english } from 'flatpickr/dist/l10n/default';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { CapabilitiesResourceService } from 'core-app/core/state/capabilities/capabilities.service';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { States } from 'core-app/core/states/states.service';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { FormResource } from 'core-app/features/hal/resources/form-resource';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { WorkPackageAutocompleterComponent } from 'core-app/shared/components/autocompleter/work-package-autocompleter/wp-autocompleter.component';
import { OpWpDatePickerModalComponent } from 'core-app/shared/components/datepicker/wp-date-picker-modal/wp-date-picker.modal';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { OpenprojectFieldsModule } from '../../openproject-fields.module';
import { EditFieldComponent } from '../edit-field.component';
import { EditFieldService } from '../edit-field.service';
import { EditFormComponent } from '../edit-form/edit-form.component';
import { HalResourceEditFieldHandler } from '../field-handler/hal-resource-edit-field-handler';
import { CombinedDateEditFieldComponent } from '../field-types/combined-date-edit-field.component';
import { DateTimeEditFieldComponent } from '../field-types/datetime-edit-field.component';
import { DaysDurationEditFieldComponent } from '../field-types/days-duration-edit-field.component';
import { SelectAutocompleterRegisterService } from '../field-types/select-edit-field/select-autocompleter-register.service';
import { WorkPackageEditFieldComponent } from '../field-types/work-package-edit-field.component';
import { HalResourceEditingService } from '../services/hal-resource-editing.service';
import { EditFormPortalComponent } from './edit-form-portal.component';
import { EditingPortalService } from './editing-portal-service';

describe('EditFormPortalComponent', () => {
  const formPath = '/api/v3/work_packages/1/form';
  const allowedParentsPath = '/api/v3/work_packages/1/available_parents';
  let container:HTMLElement;
  let handler:HalResourceEditFieldHandler|undefined;
  let http:HttpTestingController;
  const startDate = '2026-11-07';
  const dueDate = '2026-11-09';
  const dateTime = '2026-11-07T12:30:00Z';
  const schemaProperties = {
    startDate: { name: 'Start date', type: 'Date' },
    dueDate: { name: 'Due date', type: 'Date' },
    duration: { name: 'Duration', type: 'Duration' },
    customField1: { name: 'Meeting time', type: 'DateTime' },
    parent: {
      name: 'Parent',
      type: 'WorkPackage',
      _links: { allowedValues: { href: allowedParentsPath } },
    },
  };

  const formSource = () => ({
    _type: 'Form',
    _links: { self: { href: formPath } },
    _embedded: {
      payload: { _links: { self: { href: '/api/v3/work_packages/1' } } },
      schema: {
        _type: 'Schema',
        ...Object.fromEntries(Object.entries(structuredClone(schemaProperties)).map(([name, schema]) => [
          name, { ...schema, writable: true, required: true, hasDefault: false },
        ])),
      },
    },
  });

  type SchedulingModal = Pick<OpWpDatePickerModalComponent, 'element'|'closingEvent'>;
  let modal:SchedulingModal;
  const showModal = vi.fn<(...args:Parameters<OpModalService['show']>) => Observable<SchedulingModal>>(() => of(modal));

  beforeEach(() => {
    modal = { element: document.createElement('div'), closingEvent: new EventEmitter() };
    vi.stubGlobal('OpenProject', {});
    vi.stubGlobal('ErrorReporter', { addHook: vi.fn() });
    window.I18n.store({
      en: {
        date: {
          abbr_day_names: english.weekdays.shorthand,
          day_names: english.weekdays.longhand,
          abbr_month_names: ['', ...english.months.shorthand],
          month_names: ['', ...english.months.longhand],
          abbr_week: 'Wk',
        },
        js: { inplace: { errors: { messages_on_field: '%{messages}' } } },
      },
    });
    TestBed.configureTestingModule({
      imports: [OpenprojectFieldsModule],
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        States,
        SchemaCacheService,
        CapabilitiesResourceService,
        HalResourceNotificationService,
        HalResourceEditingService,
        {
          provide: ConfigurationService,
          useValue: {
            startOfWeek: () => 1,
            isTimezoneSet: () => true,
            timezone: () => 'UTC',
            timeFormatPresent: () => true,
            timeFormat: () => 'HH:mm',
            dateFormatPresent: () => true,
            dateFormat: () => 'YYYY-MM-DD',
          },
        },
        { provide: WeekdayService, useValue: { loadWeekdays: () => of([]), isNonWorkingDay: () => false } },
        { provide: DayResourceService, useValue: { isNonWorkingDay$: () => Promise.resolve(false) } },
        { provide: OpModalService, useValue: {
          show: showModal,
          activeModalInstance$: new BehaviorSubject<OpModalService['activeModalInstance$']['value']>(null),
        } },
      ],
    });

    http = TestBed.inject(HttpTestingController);
    container = document.createElement('div');
    container.className = '__hidden_overflow_container';
    document.body.append(container);
  });

  afterEach(() => {
    handler?.deactivate(false);
    handler = undefined;
    modal.closingEvent.complete();
    container?.remove();
    showModal.mockClear();
    http?.verify();
    vi.unstubAllGlobals();
  });

  async function setup(fieldName:keyof typeof schemaProperties, field:Type<EditFieldComponent>) {
    const hal = TestBed.inject(HalResourceService);
    hal.registerResource('Form', { cls: FormResource });
    hal.registerResource('Collection', { cls: CollectionResource });
    const resource = hal.createHalResource({
      _type: 'WorkPackage',
      id: 1,
      startDate,
      dueDate,
      duration: 'P3D',
      customField1: dateTime,
      _links: {
        self: { href: '/api/v3/work_packages/1' },
        update: { href: formPath, method: 'post' },
      },
    });
    const loadedForm = hal.createHalResourceOfClass(FormResource, formSource(), true);
    const change = TestBed.inject(HalResourceEditingService).edit(resource, loadedForm);
    const schema = change.schema.ofProperty(fieldName);
    TestBed.inject(EditFieldService).addFieldType(field, fieldName, [fieldName]);

    const fixture = TestBed.createComponent(EditFormComponent);
    fixture.componentRef.setInput('resource', resource);
    fixture.componentRef.setInput('inEditMode', true);
    await fixture.whenStable();

    return { form: fixture.componentInstance, change, schema };
  }

  async function attach(fieldName:keyof typeof schemaProperties, field:Type<EditFieldComponent>) {
    const { form, change, schema } = await setup(fieldName, field);
    const portal = await TestBed.inject(EditingPortalService)
      .create(container, form.injector, form, schema, fieldName, []);
    if (!(portal instanceof HalResourceEditFieldHandler)) throw new Error('Expected a HAL edit field handler');
    handler = portal;
    form.activeFields[fieldName] = portal;
    return { change, handler: portal };
  }

  it('initializes the actual date-time picker from explicit portal inputs and renders handler state', async () => {
    const { form, change, schema } = await setup('customField1', DateTimeEditFieldComponent);
    const fixture = TestBed.createComponent(EditFormPortalComponent);
    const field = new HalResourceEditFieldHandler(
      form.injector, form, 'customField1', schema, fixture.nativeElement as HTMLElement,
      TestBed.inject(PathHelperService), [],
    );
    const ready = vi.fn<() => void>();
    fixture.componentInstance.onEditFieldReady.subscribe(ready);
    fixture.componentRef.setInput('editFieldHandler', field);
    fixture.componentRef.setInput('schemaInput', schema);
    fixture.componentRef.setInput('changeInput', change);
    await waitFor(() => expect(ready).toHaveBeenCalledOnce());
    const input = screen.getByRole('textbox', { name: 'Meeting time' });
    expect(input).toHaveValue('2026-11-07 12:30');

    change.inFlight = true;
    field.notifyStateChanged();
    await waitFor(() => expect(input).toBeDisabled());
    change.inFlight = false;
    field.notifyStateChanged();
    field.setErrors(['Invalid date']);
    await waitFor(() => expect(input).toBeEnabled());
    expect(input).toHaveAccessibleName('Meeting time Invalid date');

    fireEvent.input(input, { target: { value: '2026-11-08 14:45' } });
    fireEvent.keyDown(input, { key: 'Enter', keyCode: 13 });
    await waitFor(() => expect(change.value('customField1')).toBe('2026-11-08T14:45:00Z'));
    field.setErrors([]);
    await waitFor(() => expect(input).toHaveAccessibleName('Meeting time'));

    const detectChanges = vi.spyOn(fixture.componentInstance.cdRef, 'detectChanges');
    field.notifyStateChanged();
    expect(detectChanges).toHaveBeenCalledOnce();
    detectChanges.mockClear();
    field.setErrors(['Invalid date']);
    expect(detectChanges).toHaveBeenCalledOnce();

    fixture.destroy();
    detectChanges.mockClear();
    field.notifyStateChanged();
    field.setErrors(['Late error']);
    expect(detectChanges).not.toHaveBeenCalled();
  });

  it('refreshes the combined date after the calendar updates the same resource', async () => {
    const { change } = await attach('startDate', CombinedDateEditFieldComponent);
    const input = within(container).getByRole('textbox');
    expect(input).toHaveValue(startDate);

    fireEvent.focus(input);
    const request = await waitFor(() => http.expectOne(formPath));
    expect(request.request.method.toUpperCase()).toBe('POST');
    request.flush(formSource());
    await waitFor(() => expect(showModal).toHaveBeenCalledOnce());

    change.setValue('startDate', '2026-11-08');
    fireEvent(document, new CustomEvent('date-picker-modal:update'));
    await waitFor(() => expect(input).toHaveValue('2026-11-08'));
  });

  it('shows the new duration after a calendar create event', async () => {
    const { change } = await attach('duration', DaysDurationEditFieldComponent);
    const input = within(container).getByRole('spinbutton', { name: 'Duration' });
    expect(input).toHaveValue(3);

    fireEvent.focus(input);
    expect(showModal).toHaveBeenCalledOnce();
    await TestBed.inject(ApplicationRef).whenStable();
    fireEvent(document, new CustomEvent('date-picker-modal:create', { detail: {
      duration: 5,
      startDate,
      dueDate,
      includeNonWorkingDays: false,
      scheduleManually: true,
    } }));
    await waitFor(() => expect(input).toHaveValue(5));
    expect(change.value('duration')).toBe('P5D');
    fireEvent(document, new CustomEvent('date-picker-modal:cancel'));
    await waitFor(() => expect(input).toHaveValue(3));
  });

  it('loads parent options in the actual work package autocompleter and updates the changeset', async () => {
    TestBed.inject(SelectAutocompleterRegisterService).register(WorkPackageAutocompleterComponent, 'WorkPackage');
    const { change, handler: field } = await attach('parent', WorkPackageEditFieldComponent);
    const input = within(container).getByRole('combobox');
    fireEvent.keyDown(input, { key: 'ArrowDown', keyCode: 40 });
    fireEvent.input(input, { target: { value: 'Parent' } });
    const request = await waitFor(() => http.expectOne((req) => req.url === allowedParentsPath));
    request.flush({
      _type: 'Collection',
      _links: { self: { href: allowedParentsPath } },
      _embedded: { elements: [
        { _type: 'WorkPackage', name: 'Parent task', _links: { self: { href: '/api/v3/work_packages/2' } } },
      ] },
    });

    fireEvent.click(await screen.findByRole('option', { name: 'Parent task' }));
    expect(change.value('parent')).toMatchObject({ href: '/api/v3/work_packages/2' });
    await waitFor(() => expect(within(container).getByText('Parent task')).toBeVisible());

    change.inFlight = true;
    field.notifyStateChanged();
    await waitFor(() => expect(input).toBeDisabled());
  });
});

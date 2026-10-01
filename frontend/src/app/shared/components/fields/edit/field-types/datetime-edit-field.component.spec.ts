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

import { TestBed } from '@angular/core/testing';
import { FormsModule } from '@angular/forms';
import { vi } from 'vitest';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  OpEditingPortalChangesetToken,
  OpEditingPortalHandlerToken,
  OpEditingPortalSchemaToken,
} from 'core-app/shared/components/fields/edit/edit-field.component';
import { DateTimeEditFieldComponent } from 'core-app/shared/components/fields/edit/field-types/datetime-edit-field.component';

describe('DateTimeEditFieldComponent', () => {
  const fieldName = 'customField1';
  let resource:Record<string, unknown>;

  async function render(value:string|null, required = false):Promise<{ component:DateTimeEditFieldComponent, input:HTMLInputElement }> {
    resource = { [fieldName]: value };
    const schema = { type: 'DateTime', name: 'Detected at', required };

    TestBed.configureTestingModule({
      declarations: [DateTimeEditFieldComponent],
      imports: [FormsModule],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        {
          provide: ConfigurationService,
          useValue: { isTimezoneSet: () => true, timezone: () => 'Europe/Brussels' },
        },
        { provide: OpEditingPortalSchemaToken, useValue: schema },
        {
          provide: OpEditingPortalHandlerToken,
          useValue: {
            fieldName, htmlId: 'datetime-field', inFlight: false, handleUserKeydown: vi.fn(),
          },
        },
        {
          provide: OpEditingPortalChangesetToken,
          useValue: {
            projectedResource: resource,
            schema: { ofProperty: () => schema, mappedName: (name:string) => name },
          },
        },
      ],
    });

    const fixture = TestBed.createComponent(DateTimeEditFieldComponent);
    fixture.detectChanges();
    await fixture.whenStable();

    const input = (fixture.nativeElement as HTMLElement).querySelector('input')!;

    return { component: fixture.componentInstance, input };
  }

  it('renders a datetime-local input with the UTC value in the user time zone', async () => {
    const { input } = await render('2026-10-01T12:30:00.000Z');

    expect(input.type).toEqual('datetime-local');
    expect(input.id).toEqual('datetime-field');
    expect(input.value).toEqual('2026-10-01T14:30');
  });

  it('renders an empty input without a value', async () => {
    const { component, input } = await render(null);

    expect(component.value).toEqual('');
    expect(input.value).toEqual('');
  });

  it('writes the input as a UTC ISO 8601 value, honouring daylight saving time', async () => {
    const { component } = await render(null);

    component.value = '2026-10-01T14:30';
    expect(resource[fieldName]).toEqual('2026-10-01T12:30:00Z');

    component.value = '2026-12-01T14:30';
    expect(resource[fieldName]).toEqual('2026-12-01T13:30:00Z');
  });

  it('clears the value for an empty or invalid input', async () => {
    const { component } = await render('2026-10-01T12:30:00.000Z');

    component.value = '';
    expect(resource[fieldName]).toBeNull();

    component.value = '2026-10-01';
    expect(resource[fieldName]).toBeNull();
  });

  it('marks the input as required for required fields', async () => {
    const { input } = await render(null, true);

    expect(input.getAttribute('aria-required')).toEqual('true');
    expect(input.required).toBe(true);
  });
});

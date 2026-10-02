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

import { CUSTOM_ELEMENTS_SCHEMA, Type } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { vi } from 'vitest';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import {
  OpEditingPortalChangesetToken,
  OpEditingPortalHandlerToken,
  OpEditingPortalSchemaToken,
} from 'core-app/shared/components/fields/edit/edit-field.component';

export const fieldName = 'customField1';

export function option(id:number, name:string):HalResource {
  return { href: `/api/v3/custom_options/${id}`, name } as unknown as HalResource;
}

export interface InlineOptionsSetup<T> {
  fixture:ComponentFixture<T>;
  element:HTMLElement;
  resource:Record<string, unknown>;
  handler:{ inEditMode:boolean, handleUserSubmit:ReturnType<typeof vi.fn> };
}

export async function renderInlineOptionsField<T>(
  component:Type<T>,
  options:HalResource[],
  value:unknown,
  { required = false, inEditMode = false } = {},
):Promise<InlineOptionsSetup<T>> {
  const resource:Record<string, unknown> = { [fieldName]: value };
  const schema = {
    type: 'CustomOption', name: 'Severity', required, allowedValues: options,
  };
  const handler = {
    fieldName,
    htmlId: 'inline-options-field',
    inFlight: false,
    inEditMode,
    handleUserKeydown: vi.fn(),
    handleUserSubmit: vi.fn().mockResolvedValue(undefined),
    handleUserCancel: vi.fn(),
  };

  TestBed.configureTestingModule({
    declarations: [component],
    schemas: [CUSTOM_ELEMENTS_SCHEMA],
    providers: [
      { provide: I18nService, useValue: { t: (key:string) => key } },
      { provide: OpEditingPortalSchemaToken, useValue: schema },
      { provide: OpEditingPortalHandlerToken, useValue: handler },
      {
        provide: OpEditingPortalChangesetToken,
        useValue: {
          projectedResource: resource,
          schema: { ofProperty: () => schema, mappedName: (name:string) => name },
          getForm: () => Promise.resolve(undefined),
        },
      },
    ],
  });

  const fixture = TestBed.createComponent(component);
  fixture.detectChanges();
  await fixture.whenStable();
  fixture.detectChanges();

  return {
    fixture, element: fixture.nativeElement as HTMLElement, resource, handler,
  };
}

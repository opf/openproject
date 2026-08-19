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

import { ApplicationRef, Injector } from '@angular/core';
import { EditForm } from 'core-app/shared/components/fields/edit/edit-form/edit-form';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { EditFieldHandler } from 'core-app/shared/components/fields/edit/editing-portal/edit-field-handler';
import { afterEach, vi } from 'vitest';
import type { IFieldSchema } from 'core-app/shared/components/fields/field.base';

class TestEditForm extends EditForm<HalResource> {
  constructor(injector:Injector, private readonly requireVisibleSpy:(fieldName:string) => Promise<void>, private readonly resetSpy:(fieldName:string, focus?:boolean) => void) {
    super(injector);
  }

  public requireVisible(fieldName:string):Promise<void> {
    return this.requireVisibleSpy(fieldName);
  }

  // Concrete implementation required by the abstract base. The specs mock
  // `activate` directly, so this is never invoked.
  protected activateField(_form:EditForm, _schema:IFieldSchema, _fieldName:string, _errors:string[]):Promise<EditFieldHandler> {
    return Promise.resolve({} as EditFieldHandler);
  }

  public reset(fieldName:string, focus?:boolean):void {
    this.resetSpy(fieldName, focus);
  }

  protected focusOnFirstError():void {
    return undefined;
  }
}

describe('EditForm', () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('does not require visibility twice for newly erroneous inactive fields', async () => {
    const tick = vi.fn();
    const requireVisible = vi.fn().mockResolvedValue(undefined);
    const reset = vi.fn();
    const injector = {
      get: vi.fn().mockImplementation((token:unknown) => {
        if (token === ApplicationRef) {
          return { tick };
        }

        throw new Error(`Unexpected token: ${String(token)}`);
      }),
    };

    const form = new TestEditForm(injector, requireVisible, reset);
    const activate = vi.spyOn(form, 'activate').mockResolvedValue({} as EditFieldHandler);
    const change = {
      inFlight: false,
      schema: {
        ofProperty: vi.fn().mockReturnValue({
          writable: true,
          name: 'Foo',
        }),
      },
      getForm: vi.fn().mockResolvedValue(undefined),
    };

    form.resource = { id: 1 } as unknown as HalResource;
    form.halEditing = {
      changeFor: vi.fn().mockReturnValue(change),
    } as never;
    form.halNotification = {
      handleRawError: vi.fn(),
      showEditingBlockedError: vi.fn(),
    } as never;
    form.errorsPerAttribute = { foo: ['Required'] };
    const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => undefined);

    (form as unknown as {
      setErrorsForFields:(fields:string[]) => void;
    }).setErrorsForFields(['foo']);
    await vi.waitFor(() => {
      expect(activate).toHaveBeenCalledTimes(1);
    });

    expect(requireVisible).toHaveBeenCalledTimes(1);
    expect(activate).toHaveBeenCalledWith('foo', true);
    expect(consoleErrorSpy).not.toHaveBeenCalled();
  });
});

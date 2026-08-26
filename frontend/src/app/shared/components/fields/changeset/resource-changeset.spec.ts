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

import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { FormResource } from 'core-app/features/hal/resources/form-resource';
import { vi } from 'vitest';

class TestResourceChangeset extends ResourceChangeset {
  public refresh():Promise<FormResource> {
    return this.updateForm();
  }
}

function deferred<T>() {
  let resolve:(value:T) => void;
  let reject:(reason?:unknown) => void;
  const promise = new Promise<T>((promiseResolve, promiseReject) => {
    resolve = promiseResolve;
    reject = promiseReject;
  });

  return { promise, resolve: resolve!, reject: reject! };
}

describe('ResourceChangeset', () => {
  it('returns the latest form when requests finish out of order', async () => {
    const firstRequest = deferred<FormResource>();
    const secondRequest = deferred<FormResource>();
    const update = vi.fn()
      .mockReturnValueOnce(firstRequest.promise)
      .mockReturnValueOnce(secondRequest.promise);
    const resource = {
      id: 1,
      lockVersion: 1,
      $source: { _links: {} },
      $links: { update },
      injector: {
        get: vi.fn().mockReturnValue({ of: vi.fn() }),
      },
    } as unknown as HalResource;
    const cachedForm = {
      payload: { $source: { _links: {} } },
      schema: {},
    } as unknown as FormResource;
    const currentForm = {
      payload: {},
      schema: {},
    } as unknown as FormResource;
    const staleForm = {
      payload: {},
      schema: {},
    } as unknown as FormResource;
    const changeset = new TestResourceChangeset(resource, undefined, cachedForm);

    const firstResult = changeset.refresh();
    const secondResult = changeset.refresh();
    firstRequest.resolve(staleForm);
    secondRequest.resolve(currentForm);

    await expect(firstResult).resolves.toBe(currentForm);
    await expect(secondResult).resolves.toBe(currentForm);
    await expect(changeset.getForm()).resolves.toBe(currentForm);
  });
});

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

import { waitFor } from '@testing-library/dom';
import { vi, type Mock } from 'vitest';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type FiltersFormControllerType from './filters-form.controller';

describe('Filters form controller', () => {
  let ctx:StimulusTestContext;
  let FiltersFormController:typeof FiltersFormControllerType;
  let fetchSpy:Mock;
  let resolveResponse!:(response:Response) => void;

  beforeAll(async () => {
    ({ default: FiltersFormController } = await import('./filters-form.controller'));
  });

  beforeEach(async () => {
    fetchSpy = vi.fn().mockImplementation(() => new Promise<Response>((resolve) => {
      resolveResponse = resolve;
    }));
    vi.spyOn(window, 'fetch').mockImplementation(fetchSpy);

    ctx = await setupStimulusTest({
      controllers: { 'filter--filters-form': FiltersFormController },
    });
  });

  afterEach(() => {
    ctx.dispose();
    vi.restoreAllMocks();
  });

  async function renderForm() {
    await ctx.mount(`
      <div id="global-loading-indicator" class="d-none"></div>
      <div data-controller="filter--filters-form"
           data-filter--filters-form-perform-turbo-requests-value="true">
        <form data-filter--filters-form-target="filterForm">
          <div data-filter--filters-form-target="simpleFilter"
               data-filter-name="name"
               data-filter-type="string"
               data-filter-operator="~">
            <input data-filter--filters-form-target="simpleValue"
                   data-filter-name="name"
                   value="old">
          </div>
        </form>
      </div>
    `);

    return ctx.getController<FiltersFormControllerType>('filter--filters-form');
  }

  it('ignores a response when the form has a newer unsent value', async () => {
    const controller = await renderForm();
    const replaceState = vi.spyOn(window.history, 'replaceState');

    controller.sendForm();
    await waitFor(() => expect(fetchSpy).toHaveBeenCalledOnce());

    const input = ctx.container.querySelector<HTMLInputElement>('input')!;
    input.value = 'new';
    resolveResponse(new Response('<turbo-stream action="remove" target="filter-result"></turbo-stream>'));
    await ctx.nextFrame();
    await ctx.nextFrame();

    expect(replaceState).not.toHaveBeenCalled();
  });
});

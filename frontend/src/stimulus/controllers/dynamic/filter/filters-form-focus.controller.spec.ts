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

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type FiltersFormControllerType from './filters-form.controller';

describe('Filters form focus', () => {
  const target = 'data-filter-name="test" data-filter--filters-form-target="filterValueContainer"';

  let ctx:StimulusTestContext;
  let Controller:typeof FiltersFormControllerType;

  beforeAll(async () => {
    ({ default: Controller } = await import('./filters-form.controller'));
  });

  afterEach(() => {
    vi.useRealTimers();
    ctx.dispose();
  });

  async function mount(valueMarkup:string, noValue = false) {
    ctx = await setupStimulusTest({ controllers: { 'filter--filters-form': Controller } });
    await ctx.mount(`<div data-controller="filter--filters-form">
      <button id="previous">Previous</button>
      <div data-filter-name="test" data-filter--filters-form-target="filter">
        <select id="operator" data-filter-name="test" data-filter--filters-form-target="operator">
          <option value="=" ${noValue ? 'data-no-value' : ''}>is</option>
        </select>
        ${valueMarkup}
      </div>
    </div>`);
    const controller = ctx.getController<FiltersFormControllerType>('filter--filters-form');
    const row = ctx.container.querySelector<HTMLElement>('[data-filter--filters-form-target="filter"]')!;
    ctx.container.querySelector<HTMLButtonElement>('#previous')!.focus();
    vi.useFakeTimers();
    return { controller, row };
  }

  it.each([
    ['text input', `<input id="expected" ${target}>`],
    ['number input', `<input id="expected" type="number" ${target}>`],
    ['autocomplete', `<div ${target}><input type="hidden"><ng-select><input id="expected"></ng-select><input></div>`],
    ['first usable control', `<div ${target}><input disabled><input hidden><input style="display:none"><select id="expected"><option>A</option></select></div>`],
    ['selected segmented button', `<div ${target}><input type="hidden"><button>No</button><button id="expected" aria-current="true">Yes</button></div>`],
    ['first segmented button', `<div ${target}><button id="expected">No</button><button>Yes</button></div>`],
  ])('focuses exactly one visible value control: %s', async (_name, markup) => {
    const { controller, row } = await mount(markup);
    const focusEvents:EventTarget[] = [];
    row.addEventListener('focusin', (event) => focusEvents.push(event.target!));

    controller.focusFilterValueIfPossible(row);
    await vi.advanceTimersByTimeAsync(300);

    const expected = ctx.container.querySelector('#expected');
    expect(document.activeElement).toBe(expected);
    expect(focusEvents).toEqual([expected]);
  });

  it('focuses the operator when it needs no value', async () => {
    const { controller, row } = await mount(`<input ${target}>`, true);

    controller.focusFilterValueIfPossible(row);
    await vi.advanceTimersByTimeAsync(300);

    expect(document.activeElement).toBe(ctx.container.querySelector('#operator'));
  });

  it.each(['removed', 'hidden', 'disabled'])('does not focus a target that becomes %s', async (change) => {
    const { controller, row } = await mount(`<input id="expected" ${target}>`);
    const expected = ctx.container.querySelector<HTMLInputElement>('#expected')!;
    const previous = document.activeElement;

    controller.focusFilterValueIfPossible(row);
    if (change === 'removed') expected.remove();
    if (change === 'hidden') row.hidden = true;
    if (change === 'disabled') expected.disabled = true;
    await vi.advanceTimersByTimeAsync(300);

    expect(document.activeElement).toBe(previous);
  });
});

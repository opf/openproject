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

import * as Turbo from '@hotwired/turbo';
import type { MockInstance } from 'vitest';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type FilterSelectPanelControllerType from './filter-select-panel.controller';

interface VisitingSession {
  visit:(location:string, options:object) => void;
}

const IDENTIFIER = 'backlogs--filter-select-panel';
const BASE_URL = '/projects/demo/backlogs/backlog';

describe('Backlogs filter select panel controller', () => {
  let ctx:StimulusTestContext;
  let Controller:typeof FilterSelectPanelControllerType;
  let originalUrl:string;
  let visit:MockInstance<VisitingSession['visit']>;

  beforeAll(async () => {
    ({ default: Controller } = await import('./filter-select-panel.controller'));
  });

  beforeEach(() => {
    originalUrl = window.location.href;
    visit = vi.spyOn(Turbo.session as unknown as VisitingSession, 'visit').mockImplementation(() => undefined);
  });

  afterEach(() => {
    visit.mockRestore();
    ctx.dispose();
    window.history.replaceState(window.history.state, '', originalUrl);
  });

  async function mount({ url = BASE_URL, checked = [] as string[] } = {}) {
    window.history.replaceState(window.history.state, '', url);
    ctx = await setupStimulusTest({ controllers: { [IDENTIFIER]: Controller } });
    await ctx.mount(`
      <div
        data-controller="${IDENTIFIER}"
        data-${IDENTIFIER}-filter-key-value="sprint_ids"
        data-${IDENTIFIER}-base-url-value="${BASE_URL}"
        data-action="itemActivated->${IDENTIFIER}#refreshButtons"
      >
        <button type="button" data-${IDENTIFIER}-target="clearButton"></button>
        <button type="button" data-${IDENTIFIER}-target="applyButton"></button>
      </div>
    `);

    const panel = ctx.container.querySelector<HTMLElement>(`[data-controller="${IDENTIFIER}"]`)!;
    Object.defineProperty(panel, 'selectedItems', { value: checked.map((value) => ({ value })) });

    return { panel, controller: ctx.getController<FilterSelectPanelControllerType>(IDENTIFIER, panel) };
  }

  const applyButton = () => ctx.container.querySelector<HTMLButtonElement>(`[data-${IDENTIFIER}-target="applyButton"]`)!;

  function visitedUrl():URL {
    expect(visit).toHaveBeenCalledTimes(1);
    expect(visit.mock.calls[0][1]).toEqual({ frame: 'backlogs_container', action: 'advance' });
    return new URL(String(visit.mock.calls[0][0]), window.location.origin);
  }

  describe('reading the applied filter from the URL', () => {
    it.each([
      { param: JSON.stringify(3), checked: ['3'] },
      { param: JSON.stringify([8, '3', 3, null, { id: 5 }]), checked: ['3', '8'] },
      { param: '[3', checked: [] },
    ])('treats sprint_ids=$param as applied $checked', async ({ param, checked }) => {
      const { panel } = await mount({ url: `${BASE_URL}?${new URLSearchParams({ sprint_ids: param })}`, checked });

      panel.dispatchEvent(new CustomEvent('itemActivated'));

      expect(applyButton()).toBeDisabled();
    });
  });

  describe('apply', () => {
    it('serializes a single id as a JSON string', async () => {
      const { controller } = await mount({ checked: ['3'] });

      controller.apply();

      expect(visitedUrl().searchParams.get('sprint_ids')).toBe('"3"');
    });

    it('serializes multiple ids as a sorted JSON array', async () => {
      const { controller } = await mount({ checked: ['8', '3'] });

      controller.apply();

      expect(visitedUrl().searchParams.get('sprint_ids')).toBe('["3","8"]');
    });

    it('removes the filter param when nothing is selected', async () => {
      const { controller } = await mount({ url: `${BASE_URL}?sprint_ids=%223%22` });

      controller.apply();

      expect(visitedUrl().searchParams.has('sprint_ids')).toBe(false);
    });

    it('preserves other params, including repeated ones', async () => {
      const { controller } = await mount({ url: `${BASE_URL}?bucket_ids=%227%22&ids[]=1&ids[]=2`, checked: ['3'] });

      controller.apply();

      const params = visitedUrl().searchParams;
      expect(params.get('bucket_ids')).toBe('"7"');
      expect(params.getAll('ids[]')).toEqual(['1', '2']);
    });

    it('navigates the backlog list endpoint, not the split-view details route', async () => {
      const { controller } = await mount({ url: `${BASE_URL}/details/42?bucket_ids=%227%22`, checked: ['3'] });

      controller.apply();

      const url = visitedUrl();
      expect(url.pathname).toBe(BASE_URL);
      expect(url.searchParams.get('bucket_ids')).toBe('"7"');
    });
  });
});

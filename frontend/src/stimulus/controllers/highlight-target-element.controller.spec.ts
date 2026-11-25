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

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import HighlightTargetElementController from './highlight-target-element.controller';

describe('highlight target element controller', () => {
  let ctx:StimulusTestContext;
  const originalUrl = window.location.href;

  beforeEach(async () => {
    ctx = await setupStimulusTest({
      controllers: { 'highlight-target-element': HighlightTargetElementController },
    });
  });

  afterEach(() => {
    ctx.dispose();
    window.history.replaceState(null, '', originalUrl);
    vi.restoreAllMocks();
  });

  it.each([
    ['starts with a digit', '1-intro', '#1-intro'],
    ['is percent-encoded', 'Release notes', '#Release%20notes'],
  ])('scrolls to the target whose id %s', async (_case, id, hash) => {
    window.history.replaceState(null, '', hash);
    const scrollIntoView = vi.spyOn(Element.prototype, 'scrollIntoView').mockImplementation(() => undefined);

    await ctx.mount(`<div data-controller="highlight-target-element"><h2 id="${id}">Intro</h2></div>`);

    await vi.waitFor(() => expect(scrollIntoView).toHaveBeenCalledOnce());
    expect(scrollIntoView.mock.contexts[0]).toBe(ctx.screen.getByRole('heading', { name: 'Intro' }));
  });
});

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

import { StreamActions } from '@hotwired/turbo';
import { LiveRegionElement } from '@primer/live-region-element';
import { registerLiveRegionStreamAction } from './live-region-stream-action';

// `announce()` from @primer/live-region-element ultimately calls
// `LiveRegionElement.prototype.announce(message, options)`, passing the options
// through unchanged. Spying on that real prototype method works in every
// browser, unlike `vi.mock()` of the module, which does not apply under the
// browser-mode runner used in CI.
describe('registerLiveRegionStreamAction', () => {
  let announceSpy:ReturnType<typeof vi.spyOn>;

  beforeEach(() => {
    registerLiveRegionStreamAction();
    // Pre-create the live region so announce() resolves synchronously instead
    // of waiting for a freshly-appended element to register.
    document.body.appendChild(document.createElement('live-region'));
    announceSpy = vi.spyOn(LiveRegionElement.prototype, 'announce');
  });

  afterEach(() => {
    vi.restoreAllMocks();
    document.body.innerHTML = '';
  });

  function liveRegion(attributes:Record<string, string>) {
    const element = document.createElement('turbo-stream');
    Object.entries(attributes).forEach(([name, value]) => element.setAttribute(name, value));
    StreamActions.liveRegion.call(element);
  }

  it('announces politely with the configured delay by default', () => {
    liveRegion({ message: 'Loaded', delay: '150' });

    expect(announceSpy).toHaveBeenCalledWith('Loaded', { politeness: 'polite', delayMs: 150 });
  });

  it('announces assertively without a delay when requested', () => {
    liveRegion({ message: 'Error', politeness: 'assertive' });

    expect(announceSpy).toHaveBeenCalledWith('Error', { politeness: 'assertive' });
  });

  it('does nothing without a message', () => {
    liveRegion({ politeness: 'polite' });

    expect(announceSpy).not.toHaveBeenCalled();
  });
});

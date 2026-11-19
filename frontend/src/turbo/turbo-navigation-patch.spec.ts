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

import * as Turbo from '@hotwired/turbo';
import { applyTurboNavigationPatch } from './turbo-navigation-patch';

// The FrameController prototype the patch reaches into. Internal Turbo API,
// not part of the public types, hence the casts.
const proto = (Turbo.FrameElement as any).delegateConstructor.prototype as Record<string, unknown>;

interface InternalFrame extends HTMLElement {
  delegate:{ fetchResponseLoaded:(fetchResponse:{ statusCode:number, redirected:boolean }) => Promise<void> };
}

interface InternalSession {
  visit:(location:string, options:{ snapshot:{ element:HTMLElement } }) => void;
}

describe('turbo-navigation-patch (tripwire for hotwired/turbo#1300)', () => {
  const original = proto.proposeVisitIfNavigatedWithAction;

  afterAll(() => {
    proto.proposeVisitIfNavigatedWithAction = original;
  });

  it('targets a method that still exists in the installed Turbo', () => {
    expect(typeof original).toBe('function');
  });

  it('upstream still sources the snapshot from the fetch response (#1300 unfixed)', () => {
    // When Turbo stops reading `responseHTML` off the fetch response, #1300
    // may be fixed upstream and this whole patch can be deleted. This guard
    // turns that upgrade into a red test instead of a silent behavior change.
    const upstream = String(original);
    expect(upstream).toContain('responseHTML');
    expect(upstream).toContain('fetchResponse');
  });

  it('rebinds the method to source HTML from the live document', () => {
    applyTurboNavigationPatch();

    const patched = proto.proposeVisitIfNavigatedWithAction;
    expect(patched).not.toBe(original);
    expect(String(patched)).toContain('ownerDocument');
  });

  describe('when a visit supersedes one that has not rendered yet', () => {
    let frame:InternalFrame;

    beforeEach(() => {
      applyTurboNavigationPatch();
      document.body.innerHTML = '<turbo-frame id="list" src="/list?filters=a" disabled></turbo-frame>';
      frame = document.querySelector<InternalFrame>('#list')!;
      frame.setAttribute('complete', '');
    });

    afterEach(() => {
      vi.restoreAllMocks();
      document.body.innerHTML = '';
    });

    function proposeVisit(src:string) {
      const propose = proto.proposeVisitIfNavigatedWithAction as (frame:Element, action:string) => void;
      propose.call(frame.delegate, frame, 'advance');
      frame.setAttribute('src', src);
      frame.setAttribute('busy', '');
      frame.setAttribute('aria-busy', 'true');
    }

    async function cachedFrame() {
      const visit = vi.spyOn(Turbo.session as unknown as InternalSession, 'visit').mockImplementation(() => undefined);
      await frame.delegate.fetchResponseLoaded({ statusCode: 200, redirected: false });
      const { snapshot } = visit.mock.calls[0][1];

      return snapshot.element.querySelector('#list')!;
    }

    it('keeps the snapshot taken before the superseded request started', async () => {
      proposeVisit('/list?filters=b');
      proposeVisit('/list?filters=c');

      const cached = await cachedFrame();

      expect(cached).toHaveAttribute('src', '/list?filters=a');
      expect(cached).toHaveAttribute('complete');
      expect(cached).not.toHaveAttribute('busy');
      expect(cached).not.toHaveAttribute('aria-busy');
    });

    it('takes a fresh snapshot once the previous visit has rendered', async () => {
      proposeVisit('/list?filters=b');
      await cachedFrame();
      vi.restoreAllMocks();
      frame.removeAttribute('busy');
      frame.removeAttribute('aria-busy');

      proposeVisit('/list?filters=c');

      expect(await cachedFrame()).toHaveAttribute('src', '/list?filters=b');
    });
  });
});

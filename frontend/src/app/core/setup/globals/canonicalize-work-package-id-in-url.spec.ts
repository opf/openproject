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

import {
  afterEach, beforeEach, describe, expect, it, vi,
} from 'vitest';
import * as Turbo from '@hotwired/turbo';
import { canonicalizeWorkPackageIdInUrl } from './canonicalize-work-package-id-in-url';

describe('canonicalizeWorkPackageIdInUrl', () => {
  let historyReplaceSpy:ReturnType<typeof vi.spyOn>;
  let canonicalLink:HTMLLinkElement | null = null;

  function setCanonical(href:string) {
    const link = document.createElement('link');
    link.rel = 'canonical';
    link.href = href;
    document.head.appendChild(link);
    canonicalLink = link;
  }

  beforeEach(() => {
    /* eslint-disable @typescript-eslint/no-empty-function */
    historyReplaceSpy = vi.spyOn(Turbo.session.history, 'replace').mockImplementation(() => {});
    /* eslint-enable @typescript-eslint/no-empty-function */
  });

  afterEach(() => {
    vi.restoreAllMocks();
    canonicalLink?.remove();
    canonicalLink = null;
    window.history.replaceState({}, '', '/');
  });

  it('rewrites old id to canonical id', () => {
    window.history.pushState({}, '', '/projects/old-proj/work_packages/OLD-42/activity');
    setCanonical('http://localhost/projects/new-proj/work_packages/NEW-42/activity');

    canonicalizeWorkPackageIdInUrl();

    const expectedUrl = new URL('/projects/old-proj/work_packages/NEW-42/activity', window.location.origin);
    expect(historyReplaceSpy).toHaveBeenCalledWith(expectedUrl, Turbo.session.history.restorationIdentifier);
    expect((Turbo.session as unknown as { view:{ lastRenderedLocation:URL } }).view.lastRenderedLocation.href)
      .toBe(expectedUrl.href);
  });

  it('does not rewrite when url already matches canonical', () => {
    window.history.pushState({}, '', '/projects/demo/work_packages/DEMO-42');
    setCanonical('http://localhost/projects/demo/work_packages/DEMO-42');

    canonicalizeWorkPackageIdInUrl();

    expect(historyReplaceSpy).not.toHaveBeenCalled();
  });

  it('does not rewrite when no canonical link is present', () => {
    window.history.pushState({}, '', '/projects/demo/work_packages/42');

    canonicalizeWorkPackageIdInUrl();

    expect(historyReplaceSpy).not.toHaveBeenCalled();
  });

  it('does not rewrite when url does not contain /work_packages/', () => {
    window.history.pushState({}, '', '/projects/demo/boards');
    setCanonical('http://localhost/projects/demo/boards');

    canonicalizeWorkPackageIdInUrl();

    expect(historyReplaceSpy).not.toHaveBeenCalled();
  });

  it('preserves query string and hash when rewriting the id', () => {
    window.history.pushState({}, '', '/projects/demo/work_packages/13?focus=description#comment-5');
    setCanonical('http://localhost/projects/demo/work_packages/DEMO-42');

    canonicalizeWorkPackageIdInUrl();

    const expectedUrl = new URL('/projects/demo/work_packages/DEMO-42?focus=description#comment-5', window.location.origin);
    expect(historyReplaceSpy).toHaveBeenCalledWith(expectedUrl, Turbo.session.history.restorationIdentifier);
  });
});

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

import {
  afterEach, beforeEach, describe, expect, it,
} from 'vitest';
import { addTurboGlobalListeners, canonicalizeWorkPackageIdInUrl } from './turbo-global-listeners';

describe('addTurboGlobalListeners — OPCE custom element morph guard', () => {
  let controller:AbortController;

  beforeEach(() => {
    controller = new AbortController();
    addTurboGlobalListeners(document, controller.signal);
  });

  afterEach(() => {
    controller.abort();
    document.body.innerHTML = '';
  });

  function beforeMorph(element:Element):boolean {
    return element.dispatchEvent(new CustomEvent('turbo:before-morph-element', {
      bubbles: true,
      cancelable: true,
    }));
  }

  it('prevents morphing of OPCE-* custom elements', () => {
    document.body.innerHTML = '<opce-principal></opce-principal>';
    const element = document.querySelector('opce-principal')!;

    const notCancelled = beforeMorph(element);

    expect(notCancelled).toBe(false);
  });

  it('leaves plain elements morphable', () => {
    document.body.innerHTML = '<div></div>';
    const element = document.querySelector('div')!;

    const notCancelled = beforeMorph(element);

    expect(notCancelled).toBe(true);
  });
});

describe('canonicalizeWorkPackageIdInUrl', () => {
  let replaceStateSpy:ReturnType<typeof vi.spyOn>;

  function setCanonical(href:string) {
    const link = document.createElement('link');
    link.rel = 'canonical';
    link.href = href;
    document.head.appendChild(link);
  }

  beforeEach(() => {
    window.history.pushState({}, '', '/');
    document.querySelectorAll('link[rel="canonical"]').forEach((element) => element.remove());
    /* eslint-disable @typescript-eslint/no-unsafe-assignment,@typescript-eslint/no-empty-function */
    replaceStateSpy = vi.spyOn(window.history, 'replaceState').mockImplementation(() => {});
    /* eslint-enable @typescript-eslint/no-unsafe-assignment,@typescript-eslint/no-empty-function */
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('rewrites old id to canonical id', () => {
    window.history.pushState({}, '', '/projects/old-proj/work_packages/OLD-42/activity');
    setCanonical('http://localhost/projects/new-proj/work_packages/NEW-42/activity');

    canonicalizeWorkPackageIdInUrl();

    expect(replaceStateSpy).toHaveBeenCalledWith(null, '', '/projects/old-proj/work_packages/NEW-42/activity');
  });

  it('does not call replaceState when url already matches canonical', () => {
    window.history.pushState({}, '', '/projects/demo/work_packages/DEMO-42');
    setCanonical('http://localhost/projects/demo/work_packages/DEMO-42');

    canonicalizeWorkPackageIdInUrl();

    expect(replaceStateSpy).not.toHaveBeenCalled();
  });

  it('does not call replaceState when no canonical link is present', () => {
    window.history.pushState({}, '', '/projects/demo/work_packages/42');

    canonicalizeWorkPackageIdInUrl();

    expect(replaceStateSpy).not.toHaveBeenCalled();
  });

  it('does not call replaceState when url does not contain /work_packages/', () => {
    window.history.pushState({}, '', '/projects/demo/boards');
    setCanonical('http://localhost/projects/demo/boards');

    canonicalizeWorkPackageIdInUrl();

    expect(replaceStateSpy).not.toHaveBeenCalled();
  });

  it('preserves query string and hash when rewriting the id', () => {
    window.history.pushState({}, '', '/projects/demo/work_packages/13?focus=description#comment-5');
    setCanonical('http://localhost/projects/demo/work_packages/DEMO-42');

    canonicalizeWorkPackageIdInUrl();

    expect(replaceStateSpy).toHaveBeenCalledWith(null, '', '/projects/demo/work_packages/DEMO-42?focus=description#comment-5');
  });
});

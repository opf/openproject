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
import type { VisitOptions } from '@hotwired/turbo';
import { addTurboGlobalListeners } from './turbo-global-listeners';

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

describe('addTurboGlobalListeners — snapshot caching', () => {
  let controller:AbortController;

  beforeEach(() => {
    controller = new AbortController();
    addTurboGlobalListeners(document, controller.signal);
  });

  afterEach(() => {
    controller.abort();
    document.body.innerHTML = '';
  });

  it('hides the global loading indicator before the page is cached', () => {
    document.body.innerHTML = '<div id="global-loading-indicator"></div>';

    document.dispatchEvent(new CustomEvent('turbo:before-cache'));

    expect(document.querySelector<HTMLElement>('#global-loading-indicator')).not.toBeVisible();
  });
});

describe('addTurboGlobalListeners — page visits', () => {
  let controller:AbortController;
  let pageVisits:number;
  const countPageVisit = () => { pageVisits += 1; };

  beforeEach(() => {
    pageVisits = 0;
    controller = new AbortController();
    addTurboGlobalListeners(document, controller.signal);
    document.addEventListener('op:page-visit', countPageVisit);
  });

  afterEach(() => {
    document.removeEventListener('op:page-visit', countPageVisit);
    controller.abort();
    vi.unstubAllGlobals();
  });

  const visit = () => document.dispatchEvent(new CustomEvent('turbo:visit'));

  it('dispatches op:page-visit on turbo:visit', () => {
    visit();

    expect(pageVisits).toBe(1);
  });

  it('dispatches op:page-visit for a rendering visit', () => {
    vi.stubGlobal('Turbo', { navigator: { currentVisit: { willRender: true } } });

    visit();

    expect(pageVisits).toBe(1);
  });

  it('ignores frame visits promoted without rendering', () => {
    vi.stubGlobal('Turbo', { navigator: { currentVisit: { willRender: false } } });

    visit();

    expect(pageVisits).toBe(0);
  });

  it('stops dispatching after abort', () => {
    controller.abort();

    visit();

    expect(pageVisits).toBe(0);
  });
});

// Real Turbo visits turn an upgrade that drops the navigator's currentVisit
// or the willRender option that turbo-navigation-patch.ts passes for promoted
// frame visits into a red test.
describe('addTurboGlobalListeners — page visits with the installed Turbo', () => {
  let controller:AbortController;
  let pageVisits:number;
  const countPageVisit = () => { pageVisits += 1; };
  const cancelVisit = () => { Turbo.navigator.currentVisit?.cancel(); };

  beforeEach(() => {
    pageVisits = 0;
    controller = new AbortController();
    addTurboGlobalListeners(document, controller.signal);
    document.addEventListener('op:page-visit', countPageVisit);
    document.addEventListener('turbo:visit', cancelVisit);
  });

  afterEach(() => {
    document.removeEventListener('turbo:visit', cancelVisit);
    document.removeEventListener('op:page-visit', countPageVisit);
    controller.abort();
  });

  const startVisit = (options:VisitOptions) => {
    const response = { statusCode: 200, redirected: false, responseHTML: '<html><body></body></html>' };
    Turbo.session.visit(window.location.href, { response, updateHistory: false, ...options });
  };

  it('dispatches op:page-visit for a rendering visit', () => {
    startVisit({});

    expect(pageVisits).toBe(1);
  });

  it('ignores visits started without rendering', () => {
    startVisit({ willRender: false });

    expect(pageVisits).toBe(0);
  });
});

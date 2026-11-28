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

import { onTestFinished, vi } from 'vitest';

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

  function beforeMorph(element:Element, newElement?:Element):boolean {
    return element.dispatchEvent(new CustomEvent('turbo:before-morph-element', {
      bubbles: true,
      cancelable: true,
      detail: { currentElement: element, newElement },
    }));
  }

  function parse(html:string):HTMLElement {
    const template = document.createElement('template');
    template.innerHTML = html;
    return template.content.firstElementChild as HTMLElement;
  }

  function defineOpcePrincipal() {
    if (customElements.get('opce-principal')) return;

    customElements.define('opce-principal', class extends HTMLElement {
      value:unknown;
      get principal() { return this.value; }
      set principal(value:unknown) { this.value = value; }
    });
  }

  it('prevents morphing of opce-principal and assigns its changed data attributes to its inputs', () => {
    defineOpcePrincipal();
    document.body.innerHTML = '<opce-principal data-principal=\'{"id":1}\' data-hide-name="true"></opce-principal>';
    const element = document.querySelector<HTMLElement & { principal:unknown }>('opce-principal')!;

    const notCancelled = beforeMorph(element, parse('<opce-principal data-principal=\'{"id":2}\' data-test-selector="op-avatar"></opce-principal>'));

    expect(notCancelled).toBe(false);
    expect(element.principal).toEqual({ id: 2 });
    expect(element.dataset.hideName).toBeUndefined();
    expect(element.dataset.testSelector).toBe('op-avatar');
    expect(Object.hasOwn(element, 'testSelector')).toBe(false);
  });

  it('logs an input that is not valid JSON and keeps syncing the other data attributes', () => {
    defineOpcePrincipal();
    const consoleError = vi.spyOn(console, 'error').mockImplementation(() => {});
    onTestFinished(() => consoleError.mockRestore());
    document.body.innerHTML = '<opce-principal data-principal=\'{"id":1}\'></opce-principal>';
    const element = document.querySelector<HTMLElement & { principal:unknown }>('opce-principal')!;
    element.principal = { id: 1 };

    beforeMorph(element, parse('<opce-principal data-principal="{invalid" data-test-selector="op-avatar"></opce-principal>'));

    expect(element.principal).toEqual({ id: 1 });
    expect(element.dataset.testSelector).toBe('op-avatar');
    expect(consoleError).toHaveBeenCalledWith("Couldn't parse the principal input of opce-principal:", '{invalid', expect.any(SyntaxError));
  });

  it('prevents morphing of other OPCE-* custom elements without touching their data attributes', () => {
    document.body.innerHTML = '<opce-test-other data-value="1"></opce-test-other>';
    const element = document.querySelector<HTMLElement>('opce-test-other')!;

    const notCancelled = beforeMorph(element, parse('<opce-test-other data-value="2"></opce-test-other>'));

    expect(notCancelled).toBe(false);
    expect(element.dataset.value).toBe('1');
  });

  it('allows removing OPCE-* custom elements', () => {
    document.body.innerHTML = '<opce-principal></opce-principal>';
    const element = document.querySelector('opce-principal')!;

    const notCancelled = beforeMorph(element);

    expect(notCancelled).toBe(true);
  });

  it('leaves plain elements morphable', () => {
    document.body.innerHTML = '<div></div>';
    const element = document.querySelector('div')!;

    const notCancelled = beforeMorph(element, parse('<div></div>'));

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

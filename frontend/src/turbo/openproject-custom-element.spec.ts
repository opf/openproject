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

import { isOpenProjectCustomElement, refreshAttributeInputs } from './openproject-custom-element';

describe('isOpenProjectCustomElement', () => {
  it('returns true for an element whose tag starts with OPCE-', () => {
    const element = document.createElement('opce-test-marker');

    expect(isOpenProjectCustomElement(element)).toBe(true);
  });

  it('returns false for a plain element', () => {
    const element = document.createElement('div');

    expect(isOpenProjectCustomElement(element)).toBe(false);
  });

  it('returns false for a non-Element node such as a text node', () => {
    const textNode = document.createTextNode('hello');

    expect(isOpenProjectCustomElement(textNode)).toBe(false);
  });

  it('returns false for a null event target', () => {
    expect(isOpenProjectCustomElement(null)).toBe(false);
  });
});

describe('refreshAttributeInputs', () => {
  class MarkedElement extends HTMLElement {
    static readonly opAttributeInputs = true;
    static readonly observedAttributes = ['name', 'href'];
  }

  class UnmarkedElement extends HTMLElement {
    static readonly observedAttributes = ['name'];
  }

  customElements.define('opce-test-refresh-marked', MarkedElement);
  customElements.define('opce-test-refresh-unmarked', UnmarkedElement);

  function build(tag:string, attributes:Record<string, string>):HTMLElement {
    const element = document.createElement(tag);
    Object.entries(attributes).forEach(([key, value]) => element.setAttribute(key, value));
    return element;
  }

  it('copies a changed observed attribute onto a marked element', () => {
    const element = build('opce-test-refresh-marked', { name: 'old' });
    const next = build('opce-test-refresh-marked', { name: 'new' });

    refreshAttributeInputs(element, next);

    expect(element.getAttribute('name')).toBe('new');
  });

  it('adds an observed attribute that is only present on the new element', () => {
    const element = build('opce-test-refresh-marked', {});
    const next = build('opce-test-refresh-marked', { href: '/x' });

    refreshAttributeInputs(element, next);

    expect(element.getAttribute('href')).toBe('/x');
  });

  it('removes an observed attribute that is absent on the new element', () => {
    const element = build('opce-test-refresh-marked', { name: 'old', href: '/x' });
    const next = build('opce-test-refresh-marked', { name: 'old' });

    refreshAttributeInputs(element, next);

    expect(element.hasAttribute('href')).toBe(false);
  });

  it('leaves unobserved attributes untouched', () => {
    const element = build('opce-test-refresh-marked', { id: 'keep', title: 'a' });
    const next = build('opce-test-refresh-marked', { id: 'other' });

    refreshAttributeInputs(element, next);

    expect(element.getAttribute('id')).toBe('keep');
    expect(element.getAttribute('title')).toBe('a');
  });

  it('does nothing for an unmarked element', () => {
    const element = build('opce-test-refresh-unmarked', { name: 'old' });
    const next = build('opce-test-refresh-unmarked', { name: 'new' });

    refreshAttributeInputs(element, next);

    expect(element.getAttribute('name')).toBe('old');
  });
});

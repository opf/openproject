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

import { readScriptNonce, scrubScriptElements } from './csp-script-nonce';

describe('readScriptNonce', () => {
  afterEach(() => {
    document.querySelector('meta[name="csp-nonce"]')?.remove();
  });

  it('returns the csp-nonce meta content', () => {
    document.head.insertAdjacentHTML('beforeend', '<meta name="csp-nonce" content="nonce-abc">');

    expect(readScriptNonce()).toBe('nonce-abc');
  });

  it('returns an empty string when no csp-nonce meta is present', () => {
    expect(readScriptNonce()).toBe('');
  });
});

describe('scrubScriptElements', () => {
  beforeEach(() => {
    vi.spyOn(console, 'warn').mockImplementation(() => undefined);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  function scriptWithNonce(nonce:string | null):HTMLScriptElement {
    const script = document.createElement('script');
    if (nonce !== null) {
      script.setAttribute('nonce', nonce);
    }
    return script;
  }

  it('removes a script whose nonce does not match', () => {
    const container = document.createElement('div');
    const script = scriptWithNonce('wrong-nonce');
    container.append(script);

    scrubScriptElements(container, 'our-nonce');

    expect(container.contains(script)).toBe(false);
  });

  it('removes a script with no nonce attribute', () => {
    const container = document.createElement('div');
    const script = scriptWithNonce(null);
    container.append(script);

    scrubScriptElements(container, 'our-nonce');

    expect(container.contains(script)).toBe(false);
  });

  it('keeps a script whose nonce matches', () => {
    const container = document.createElement('div');
    const script = scriptWithNonce('our-nonce');
    container.append(script);

    scrubScriptElements(container, 'our-nonce');

    expect(container.contains(script)).toBe(true);
  });

  it('operates on a DocumentFragment', () => {
    const fragment = document.createDocumentFragment();
    const script = scriptWithNonce('wrong-nonce');
    fragment.append(script);

    scrubScriptElements(fragment, 'our-nonce');

    expect(fragment.contains(script)).toBe(false);
  });
});

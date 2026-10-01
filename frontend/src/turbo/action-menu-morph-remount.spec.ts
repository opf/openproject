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

import { registerActionMenuMorphRemount } from './action-menu-morph-remount';

describe('registerActionMenuMorphRemount', () => {
  let controller:AbortController;

  beforeEach(() => {
    controller = new AbortController();
    registerActionMenuMorphRemount(document, controller.signal);
  });

  afterEach(() => {
    controller.abort();
    document.body.innerHTML = '';
  });

  function morphElement(currentElement:Element) {
    document.dispatchEvent(new CustomEvent('turbo:morph-element', {
      detail: { currentElement },
    }));
  }

  it('replaces a lazy-loading action-menu host so connectedCallback re-fires', () => {
    document.body.innerHTML = '<action-menu><include-fragment src="/menu"></include-fragment></action-menu>';
    const original = document.querySelector('action-menu')!;

    morphElement(original);

    expect(original.isConnected).toBe(false);
    expect(document.querySelector('action-menu')).not.toBe(original);
    expect(document.querySelector('action-menu include-fragment[src="/menu"]')).not.toBeNull();
  });

  it('leaves an action-menu without a lazy include-fragment untouched', () => {
    document.body.innerHTML = '<action-menu><button>Item</button></action-menu>';
    const original = document.querySelector('action-menu')!;

    morphElement(original);

    expect(original.isConnected).toBe(true);
    expect(document.querySelector('action-menu')).toBe(original);
  });
});

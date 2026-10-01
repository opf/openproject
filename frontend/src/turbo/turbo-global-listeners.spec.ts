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

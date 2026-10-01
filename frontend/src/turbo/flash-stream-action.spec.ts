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
import { registerFlashStreamAction } from './flash-stream-action';

describe('registerFlashStreamAction', () => {
  beforeEach(() => {
    registerFlashStreamAction();
    document.body.innerHTML = '<div id="primerized-flash-messages"></div>';
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  function flash(innerHTML:string) {
    const element = document.createElement('turbo-stream');
    element.innerHTML = `<template>${innerHTML}</template>`;
    StreamActions.flash.call(element);
  }

  it('appends the flash to the flash-messages container', () => {
    flash('<div class="flash">Saved</div>');

    const target = document.getElementById('primerized-flash-messages')!;
    expect(target.querySelector('.flash')?.textContent).toBe('Saved');
  });

  it('replaces an existing flash that shares its unique key', () => {
    flash('<div class="flash" data-unique-key="k1">First</div>');
    flash('<div class="flash" data-unique-key="k1">Second</div>');

    const target = document.getElementById('primerized-flash-messages')!;
    const flashes = target.querySelectorAll('[data-unique-key="k1"]');
    expect(flashes).toHaveLength(1);
    expect(flashes[0].textContent).toBe('Second');
  });
});

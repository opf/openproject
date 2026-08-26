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
import { registerInputCaptionStreamAction } from './input-caption-stream-action';

describe('registerInputCaptionStreamAction', () => {
  beforeEach(() => {
    registerInputCaptionStreamAction();
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  function addCaption(attributes:Record<string, string>) {
    const element = document.createElement('turbo-stream');
    Object.entries(attributes).forEach(([name, value]) => element.setAttribute(name, value));
    StreamActions.addInputCaption.call(element);
  }

  it('appends a caption to the FormControl wrapping the target input', () => {
    document.body.innerHTML = '<div class="FormControl"><input id="email"></div>';

    addCaption({ target: '#email', caption: 'Required' });

    const captions = document.querySelectorAll('.FormControl .FormControl-caption');
    expect(captions).toHaveLength(1);
    expect(captions[0].textContent).toBe('Required');
  });

  it('replaces existing captions when clean_other_captions is true', () => {
    document.body.innerHTML = '<div class="FormControl">'
      + '<input id="email"><span class="FormControl-caption">Stale</span></div>';

    addCaption({ target: '#email', caption: 'Fresh', clean_other_captions: 'true' });

    const captions = document.querySelectorAll('.FormControl .FormControl-caption');
    expect(captions).toHaveLength(1);
    expect(captions[0].textContent).toBe('Fresh');
  });
});

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

import { render } from 'lit-html';
import { timeEntryPopoverHtml } from './te-calendar.component';

describe('timeEntryPopoverHtml', () => {
  let host:HTMLElement;

  beforeEach(() => {
    host = document.createElement('div');
  });

  const rows = [{ label: 'Project', value: 'Demo' }, { label: 'Hours', value: '2h' }];

  it('renders an anchored popover with the Primer message wrapper', () => {
    render(timeEntryPopoverHtml('pop-1', 'anchor-1', rows, null), host);
    const popover = host.querySelector('anchored-position')!;
    expect(popover.id).toBe('pop-1');
    expect(popover.getAttribute('anchor')).toBe('anchor-1');
    expect(popover.getAttribute('popover')).toBe('hint');
    expect(popover.getAttribute('role')).toBe('dialog');
    expect(popover.classList.contains('op-anchored-popover--host')).toBe(true);
    expect(host.querySelector('.Popover-message.op-anchored-popover')).not.toBeNull();
    expect(host.textContent).toContain('Project:');
    expect(host.textContent).toContain('Demo');
  });

  it('renders the caret from the placement', () => {
    render(timeEntryPopoverHtml('pop-1', 'anchor-1', rows, { side: 'right', offset: 20 }), host);
    const message = host.querySelector<HTMLElement>('.Popover-message')!;
    expect(message.classList.contains('Popover-message--right')).toBe(true);
    expect(message.style.getPropertyValue('--op-anchored-popover-caret-offset')).toBe('20px');
  });
});

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
import { within } from '@testing-library/dom';
import { timeEntryPopoverHtml } from './te-calendar-popover';

describe('timeEntryPopoverHtml', () => {
  let host:HTMLElement;

  beforeEach(() => {
    host = document.createElement('div');
  });

  const rows = [{ label: 'Project', value: 'Demo' }, { label: 'Hours', value: '2h' }];

  it('renders a hint popover anchored to the entry', () => {
    render(timeEntryPopoverHtml('pop-1', 'anchor-1', rows, null), host);
    const popover = host.querySelector('anchored-position')!;

    expect(popover).toHaveAttribute('id', 'pop-1');
    expect(popover).toHaveAttribute('anchor', 'anchor-1');
    expect(popover).toHaveAttribute('popover', 'hint');
    expect(popover).toHaveAttribute('role', 'dialog');
    expect(popover).toHaveClass('op-anchored-popover--host');
  });

  it('lists every row as label and value', () => {
    render(timeEntryPopoverHtml('pop-1', 'anchor-1', rows, null), host);
    const entries = within(host).getAllByRole('listitem');

    expect(entries).toHaveLength(2);
    expect(entries[0]).toHaveTextContent('Project: Demo');
    expect(entries[1]).toHaveTextContent('Hours: 2h');
  });

  it('renders the caret from the placement', () => {
    render(timeEntryPopoverHtml('pop-1', 'anchor-1', rows, { side: 'right', offset: 20 }), host);
    const message = host.querySelector<HTMLElement>('.Popover-message')!;

    expect(message).toHaveClass('Popover-message--right');
    expect(message.style.getPropertyValue('--op-anchored-popover-caret-offset')).toBe('20px');
  });
});

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
import { popoverMessage } from './popover-message';

describe('popoverMessage', () => {
  let host:HTMLElement;

  beforeEach(() => {
    host = document.createElement('div');
  });

  const message = () => host.querySelector<HTMLElement>('.Popover-message')!;

  it('renders the content inside a Primer popover message', () => {
    render(popoverMessage('Launch'), host);
    expect(within(host).getByText('Launch')).toHaveClass('Popover-message', 'op-anchored-popover');
  });

  it('renders an element as content', () => {
    const el = document.createElement('strong');
    el.textContent = 'Milestone';
    render(popoverMessage(el), host);
    expect(within(host).getByText('Milestone')).toBe(el);
    expect(el.parentElement).toBe(message());
  });

  it('uses the default (top) caret when no placement is known', () => {
    render(popoverMessage('x'), host);
    expect(message()).toHaveClass('Popover-message op-anchored-popover', { exact: true });
    expect(message().style.getPropertyValue('--op-anchored-popover-caret-offset')).toBe('');
  });

  it.each([
    ['bottom', 'Popover-message--bottom'],
    ['left', 'Popover-message--left'],
    ['right', 'Popover-message--right'],
  ] as const)('sets the %s caret class and offset', (side, className) => {
    render(popoverMessage('x', { side, offset: 42 }), host);
    expect(message()).toHaveClass(className);
    expect(message().style.getPropertyValue('--op-anchored-popover-caret-offset')).toBe('42px');
  });

  it('drops the modifier again when re-rendered with a top caret', () => {
    render(popoverMessage('x', { side: 'bottom', offset: 10 }), host);
    render(popoverMessage('x', { side: 'top', offset: 10 }), host);
    expect(message()).not.toHaveClass('Popover-message--bottom');
  });
});

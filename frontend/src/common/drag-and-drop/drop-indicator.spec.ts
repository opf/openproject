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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  clearDropIndicator,
  dropPositionAttribute,
  dropPositionOwnerAttribute,
  renderDropIndicator,
} from './drop-indicator';

describe('drop indicator owner tracking', () => {
  it('records the owner when rendering', () => {
    const el = document.createElement('div');
    renderDropIndicator(el, 'top', 'item-1');

    expect(el.getAttribute(dropPositionAttribute)).toBe('top');
    expect(el.getAttribute(dropPositionOwnerAttribute)).toBe('item-1');
  });

  it('does not clear an indicator another owner rendered since', () => {
    const el = document.createElement('div');
    renderDropIndicator(el, 'top', 'item-1');
    renderDropIndicator(el, 'bottom', 'item-2');
    clearDropIndicator(el, 'item-1');

    expect(el.getAttribute(dropPositionAttribute)).toBe('bottom');

    clearDropIndicator(el, 'item-2');
    expect(el.hasAttribute(dropPositionAttribute)).toBe(false);
    expect(el.hasAttribute(dropPositionOwnerAttribute)).toBe(false);
  });
});

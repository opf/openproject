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

import { focusAfterMenuClose } from './menu-focus';

describe('focusAfterMenuClose', () => {
  let target:HTMLButtonElement;
  let other:HTMLInputElement;

  beforeEach(() => {
    target = document.createElement('button');
    target.textContent = 'Create';
    other = document.createElement('input');
    document.body.append(target, other);
    (document.activeElement as HTMLElement|null)?.blur();
  });

  afterEach(() => {
    target.remove();
    other.remove();
  });

  it('focuses the target after escape', () => {
    other.focus();

    focusAfterMenuClose(target, 'escape');

    expect(target).toHaveFocus();
  });

  it('focuses the target after an action that left focus on the body', () => {
    focusAfterMenuClose(target, 'action');

    expect(target).toHaveFocus();
  });

  it('leaves focus where an action moved it', () => {
    other.focus();

    focusAfterMenuClose(target, 'action');

    expect(other).toHaveFocus();
  });

  it('focuses the target after a scroll close that left focus on the body', () => {
    focusAfterMenuClose(target, 'scroll');

    expect(target).toHaveFocus();
  });

  it('leaves focus alone after an outside close', () => {
    focusAfterMenuClose(target, 'outside');

    expect(document.activeElement).toBe(document.body);
  });

  it('leaves focus alone without a reason', () => {
    focusAfterMenuClose(target, undefined);

    expect(document.activeElement).toBe(document.body);
  });
});

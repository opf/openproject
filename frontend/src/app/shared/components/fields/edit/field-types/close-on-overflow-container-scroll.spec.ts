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

import { fireEvent } from '@testing-library/dom';
import { closeOnOverflowContainerScroll } from './close-on-overflow-container-scroll';

describe('closeOnOverflowContainerScroll', () => {
  afterEach(() => {
    document.body.replaceChildren();
  });

  it('does nothing outside a hidden-overflow container', () => {
    const close = vi.fn<() => void>();

    expect(() => closeOnOverflowContainerScroll(close)).not.toThrow();
    expect(close).not.toHaveBeenCalled();
  });

  it('closes once when the hidden-overflow container scrolls', () => {
    const container = document.createElement('div');
    container.className = '__hidden_overflow_container';
    document.body.appendChild(container);
    const close = vi.fn<() => void>();

    closeOnOverflowContainerScroll(close);
    fireEvent.scroll(container);
    fireEvent.scroll(container);

    expect(close).toHaveBeenCalledOnce();
  });
});

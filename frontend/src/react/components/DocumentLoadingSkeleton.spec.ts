/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { render } from '@testing-library/react';
import { createElement } from 'react';
import { DocumentLoadingSkeleton } from './DocumentLoadingSkeleton';

describe('DocumentLoadingSkeleton', () => {
  it('renders title and content skeleton boxes', () => {
    const { container } = render(createElement(DocumentLoadingSkeleton));

    const skeletons = Array.from(container.querySelectorAll<HTMLElement>('.SkeletonBox'));

    expect(skeletons).toHaveLength(2);
    expect(skeletons[0].style.width).toBe('25%');
    expect(skeletons[0].style.height).toBe('40px');
    expect(skeletons[1].style.width).toBe('100%');
    expect(skeletons[1].style.height).toBe('150px');
  });
});

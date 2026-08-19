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

import { vi } from 'vitest';

import { flipMove } from './flip-helper';

describe('flipMove', () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  function row():HTMLElement {
    return document.createElement('li');
  }

  function stubReducedMotion(matches:boolean) {
    vi.spyOn(window, 'matchMedia').mockReturnValue({ matches } as MediaQueryList);
  }

  function stubRects(element:HTMLElement, first:{ top:number; left:number }, last:{ top:number; left:number }) {
    vi.spyOn(element, 'getBoundingClientRect')
      .mockReturnValueOnce({ ...first } as DOMRect)
      .mockReturnValueOnce({ ...last } as DOMRect);
  }

  it('runs the mutation and animates each element from its previous position', () => {
    stubReducedMotion(false);

    const element = row();
    const animate = vi.spyOn(element, 'animate').mockReturnValue({} as Animation);
    const mutate = vi.fn();

    stubRects(element, { top: 100, left: 20 }, { top: 0, left: 0 });
    flipMove([element], mutate);

    expect(mutate).toHaveBeenCalledOnce();
    expect(animate).toHaveBeenCalledWith(
      [{ transform: 'translate(20px, 100px)' }, { transform: 'none' }],
      { duration: 200, easing: 'ease' },
    );
  });

  it('does not animate an element that did not move', () => {
    stubReducedMotion(false);

    const element = row();
    const animate = vi.spyOn(element, 'animate');
    const mutate = vi.fn();

    stubRects(element, { top: 50, left: 0 }, { top: 50, left: 0 });
    flipMove([element], mutate);

    expect(mutate).toHaveBeenCalledOnce();
    expect(animate).not.toHaveBeenCalled();
  });

  it('applies the mutation without animating when reduced motion is preferred', () => {
    stubReducedMotion(true);

    const element = row();
    const animate = vi.spyOn(element, 'animate');
    const mutate = vi.fn();

    flipMove([element], mutate);

    expect(mutate).toHaveBeenCalledOnce();
    expect(animate).not.toHaveBeenCalled();
  });
});

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

import React, { act, createElement } from 'react';
import { createRoot, type Root } from 'react-dom/client';
import { useCardSubjectClicks } from './card-subject-clicks';

function Harness() {
  const [root, setRoot] = React.useState<HTMLDivElement|null>(null);
  useCardSubjectClicks(root);
  return createElement('div', { ref: setRoot, style: { position: 'fixed', inset: 0 } },
    createElement('div', { style: { pointerEvents: 'none' } },
      createElement('a', {
        href: 'https://op.example.com/wp/42',
        'data-whiteboard-card-subject': '',
        style: { position: 'fixed', left: '100px', top: '100px', width: '200px', height: '20px' },
      }, 'Plan the launch')));
}

describe('useCardSubjectClicks', () => {
  let container:HTMLElement;
  let root:Root;
  let open:ReturnType<typeof vi.spyOn>;

  function pointer(type:string, x:number, y:number) {
    act(() => {
      container.firstElementChild!.dispatchEvent(new PointerEvent(type, {
        bubbles: true, clientX: x, clientY: y, pointerId: 1, isPrimary: true,
      }));
    });
  }

  beforeAll(() => {
    (globalThis as { IS_REACT_ACT_ENVIRONMENT?:boolean }).IS_REACT_ACT_ENVIRONMENT = true;
  });

  beforeEach(() => {
    container = document.createElement('div');
    document.body.appendChild(container);
    root = createRoot(container);
    open = vi.spyOn(window, 'open').mockReturnValue(null);
    act(() => root.render(createElement(Harness)));
  });

  afterEach(() => {
    vi.restoreAllMocks();
    act(() => root.unmount());
    container.remove();
  });

  it('opens the work package when the subject is clicked', () => {
    pointer('pointerdown', 150, 110);
    pointer('pointerup', 152, 111);

    expect(open).toHaveBeenCalledWith('https://op.example.com/wp/42', '_blank', 'noopener');
  });

  it('does not open the work package when the card is dragged', () => {
    pointer('pointerdown', 150, 110);
    pointer('pointerup', 250, 300);

    expect(open).not.toHaveBeenCalled();
  });

  it('does not open the work package for clicks outside of the subject', () => {
    pointer('pointerdown', 150, 200);
    pointer('pointerup', 150, 200);

    expect(open).not.toHaveBeenCalled();
  });
});

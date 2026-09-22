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

import '@openproject/primer-view-components/app/components/primer/anchored_position';
import type AnchoredPositionElement from '@openproject/primer-view-components/app/components/primer/anchored_position';
import { liveRect } from './live-rect';
import { placePopover } from './popover-placement';

describe('liveRect', () => {
  it('reads the source again in the next task', async () => {
    let current = new DOMRect(10, 20, 30, 40);
    const rect = liveRect(() => current);

    expect(rect.left).toBe(10);
    expect(rect.bottom).toBe(60);

    current = new DOMRect(100, 200, 30, 40);
    await Promise.resolve();
    expect(rect.left).toBe(100);
    expect(rect.bottom).toBe(240);
  });

  it('reads the source once per task', () => {
    const source = vi.fn(() => new DOMRect(1, 2, 3, 4));
    const rect = liveRect(source);

    expect(rect.left + rect.top + rect.right + rect.bottom).toBe(13);
    expect(source).toHaveBeenCalledTimes(1);
  });

  it('remains a DOMRect', () => {
    const rect = liveRect(() => new DOMRect(1, 2, 3, 4));

    expect(rect).toBeInstanceOf(DOMRect);
    expect(rect.toJSON()).toEqual(new DOMRect(1, 2, 3, 4).toJSON());
  });

  it('anchors a popover where the source currently is', async () => {
    const popover = document.createElement('anchored-position') as AnchoredPositionElement;
    popover.setAttribute('popover', 'manual');
    popover.setAttribute('side', 'outside-top');
    popover.setAttribute('align', 'center');
    popover.style.cssText = 'margin: 0; padding: 0; border: 0;';
    popover.innerHTML = '<div style="width: 100px; height: 60px;"></div>';
    document.body.append(popover);

    let anchor = new DOMRect(200, 200, 10, 10);
    const rect = liveRect(() => anchor);
    popover.anchorElement = rect as unknown as HTMLElement;
    popover.togglePopover(true);

    const centre = () => {
      const box = popover.getBoundingClientRect();
      return box.left + box.width / 2;
    };

    placePopover(popover, rect);
    expect(centre()).toBeCloseTo(205, 0);

    anchor = new DOMRect(300, 200, 10, 10);
    await Promise.resolve();
    placePopover(popover, rect);
    expect(centre()).toBeCloseTo(305, 0);

    popover.remove();
  });
});

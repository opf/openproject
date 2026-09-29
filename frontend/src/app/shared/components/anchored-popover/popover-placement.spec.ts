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
import { placePopover } from './popover-placement';

describe('placePopover', () => {
  let popover:AnchoredPositionElement;
  let anchor:HTMLElement;

  beforeEach(() => {
    anchor = document.createElement('div');
    anchor.style.cssText = 'position: fixed; top: 200px; left: 200px; width: 10px; height: 10px;';
    popover = document.createElement('anchored-position') as AnchoredPositionElement;
    popover.setAttribute('popover', 'manual');
    popover.setAttribute('side', 'outside-top');
    popover.setAttribute('align', 'center');
    popover.setAttribute('anchor-offset', 'spacious');
    popover.style.cssText = 'margin: 0; padding: 0; border: 0;';
    popover.innerHTML = '<div style="width: 100px; height: 60px;"></div>';
    document.body.append(anchor, popover);
    popover.anchorElement = anchor;
    popover.togglePopover(true);
  });

  afterEach(() => {
    popover.remove();
    anchor.remove();
    document.body.style.minHeight = '';
    window.scrollTo(0, 0);
  });

  const centred = () => popover.getBoundingClientRect().width / 2;

  it('places the caret on the edge facing the anchor as soon as the popover is open', () => {
    expect(placePopover(popover, anchor)).toEqual({ side: 'bottom', offset: centred() });
  });

  it('moves the popover into place without waiting for a frame', () => {
    anchor.style.left = '300px';
    placePopover(popover, anchor);

    const box = popover.getBoundingClientRect();
    expect(box.left + box.width / 2).toBeCloseTo(305, 0);
    expect(box.bottom).toBeLessThanOrEqual(200);
  });

  it('follows the flip when the anchor is too close to the viewport edge', () => {
    anchor.style.top = '0px';
    expect(placePopover(popover, anchor).side).toBe('top');
  });

  it('accepts a rectangle as the anchor', () => {
    expect(placePopover(popover, new DOMRect(200, 200, 10, 10))).toEqual({ side: 'bottom', offset: centred() });
  });

  it('agrees with where anchored-position puts the popover', async () => {
    const caret = placePopover(popover, anchor);
    await new Promise(requestAnimationFrame);

    const box = popover.getBoundingClientRect();
    expect(box.bottom).toBeLessThanOrEqual(200);
    expect(caret.offset).toBeCloseTo(205 - box.left, 0);
  });

  it('faces the anchor on a scrolled page', async () => {
    document.body.style.minHeight = '3000px';
    window.scrollTo(0, 1000);
    anchor.style.cssText = 'position: absolute; top: 1200px; left: 200px; width: 10px; height: 10px;';

    const caret = placePopover(popover, anchor);
    expect(caret.side).toBe('bottom');

    await new Promise(requestAnimationFrame);
    const box = popover.getBoundingClientRect();
    expect(box.bottom).toBeLessThanOrEqual(anchor.getBoundingClientRect().top);
    expect(caret.offset).toBeCloseTo(205 - box.left, 0);
  });
});

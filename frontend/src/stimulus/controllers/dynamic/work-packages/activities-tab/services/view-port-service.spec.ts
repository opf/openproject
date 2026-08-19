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
import { ViewPortService } from './view-port-service';

// isMobile() compares against window.innerWidth, so pick a breakpoint either
// side of the test window to force one layout or the other.
function serviceForViewport(mobile:boolean):ViewPortService {
  const breakpoint = mobile ? window.innerWidth + 1 : 0;
  return new ViewPortService('notifications', 'work_packages/details', breakpoint);
}

describe('ViewPortService#anchorScrollOffset', () => {
  let contentBody:HTMLElement;
  let tabContent:HTMLElement;

  beforeEach(() => {
    contentBody = document.createElement('div'); // mobile scroll container
    contentBody.id = 'content-body';
    document.body.appendChild(contentBody);

    tabContent = document.createElement('div'); // desktop scroll container
    tabContent.className = 'tabcontent';
    document.body.appendChild(tabContent);
  });

  afterEach(() => {
    contentBody.remove();
    tabContent.remove();
    vi.restoreAllMocks();
  });

  // Pins a header to the top of the scroll container and makes it the only box
  // the layout probe finds there. `reach` is how far it extends below the
  // container top.
  function pinHeader(container:HTMLElement, reach:number) {
    container.getBoundingClientRect = () => ({ top: 0, left: 0 }) as DOMRect;
    const header = document.createElement('div');
    header.style.position = 'sticky';
    container.appendChild(header);
    header.getBoundingClientRect = () => ({ bottom: reach }) as DOMRect;
    vi.spyOn(document, 'elementsFromPoint').mockReturnValue([header]);
  }

  it('seats the comment below a header pinned over the scroll container, plus a gap', () => {
    pinHeader(contentBody, 185);

    // 185 (measured toolbar) + 16 (gap)
    expect(serviceForViewport(true).anchorScrollOffset()).toBe(201);
  });

  it('uses just the gap when nothing is pinned over the container', () => {
    vi.spyOn(document, 'elementsFromPoint').mockReturnValue([]);

    expect(serviceForViewport(true).anchorScrollOffset()).toBe(16);
  });

  it('ignores an unpinned element sitting at the container top', () => {
    // The layout reads as mobile well above the breakpoint where the toolbar
    // turns sticky, so in that window the toolbar is still static and scrolls
    // away. Reading the live position keeps it from reserving space it won't hold.
    contentBody.getBoundingClientRect = () => ({ top: 0, left: 0 }) as DOMRect;
    const staticHeader = document.createElement('div');
    staticHeader.style.position = 'static';
    staticHeader.getBoundingClientRect = () => ({ bottom: 185 }) as DOMRect;
    contentBody.appendChild(staticHeader);
    vi.spyOn(document, 'elementsFromPoint').mockReturnValue([staticHeader]);

    expect(serviceForViewport(true).anchorScrollOffset()).toBe(16);
  });

  it('seats the comment a small gap below the top on desktop, showing only the stem', () => {
    vi.spyOn(document, 'elementsFromPoint').mockReturnValue([]);

    // .tabcontent has nothing pinned over it, so the offset is just the gap; a
    // large offset here exposed the bottom of the preceding comment.
    expect(serviceForViewport(false).anchorScrollOffset()).toBe(16);
  });

  it('ignores a pinned element that sits outside the scroll container', () => {
    // The desktop toolbar is sticky but lives above .tabcontent, not within it,
    // so it must not count toward the offset even while it overlaps the probe.
    tabContent.getBoundingClientRect = () => ({ top: 0, left: 0 }) as DOMRect;
    const outsideHeader = document.createElement('div');
    outsideHeader.style.position = 'sticky';
    outsideHeader.getBoundingClientRect = () => ({ bottom: 185 }) as DOMRect;
    document.body.appendChild(outsideHeader);
    vi.spyOn(document, 'elementsFromPoint').mockReturnValue([outsideHeader]);

    try {
      expect(serviceForViewport(false).anchorScrollOffset()).toBe(16);
    } finally {
      outsideHeader.remove();
    }
  });
});

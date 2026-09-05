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

import { visibleRect } from './visible-rect';

describe('visibleRect', () => {
  let fixture:HTMLElement;

  const mount = (markup:string) => {
    fixture.innerHTML = markup;
    return {
      container: fixture.querySelector<HTMLElement>('[data-container]')!,
      target: fixture.querySelector<HTMLElement>('[data-target]')!,
    };
  };

  const paddingBox = (element:HTMLElement) => {
    const rect = element.getBoundingClientRect();
    return {
      left: rect.left + element.clientLeft,
      top: rect.top + element.clientTop,
      right: rect.left + element.clientLeft + element.clientWidth,
      bottom: rect.top + element.clientTop + element.clientHeight,
    };
  };

  beforeEach(() => {
    fixture = document.createElement('div');
    fixture.style.cssText = 'position: absolute; top: 0; left: 0;';
    document.body.append(fixture);
  });

  afterEach(() => {
    fixture.remove();
  });

  it('returns the element rect when nothing clips it', () => {
    const { target } = mount(`
      <div data-container style="position: relative; width: 200px; height: 100px; overflow: auto;">
        <div style="position: relative; width: 400px; height: 100px;">
          <div data-target style="position: absolute; left: 10px; top: 10px; width: 100px; height: 20px;"></div>
        </div>
      </div>
    `);

    expect(visibleRect(target)).toEqual(target.getBoundingClientRect());
  });

  it('cuts the part hidden behind a scroller edge', () => {
    const { container, target } = mount(`
      <div data-container style="position: relative; width: 200px; height: 100px; overflow: auto;">
        <div style="position: relative; width: 400px; height: 100px;">
          <div data-target style="position: absolute; left: 150px; top: 10px; width: 100px; height: 20px;"></div>
        </div>
      </div>
    `);

    const rect = visibleRect(target);
    expect(rect.left).toBeCloseTo(target.getBoundingClientRect().left, 0);
    expect(rect.right).toBeCloseTo(paddingBox(container).right, 0);
    expect(rect.width).toBeCloseTo(50, 0);
    expect(rect.height).toBeCloseTo(20, 0);
  });

  it('follows the scroll position', () => {
    const { container, target } = mount(`
      <div data-container style="position: relative; width: 200px; height: 100px; overflow: auto;">
        <div style="position: relative; width: 400px; height: 100px;">
          <div data-target style="position: absolute; left: 150px; top: 10px; width: 100px; height: 20px;"></div>
        </div>
      </div>
    `);
    container.scrollLeft = 100;

    const rect = visibleRect(target);
    expect(rect.left).toBeCloseTo(paddingBox(container).left + 50, 0);
    expect(rect.width).toBeCloseTo(100, 0);
  });

  it('clips at the padding edge, inside the border', () => {
    const { container, target } = mount(`
      <div data-container style="position: relative; box-sizing: content-box; width: 200px; height: 100px; overflow: auto; border: 10px solid black;">
        <div style="position: relative; width: 400px; height: 40px;">
          <div data-target style="position: absolute; left: 150px; top: 10px; width: 100px; height: 20px;"></div>
        </div>
      </div>
    `);

    const rect = visibleRect(target);
    expect(rect.right).toBeCloseTo(paddingBox(container).right, 0);
    expect(rect.right).toBeLessThan(container.getBoundingClientRect().right);
    expect(rect.width).toBeCloseTo(50, 0);
  });

  it('excludes a reserved scrollbar', () => {
    const { container, target } = mount(`
      <div data-container style="position: relative; width: 200px; height: 100px; overflow: scroll;">
        <div style="position: relative; width: 400px; height: 400px;">
          <div data-target style="position: absolute; left: 150px; top: 10px; width: 100px; height: 20px;"></div>
        </div>
      </div>
    `);

    const rect = visibleRect(target);
    expect(rect.right).toBeCloseTo(paddingBox(container).right, 0);
    expect(rect.width).toBeLessThanOrEqual(50);
  });

  it('applies every clipping ancestor on its own axes', () => {
    const { container, target } = mount(`
      <div data-container style="position: relative; width: 200px; height: 100px; overflow: auto;">
        <div style="position: relative; width: 400px; height: 40px; overflow: hidden;">
          <div data-target style="position: absolute; left: 150px; top: 20px; width: 100px; height: 40px;"></div>
        </div>
      </div>
    `);

    const rect = visibleRect(target);
    expect(rect.width).toBeCloseTo(50, 0);
    expect(rect.height).toBeCloseTo(20, 0);
    expect(rect.right).toBeCloseTo(paddingBox(container).right, 0);
  });

  it('ignores ancestors that let content overflow', () => {
    const { target } = mount(`
      <div data-container style="position: relative; width: 50px; height: 50px; overflow: visible;">
        <div data-target style="position: absolute; left: 10px; top: 10px; width: 100px; height: 100px;"></div>
      </div>
    `);

    expect(visibleRect(target)).toEqual(target.getBoundingClientRect());
  });

  it('is empty when the element is scrolled out of view', () => {
    const { target } = mount(`
      <div data-container style="position: relative; width: 200px; height: 100px; overflow: auto;">
        <div style="position: relative; width: 400px; height: 100px;">
          <div data-target style="position: absolute; left: 300px; top: 10px; width: 50px; height: 20px;"></div>
        </div>
      </div>
    `);

    const rect = visibleRect(target);
    expect(rect.width).toBe(0);
    expect(rect.height).toBeCloseTo(20, 0);
  });
});

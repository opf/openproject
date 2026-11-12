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
import { createScrollSync } from './wp-table-scroll-sync';

describe('scroll sync lifetime', () => {
  let root:HTMLElement;
  let table:HTMLElement;
  let timeline:HTMLElement;
  let frames:Map<number, FrameRequestCallback>;
  let sync:{ update(visible:boolean):void; destroy():void };

  beforeEach(() => {
    frames = new Map();
    let nextId = 0;
    vi.spyOn(window, 'requestAnimationFrame').mockImplementation((callback) => {
      nextId += 1;
      frames.set(nextId, callback);
      return nextId;
    });
    vi.spyOn(window, 'cancelAnimationFrame').mockImplementation((id) => { frames.delete(id); });
    root = document.createElement('div');
    root.innerHTML = '<div class="work-packages-tabletimeline--table-side"></div><div class="work-packages-tabletimeline--timeline-side"></div>';
    document.body.appendChild(root);
    [table, timeline] = Array.from(root.children) as HTMLElement[];
    for (const side of [table, timeline]) {
      side.style.cssText = 'display: block; height: 40px; width: 80px; overflow: auto';
      side.innerHTML = '<div style="height: 1000px; width: 1000px"></div>';
    }
    sync = createScrollSync(root);
  });

  afterEach(() => {
    sync.destroy();
    root.remove();
    vi.restoreAllMocks();
  });

  // Firefox snaps scroll offsets to device pixels, so a requested offset can land a fraction short.
  function expectScrollTops(tableTop:number, timelineTop:number) {
    expect(table.scrollTop).toBeCloseTo(tableTop, 0);
    expect(timeline.scrollTop).toBeCloseTo(timelineTop, 0);
  }

  function advanceFrames() {
    const pending = [...frames.values()];
    frames.clear();
    pending.forEach((callback) => callback(0));
  }

  for (const action of ['disable', 'destroy'] as const) {
    it(`cancels queued wheel effects and removes both sides on ${action}`, () => {
      const unrelated = vi.fn();
      for (const side of [table, timeline]) {
        side.addEventListener('wheel', unrelated);
        side.addEventListener('scroll', unrelated);
      }
      sync.update(true);
      fireEvent.wheel(table, { deltaY: 10, deltaX: 10 });
      fireEvent.wheel(timeline, { deltaY: 10, deltaX: 10 });
      if (action === 'disable') sync.update(false);
      else sync.destroy();
      advanceFrames();
      expect([table.scrollTop, timeline.scrollTop, table.scrollLeft, timeline.scrollLeft]).toEqual([0, 0, 0, 0]);
      table.scrollTop = 40;
      fireEvent.scroll(table);
      expect(timeline.scrollTop).toBe(0);
      timeline.scrollTop = 80;
      fireEvent.scroll(timeline);
      expectScrollTops(40, 80);
      fireEvent.wheel(table, { deltaY: 10 });
      fireEvent.wheel(timeline, { deltaY: 10 });
      advanceFrames();
      expectScrollTops(40, 80);
      expect(unrelated).toHaveBeenCalledTimes(6);
    });
  }

  it.each(['wheel', 'scroll'] as const)('isolates a failed %s removal from every other release', (type) => {
    const error = new Error('listener removal');
    const report = vi.spyOn(console, 'error').mockImplementation(() => undefined);
    const remove = table.removeEventListener.bind(table);
    const tableRemoval = vi.spyOn(table, 'removeEventListener').mockImplementation((event, callback, options) => {
      if (event === type) throw error;
      remove(event, callback, options);
    });
    const timelineRemoval = vi.spyOn(timeline, 'removeEventListener');
    const cancel = vi.spyOn(window, 'cancelAnimationFrame');
    cancel.mockImplementationOnce(() => { throw new Error('frame cancellation'); });
    sync.update(true);
    fireEvent.wheel(table, { deltaY: 10 });
    fireEvent.wheel(timeline, { deltaY: 10 });
    const callbacks = [...frames.values()];
    expect(() => sync.destroy()).not.toThrow();
    expect(tableRemoval).toHaveBeenCalledTimes(2);
    expect(timelineRemoval).toHaveBeenCalledTimes(2);
    expect(cancel).toHaveBeenCalledTimes(2);
    expect(report).toHaveBeenCalledTimes(2);
    expect(() => sync.destroy()).not.toThrow();
    expect(cancel).toHaveBeenCalledTimes(2);
    expect(tableRemoval).toHaveBeenCalledTimes(2);
    const scheduled = vi.spyOn(window, 'requestAnimationFrame');
    scheduled.mockClear();
    table.scrollTop = 40;
    fireEvent.scroll(table);
    fireEvent.wheel(table, { deltaY: 10 });
    callbacks.forEach((callback) => callback(0));
    expectScrollTops(40, 0);
    expect(scheduled).not.toHaveBeenCalled();
    // The injected boundary deliberately left a native listener attached.
    tableRemoval.mock.calls.forEach(([event, callback, options]) => remove(event, callback, options));
  });

  it('keeps wheel deltas and scroll physics across repeated visibility changes', () => {
    sync.update(true);
    sync.update(true);
    fireEvent.wheel(table, { deltaY: 1, deltaX: -1 });
    advanceFrames();
    expectScrollTops(15, 30);
    sync.update(false);
    sync.update(false);
    sync.update(true);
    fireEvent.wheel(timeline, { deltaY: -1 });
    advanceFrames();
    expect([table.scrollTop, timeline.scrollTop]).toEqual([0, 0]);
    fireEvent.wheel(table, { deltaY: 10, shiftKey: true });
    advanceFrames();
    expect([table.scrollTop, timeline.scrollTop]).toEqual([0, 0]);
    sync.destroy();
    sync.update(true);
    fireEvent.wheel(table, { deltaY: 10 });
    advanceFrames();
    expect([table.scrollTop, timeline.scrollTop]).toEqual([0, 0]);
  });
});

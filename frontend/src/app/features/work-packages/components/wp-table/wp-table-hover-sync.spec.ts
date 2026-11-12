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
import { WpTableHoverSync } from './wp-table-hover-sync';

describe('WpTableHoverSync lifetime', () => {
  let root:HTMLElement;
  let hover:WpTableHoverSync;
  let frames:Map<number, FrameRequestCallback>;
  let tableRow:HTMLElement;
  let timelineRow:HTMLElement;

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
    root.innerHTML = '<table><tbody><tr class="wp-row-1" data-work-package-id="1"><td>Subject</td></tr></tbody></table><div class="wp-timeline-cell wp-row-1" data-work-package-id="1">Timeline</div>';
    document.body.appendChild(root);
    tableRow = root.querySelector('tr')!;
    timelineRow = root.querySelector('.wp-timeline-cell')!;
    hover = new WpTableHoverSync(root);
    hover.activate();
  });

  afterEach(() => {
    hover.deactivate();
    root.remove();
    vi.restoreAllMocks();
  });

  function advanceFrames() {
    const pending = [...frames.values()];
    frames.clear();
    pending.forEach((callback) => callback(0));
  }

  it('cancels queued hover painting and preserves unrelated listeners on both sides', () => {
    const unrelated = vi.fn();
    tableRow.addEventListener('mousemove', unrelated);
    timelineRow.addEventListener('mousemove', unrelated);
    fireEvent.mouseMove(tableRow);
    hover.deactivate();
    advanceFrames();
    expect(tableRow).not.toHaveClass('row-hovered');
    expect(timelineRow).not.toHaveClass('row-hovered');
    fireEvent.mouseMove(tableRow);
    fireEvent.mouseMove(timelineRow);
    advanceFrames();
    expect(unrelated).toHaveBeenCalledTimes(3);
    expect(tableRow).not.toHaveClass('row-hovered');
    expect(timelineRow).not.toHaveClass('row-hovered');
  });

  it('isolates failed listener, frame and class releases during deactivation', () => {
    const report = vi.spyOn(console, 'error').mockImplementation(() => undefined);
    fireEvent.mouseMove(tableRow);
    advanceFrames();
    fireEvent.mouseMove(timelineRow);
    fireEvent.mouseMove(tableRow);
    const callbacks = [...frames.values()];
    const removal = vi.spyOn(window, 'removeEventListener').mockImplementationOnce(() => {
      throw new Error('listener removal');
    });
    const cancel = vi.spyOn(window, 'cancelAnimationFrame');
    cancel.mockImplementationOnce(() => { throw new Error('frame cancellation'); });
    const removeClass = vi.spyOn(tableRow.classList, 'remove').mockImplementationOnce(() => {
      throw new Error('class removal');
    });
    expect(() => hover.deactivate()).not.toThrow();
    expect(cancel).toHaveBeenCalledTimes(2);
    expect(timelineRow).not.toHaveClass('row-hovered');
    expect(report).toHaveBeenCalledTimes(3);
    const scheduled = vi.spyOn(window, 'requestAnimationFrame');
    scheduled.mockClear();
    fireEvent.mouseMove(timelineRow);
    callbacks.forEach((callback) => callback(0));
    expect(scheduled).not.toHaveBeenCalled();
    expect(timelineRow).not.toHaveClass('row-hovered');
    expect(() => hover.deactivate()).not.toThrow();
    expect(cancel).toHaveBeenCalledTimes(2);
    removeClass.mockRestore();
    removal.mockRestore();
    // Repeat disposal removed the native listener after its injected failure.
    hover.activate();
    fireEvent.mouseMove(tableRow);
    advanceFrames();
    expect(tableRow).toHaveClass('row-hovered');
    expect(timelineRow).toHaveClass('row-hovered');
  });

  it('clears painted classes and permits the same target after reactivation', () => {
    fireEvent.mouseMove(tableRow);
    advanceFrames();
    expect(tableRow).toHaveClass('row-hovered');
    expect(timelineRow).toHaveClass('row-hovered');
    hover.deactivate();
    expect(tableRow).not.toHaveClass('row-hovered');
    expect(timelineRow).not.toHaveClass('row-hovered');
    hover.activate();
    hover.activate();
    fireEvent.mouseMove(tableRow);
    advanceFrames();
    expect(tableRow).toHaveClass('row-hovered');
    expect(timelineRow).toHaveClass('row-hovered');
  });
});

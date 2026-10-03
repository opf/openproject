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

import { DestroyRef, Injector } from '@angular/core';
import { TableUiWork } from './table-ui-work';

describe('TableUiWork', () => {
  let injector:ReturnType<typeof Injector.create>;
  let ref:DestroyRef;
  beforeEach(() => {
    injector = Injector.create({ providers: [] });
    ref = injector.get(DestroyRef);
  });
  afterEach(() => {
    if (!ref.destroyed) injector.destroy();
    vi.restoreAllMocks();
  });

  it('runs frames and tasks while the native owner is alive', async () => {
    const work = new TableUiWork(injector.get(DestroyRef));
    const callback = vi.fn();
    work.frame(callback);
    work.task(callback);
    await vi.waitFor(() => expect(callback).toHaveBeenCalledTimes(2));
  });

  it('cancels queued work and guards captured callbacks after destruction', () => {
    const frames:FrameRequestCallback[] = [];
    const frame = vi.spyOn(window, 'requestAnimationFrame').mockImplementation((callback) => frames.push(callback));
    const cancelFrame = vi.spyOn(window, 'cancelAnimationFrame');
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
    try {
      const callback = vi.fn();
      const work = new TableUiWork(injector.get(DestroyRef));
      work.frame(callback);
      work.task(callback);
      injector.destroy();
      frames[0](0);
      vi.runAllTimers();
      expect(cancelFrame).toHaveBeenCalledWith(1);
      expect(callback).not.toHaveBeenCalled();
    } finally {
      vi.useRealTimers();
      frame.mockRestore();
    }
  });

  it('guards a captured task callback even when cancellation cannot stop execution', () => {
    const tasks:(() => void)[] = [];
    const task = vi.spyOn(window, 'setTimeout').mockImplementation((callback) => {
      tasks.push(callback as () => void);
      return tasks.length;
    });
    const clear = vi.spyOn(window, 'clearTimeout').mockImplementation(() => undefined);
    try {
      const work = new TableUiWork(ref);
      const callback = vi.fn();
      work.task(callback);
      injector.destroy();
      tasks[0]();
      expect(clear).toHaveBeenCalledWith(1);
      expect(callback).not.toHaveBeenCalled();
    } finally {
      task.mockRestore();
    }
  });

  it('can cancel work explicitly and schedule again while alive', async () => {
    const work = new TableUiWork(injector.get(DestroyRef));
    const cancelled = vi.fn();
    const next = vi.fn();
    work.task(cancelled);
    work.cancel();
    work.task(next);
    await vi.waitFor(() => expect(next).toHaveBeenCalledTimes(1));
    expect(cancelled).not.toHaveBeenCalled();
  });

  it('is inert when constructed with an already-destroyed native ref', () => {
    const ref = injector.get(DestroyRef);
    injector.destroy();
    const frame = vi.spyOn(window, 'requestAnimationFrame');
    const task = vi.spyOn(window, 'setTimeout');
    expect(() => {
      const work = new TableUiWork(ref);
      work.frame(vi.fn());
      work.task(vi.fn());
      work.cancel();
    }).not.toThrow();
    expect(frame).not.toHaveBeenCalled();
    expect(task).not.toHaveBeenCalled();
  });
});

/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2023 the OpenProject GmbH
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

import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import SettleWindow from './settle-window';

describe('SettleWindow', () => {
  let target:HTMLElement;
  let observers:FakeResizeObserver[];
  let originalResizeObserver:typeof ResizeObserver;

  // Captures each observer so a test can fire its callback and inspect teardown.
  class FakeResizeObserver {
    observed:Element[] = [];

    disconnected = false;

    constructor(public readonly callback:() => void) { observers.push(this); }

    observe(element:Element) { this.observed.push(element); }

    disconnect() { this.disconnected = true; }
  }

  function open(duration = 1000, yieldOn?:string[]) {
    return new SettleWindow({ target, duration, yieldOn });
  }

  beforeEach(() => {
    observers = [];
    target = document.createElement('div');
    originalResizeObserver = globalThis.ResizeObserver;
    vi.stubGlobal('ResizeObserver', FakeResizeObserver);
  });

  afterEach(() => {
    vi.stubGlobal('ResizeObserver', originalResizeObserver);
    vi.restoreAllMocks();
    vi.useRealTimers();
  });

  it('asserts the callback immediately and observes the target', () => {
    const onSettle = vi.fn();

    open().follow(onSettle);

    expect(onSettle).toHaveBeenCalledTimes(1);
    expect(observers[0].observed).toContain(target);
  });

  it('re-asserts the callback each time the target resizes', () => {
    const onSettle = vi.fn();
    open().follow(onSettle);

    observers[0].callback();
    observers[0].callback();

    // one immediate assert plus one per resize
    expect(onSettle).toHaveBeenCalledTimes(3);
  });

  it('closes on its own once the duration elapses', () => {
    vi.useFakeTimers();
    open(1000).follow(vi.fn());

    vi.advanceTimersByTime(1000);

    expect(observers[0].disconnected).toBe(true);
  });

  it('yields to the user on the first scroll gesture', () => {
    open().follow(vi.fn());

    window.dispatchEvent(new WheelEvent('wheel'));

    expect(observers[0].disconnected).toBe(true);
  });

  it('yields to the user on a touch gesture', () => {
    open().follow(vi.fn());

    window.dispatchEvent(new Event('touchmove'));

    expect(observers[0].disconnected).toBe(true);
  });

  it('runs only one window at a time, tearing down the prior on a fresh follow', () => {
    const settleWindow = open();

    settleWindow.follow(vi.fn());
    settleWindow.follow(vi.fn());

    expect(observers).toHaveLength(2);
    expect(observers[0].disconnected).toBe(true);
    expect(observers[1].disconnected).toBe(false);
  });

  it('waits out the given delay before opening', () => {
    vi.useFakeTimers();
    const onSettle = vi.fn();

    open().follow(onSettle, { delay: 300 });

    expect(onSettle).not.toHaveBeenCalled();
    expect(observers).toHaveLength(0);

    vi.advanceTimersByTime(300);

    expect(onSettle).toHaveBeenCalledTimes(1);
    expect(observers[0].observed).toContain(target);
  });

  it('cancels a follow still waiting out its delay on stop()', () => {
    vi.useFakeTimers();
    const onSettle = vi.fn();
    const settleWindow = open();

    settleWindow.follow(onSettle, { delay: 300 });
    settleWindow.stop();
    vi.advanceTimersByTime(300);

    expect(onSettle).not.toHaveBeenCalled();
    expect(observers).toHaveLength(0);
  });

  it('supersedes a follow still waiting out its delay on a fresh follow', () => {
    vi.useFakeTimers();
    const delayed = vi.fn();
    const fresh = vi.fn();
    const settleWindow = open();

    settleWindow.follow(delayed, { delay: 300 });
    settleWindow.follow(fresh);
    vi.advanceTimersByTime(300);

    expect(delayed).not.toHaveBeenCalled();
    expect(fresh).toHaveBeenCalledTimes(1);
  });

  it('stops observing and ignores later gestures after stop()', () => {
    const settleWindow = open();
    settleWindow.follow(vi.fn());

    settleWindow.stop();
    expect(observers[0].disconnected).toBe(true);

    // stop() tears down the gesture listeners too, so a late scroll does nothing.
    expect(() => window.dispatchEvent(new WheelEvent('wheel'))).not.toThrow();
  });
});

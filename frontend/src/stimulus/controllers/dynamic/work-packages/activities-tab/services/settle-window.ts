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

interface SettleWindowOptions {
  target:Element;
  duration:number;
  // Gestures that signal the user has taken over; defaults to wheel and touchmove.
  yieldOn?:readonly string[];
}

interface FollowOptions {
  // Defers the window's opening; the duration only starts counting once it opens.
  delay?:number;
}

// Images reserve their height only once they load, so a single scroll to a freshly
// inserted entry lands short of the settled layout. This re-runs the callback for a
// bounded window as the element grows, and yields the moment the user scrolls.
export default class SettleWindow {
  private observer?:ResizeObserver;
  private timeout?:ReturnType<typeof setTimeout>;
  private delayTimeout?:ReturnType<typeof setTimeout>;
  private abort?:AbortController;

  constructor(private readonly options:SettleWindowOptions) {}

  // Runs onSettle once the delay elapses, then on every resize until the window
  // closes. stop() also cancels a follow still waiting out its delay, so the
  // window's whole lifecycle, opened or pending, ends with it.
  follow(onSettle:() => void, { delay = 0 }:FollowOptions = {}) {
    this.stop();

    if (delay > 0) {
      this.delayTimeout = setTimeout(() => this.open(onSettle), delay);
    } else {
      this.open(onSettle);
    }
  }

  private open(onSettle:() => void) {
    onSettle();

    this.observer = new ResizeObserver(onSettle);
    this.observer.observe(this.options.target);

    this.abort = new AbortController();
    const yieldToUser = () => this.stop();
    for (const gesture of this.options.yieldOn ?? ['wheel', 'touchmove']) {
      window.addEventListener(gesture, yieldToUser, { signal: this.abort.signal, passive: true });
    }

    this.timeout = setTimeout(() => this.stop(), this.options.duration);
  }

  stop() {
    this.observer?.disconnect();
    this.observer = undefined;

    this.abort?.abort();
    this.abort = undefined;

    clearTimeout(this.timeout);
    this.timeout = undefined;

    clearTimeout(this.delayTimeout);
    this.delayTimeout = undefined;
  }
}

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

import { eventToHotkeyString, normalizeSequence, SequenceTracker } from '@github/hotkey';

export type HotkeyHandler = (event:KeyboardEvent) => void;

export interface HotkeyDispatcherOptions {
  /** Single-key hotkeys that also fire on auto-repeated keydowns. */
  repeat?:readonly string[];
}

function isTypingElement(element:Element):boolean {
  return element instanceof HTMLInputElement
    || element instanceof HTMLTextAreaElement
    || element instanceof HTMLSelectElement
    || (element instanceof HTMLElement && element.isContentEditable);
}

function isTypingTarget(event:KeyboardEvent):boolean {
  const target = event.composedPath()[0];
  return target instanceof Element && isTypingElement(target);
}

// With Caps Lock on, a letter arrives in upper case without Shift.
function withoutCapsLock(event:KeyboardEvent):KeyboardEvent {
  if (event.shiftKey || !/^[A-Z]$/.test(event.key)) {
    return event;
  }

  const { ctrlKey, altKey, metaKey } = event;
  return new KeyboardEvent(event.type, { key: event.key.toLowerCase(), ctrlKey, altKey, metaKey });
}

function properPrefixes(sequence:string):string[] {
  const keys = sequence.split(' ');
  return keys.slice(1).map((_key, index) => keys.slice(0, index + 1).join(' '));
}

/**
 * Calls the handler of a hotkey when its key sequence is typed outside of form fields and editors.
 * Hotkeys use the `@github/hotkey` sequence syntax, for example `'g w p'` or `'Shift+?'`.
 */
export class HotkeyDispatcher {
  private readonly tracker = new SequenceTracker();

  private readonly handlers = new Map<string, HotkeyHandler>();

  private readonly prefixes:ReadonlySet<string>;

  private readonly repeatable:ReadonlySet<string>;

  private listener?:AbortController;

  constructor(handlers:Readonly<Record<string, HotkeyHandler>>, options:HotkeyDispatcherOptions = {}) {
    Object.entries(handlers).forEach(([hotkey, handler]) => this.handlers.set(normalizeSequence(hotkey), handler));
    this.prefixes = new Set([...this.handlers.keys()].flatMap(properPrefixes));
    this.repeatable = new Set((options.repeat ?? []).map(normalizeSequence));
  }

  start():void {
    this.listener?.abort();
    this.listener = new AbortController();
    document.addEventListener('keydown', this.onKeydown, { signal: this.listener.signal });
  }

  stop():void {
    this.listener?.abort();
    this.listener = undefined;
    this.tracker.reset();
  }

  private readonly onKeydown = (event:KeyboardEvent):void => {
    if (event.defaultPrevented || event.isComposing || isTypingTarget(event)) {
      this.tracker.reset();
      return;
    }

    const key = withoutCapsLock(event);
    if (event.repeat) {
      this.repeat(key, event);
      return;
    }

    this.tracker.registerKeypress(key);
    const restartable = this.tracker.path.length > 1;
    if (!this.match(event) && restartable) {
      this.tracker.registerKeypress(key);
      this.match(event);
    }
  };

  private repeat(key:KeyboardEvent, event:KeyboardEvent):void {
    if (this.tracker.path.length > 0) return;

    const hotkey = eventToHotkeyString(key);
    if (this.repeatable.has(hotkey)) {
      this.fire(hotkey, event);
    }
  }

  private match(event:KeyboardEvent):boolean {
    const candidate = this.tracker.path.join(' ');

    if (this.handlers.has(candidate)) {
      this.tracker.reset();
      this.fire(candidate, event);
      return true;
    }
    if (this.prefixes.has(candidate)) {
      return true;
    }
    this.tracker.reset();
    return false;
  }

  private fire(sequence:string, event:KeyboardEvent):void {
    event.preventDefault();
    this.handlers.get(sequence)?.(event);
  }
}

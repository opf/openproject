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
import { setOrRemove } from 'core-common/dom-attributes';
import { isFocusableField } from 'core-common/interactive-element-helper';

const KNOWN_SEQUENCES = [
  'g m',
  'g o',
  'g w p',
  'g w i',
  'g a',
  'g c',
  'g n',
  'g e',
  'n w p',
  'd w p',
] as const satisfies readonly string[];

const KNOWN_SEQUENCE_SET:ReadonlySet<string> = new Set(KNOWN_SEQUENCES.map((sequence) => normalizeSequence(sequence)));

const TARGET_SELECTOR = '[data-hotkey], [accesskey], [data-hotkey-yielded-accesskey]';
const YIELDED_ACCESSKEY = 'data-hotkey-yielded-accesskey';

const actions = new Map<string, (el:HTMLElement) => void>();

/**
 * Registers the action that runs when the owner of a hotkey carries `data-hotkey-action="<name>"`.
 *
 * @returns A function that unregisters the action, unless a newer registration has replaced it.
 */
export function registerHotkeyAction(name:string, fn:(el:HTMLElement) => void):() => void {
  actions.set(name, fn);
  return () => {
    if (actions.get(name) === fn) {
      actions.delete(name);
    }
  };
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

function hotkeyAlternatives(element:HTMLElement):string[] {
  return (element.dataset.hotkey ?? '')
    .split(',')
    .map((alternative) => alternative.trim())
    .filter((alternative) => alternative !== '')
    .map((alternative) => normalizeSequence(alternative));
}

function accessKeysOf(element:HTMLElement):string[] {
  const key = element.getAttribute('accesskey') ?? element.getAttribute(YIELDED_ACCESSKEY);
  return key ? [key] : [];
}

function pickOwner(elements:HTMLElement[]):HTMLElement {
  const primary = elements.filter((element) => !element.hasAttribute('data-hotkey-fallback'));
  const candidates = primary.length > 0 ? primary : elements;
  if (candidates.length === 1) return candidates[0];
  return candidates.find((element) => element.checkVisibility()) ?? candidates[0];
}

function groupBy(elements:HTMLElement[], keysOf:(element:HTMLElement) => string[]):Map<string, HTMLElement[]> {
  const groups = new Map<string, HTMLElement[]>();
  elements.forEach((element) => {
    keysOf(element).forEach((key) => {
      const group = groups.get(key);
      if (group) {
        if (!group.includes(element)) group.push(element);
      } else {
        groups.set(key, [element]);
      }
    });
  });
  return groups;
}

function moveAccessKey(element:HTMLElement, key:string, owns:boolean):void {
  setOrRemove(element, 'accesskey', owns ? key : null);
  setOrRemove(element, YIELDED_ACCESSKEY, owns ? null : key);
}

function properPrefixes(sequence:string):string[] {
  const keys = sequence.split(' ');
  return keys.slice(1).map((_key, index) => keys.slice(0, index + 1).join(' '));
}

interface Bindings {
  readonly owners:ReadonlyMap<string, HTMLElement>;
  readonly prefixes:ReadonlySet<string>;
}

const noBindings:Bindings = { owners: new Map(), prefixes: new Set() };

function bindingsFor(elements:HTMLElement[]):Bindings {
  const owners = new Map(Array.from(groupBy(elements, hotkeyAlternatives), ([sequence, group]) => [sequence, pickOwner(group)]));
  const prefixes = new Set([...owners.keys(), ...KNOWN_SEQUENCE_SET].flatMap(properPrefixes));
  return { owners, prefixes };
}

/**
 * Gives every `data-hotkey` sequence and every `accesskey` under the root one owner, preferring the first visible
 * element without `data-hotkey-fallback`; the others keep their access key in `data-hotkey-yielded-accesskey`.
 * A hotkey runs its owner's `data-hotkey-action`, focuses an owner that is a form field, or clicks the owner.
 * Held keys repeat only single-key hotkeys whose owner carries `data-hotkey-repeat`.
 */
export class HotkeyDispatcher {
  private readonly tracker = new SequenceTracker();

  private bindings = noBindings;

  private enabled = false;

  private listener?:AbortController;

  constructor(
    private readonly root:HTMLElement,
    private readonly doc:Document = document,
  ) {}

  setEnabled(enabled:boolean):void {
    this.enabled = enabled;
    if (!enabled) {
      this.tracker.reset();
    }
    this.reconcile();
  }

  start():void {
    this.listener?.abort();
    this.listener = new AbortController();
    this.doc.addEventListener('keydown', this.onKeydown, { signal: this.listener.signal });
  }

  stop():void {
    this.listener?.abort();
    this.listener = undefined;
    this.tracker.reset();
    this.bindings = noBindings;
  }

  reconcile():void {
    const elements = Array.from(this.root.querySelectorAll<HTMLElement>(TARGET_SELECTOR));

    groupBy(elements, accessKeysOf).forEach((group, key) => {
      const owner = pickOwner(group);
      group.forEach((element) => moveAccessKey(element, key, element === owner));
    });

    this.bindings = this.enabled ? bindingsFor(elements) : noBindings;
  }

  private readonly onKeydown = (event:KeyboardEvent):void => {
    if (!this.enabled || event.defaultPrevented || event.isComposing || isTypingTarget(event)) {
      return;
    }
    if (event.repeat) {
      this.repeat(event);
      return;
    }

    this.tracker.registerKeypress(event);
    const restartable = this.tracker.path.length > 1;
    if (!this.match(event) && restartable) {
      this.tracker.registerKeypress(event);
      this.match(event);
    }
  };

  private repeat(event:KeyboardEvent):void {
    if (this.tracker.path.length > 0) return;

    const owner = this.bindings.owners.get(eventToHotkeyString(event));
    if (owner?.hasAttribute('data-hotkey-repeat')) {
      event.preventDefault();
      this.fire(owner);
    }
  }

  private match(event:KeyboardEvent):boolean {
    const candidate = this.tracker.path.join(' ');
    const owner = this.bindings.owners.get(candidate);

    if (owner) {
      event.preventDefault();
      this.tracker.reset();
      this.fire(owner);
      return true;
    }
    if (this.bindings.prefixes.has(candidate)) {
      return true;
    }
    if (KNOWN_SEQUENCE_SET.has(candidate)) {
      event.preventDefault();
      this.tracker.reset();
      return true;
    }
    this.tracker.reset();
    return false;
  }

  private fire(element:HTMLElement):void {
    const actionName = element.dataset.hotkeyAction;
    if (actionName !== undefined) {
      actions.get(actionName)?.(element);
    } else if (isFocusableField(element)) {
      element.focus();
    } else {
      element.click();
    }
  }
}

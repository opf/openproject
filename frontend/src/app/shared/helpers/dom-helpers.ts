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

export const getNodeIndex = (element:Element) => Array.from(element.parentNode!.children).indexOf(element);

/**
 * Toggles the visibility of an HTMLElement using `hidden` property.
 *
 * @note This is the recommended, modern approach. It is also accessible.
 * @param element the element to be toggled.
 * @param value force visibility (optional): `true` to show the element/`false` to hide the element.
 */
export function toggleElement(element:HTMLElement, value?:boolean) {
  if (typeof value === 'undefined') {
    element.hidden = !element.hidden;
  } else {
    element.hidden = !value;
  }
};

export const showElement = (element:HTMLElement) => toggleElement(element, true);

export const hideElement = (element:HTMLElement) => toggleElement(element, false);

/**
 * Toggles the visibility of an Element using a CSS class.
 * Also takes care of setting `aria-hidden` attribute for accessibility.
 *
 * @param element the element to be toggled.
 * @param className the CSS class name to use.
 * @param value force visibility (optional): `true` to show the element/`false` to hide the element.
 */
export function toggleElementByClass(element:Element, className:string, value?:boolean) {
  let hiddenValue:boolean;
  if (typeof value === 'undefined') {
    hiddenValue = element.classList.toggle(className);
  } else {
    hiddenValue = element.classList.toggle(className, !value);
  }
  element.setAttribute('aria-hidden', hiddenValue.toString());
};

/**
 * Toggles the visibility of an HTMLElement using `visibility` style property.
 *
 * @param element the element to be toggled.
 * @param value force visibility (optional): `true` to show the element/`false` to hide the element.
 */
export function toggleElementByVisibility(element:HTMLElement, value?:boolean) {
  value ??= element.style.getPropertyValue('visibility') !== 'visible';
  element.style.setProperty('visibility', value ? 'visible' : 'hidden');
};

/**
 * Mimics jQuery(':visible')
 */
export function isVisible(elem:HTMLElement|null) {
  if (!elem) return false;

  // Check if element is in the DOM
  if (!document.contains(elem)) return false;

  // Check if dimensions are visible
  return !!(
    elem.offsetWidth
    || elem.offsetHeight
    || elem.getClientRects().length
  );
}

export function queryVisible<T extends HTMLElement = HTMLElement>(selector:string, node:Element|Document = document) {
  return Array.from(node.querySelectorAll<T>(selector)).filter(isVisible);
}

const idSalt = Math.random().toString(36).slice(2, 6);
let elementId = 0;

/**
 * Generates a unique and stable ID for use with `HTMLElement`.
 *
 * @param {string} [prefix='el'] - The prefix to use for the generated ID.
 * @returns {string} The newly generated element ID.
 */
export function generateId(prefix = 'el'):string {
  // eslint-disable-next-line no-plusplus
  return `${prefix}-${idSalt}-${elementId++}`;
}

/**
 * Ensures that the given HTMLElement has a unique and stable `id` attribute.
 *
 * - If the element already has an `id`, it is returned unchanged.
 * - Otherwise, a new ID is generated using the provided prefix, a short random
 *   session-specific salt, and an incrementing counter.
 * - This guarantees uniqueness across multiple controller instances or scripts
 *   on the same page, while remaining stable for the element’s lifetime.
 *
 * The generated ID is stable only within the current page session — it will be
 * regenerated if the page is reloaded or the script is re-executed.
 *
 * @example
 * ```ts
 * const div = document.createElement('div');
 * console.log(ensureId(div));       // "el-ab3f-0"
 * console.log(ensureId(div));       // "el-ab3f-0" (same on subsequent calls)
 *
 * const span = document.createElement('span');
 * console.log(ensureId(span, 'fx')); // "fx-ab3f-1"
 * ```
 *
 * @param {HTMLElement} el - The element to ensure has an ID.
 * @param {string} [prefix='el'] - The prefix to use for the generated ID.
 * @returns {string} The existing or newly generated element ID.
 */
export function ensureId(el:HTMLElement, prefix = 'el'):string {
  if (!el.id) {
    el.id = generateId(prefix);
  }
  return el.id;
}

/**
 * Returns a `DOMTokenList`-like facade for an arbitrary attribute.
 *
 * Mimics `element.classList` for space-separated attributes (e.g.
 * `aria-describedby`). It reads and writes the underlying attribute and
 * supports `contains`, `add`, `remove`, `toggle`, `replace`, iteration, and a
 * `.value` accessor.
 *
 * @example
 * ```ts
 * const tokens = attributeTokenList(el, 'aria-describedby');
 * tokens.add('hint-1', 'hint-2'); // sets attribute to "hint-1 hint-2"
 * ```
 *
 * @param element Target element whose attribute holds space-separated tokens.
 * @param attribute Attribute name to manage (e.g. "aria-describedby").
 * @returns A `DOMTokenList`-like object bound to the given attribute.
 */
/* eslint-disable @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-argument, @typescript-eslint/no-unsafe-return, @typescript-eslint/no-explicit-any */
export function attributeTokenList(element:HTMLElement, attribute:string):DOMTokenList {
  const list:any = {};

  const getTokens = ():string[] =>
    (element.getAttribute(attribute) ?? '').trim().split(/\s+/).filter(Boolean);

  const setTokens = (tokens:string[]):void =>
    element.setAttribute(attribute, tokens.join(' '));

  const syncIndexes = ():void => {
    // remove old indexed properties
    const keys = Object.keys(list).filter((key) => /^\d+$/.test(key));
    for (const key of keys) {
      delete list[key];
    }

    const tokens = getTokens();
    tokens.forEach((token, index) => {
      list[index] = token;
    });
    list.length = tokens.length;
  };

  // Initialize indexed properties and length
  syncIndexes();

  list.add = (...tokens:string[]):void => {
    const set = new Set(getTokens());
    tokens.forEach((token) => {
      set.add(token);
    });
    setTokens([...set]);
    syncIndexes();
  };

  list.remove = (...tokens:string[]):void => {
    setTokens(getTokens().filter((token) => !tokens.includes(token)));
    syncIndexes();
  };

  list.toggle = (token:string, force?:boolean):boolean => {
    const exists = list.contains(token);
    const shouldAdd = force ?? !exists;
    if (shouldAdd) {
      list.add(token);
    } else {
      list.remove(token);
    }
    return shouldAdd;
  };

  list.replace = (oldToken:string, newToken:string):boolean => {
    if (!list.contains(oldToken)) return false;
    list.remove(oldToken);
    list.add(newToken);
    return true;
  };

  list.contains = (token:string):boolean => getTokens().includes(token);

  list.item = (index:number):string|null => getTokens()[index] ?? null;

  Object.defineProperty(list, 'value', {
    get: ():string => element.getAttribute(attribute) ?? '',
    set: (value:string):void => {
      setTokens(value.trim().split(/\s+/).filter(Boolean));
      syncIndexes();
    }
  });

  list.toString = ():string => list.value;

  // Iterable support
  list[Symbol.iterator] = function* () {
    yield* getTokens();
  };

  return list as DOMTokenList;
}
/* eslint-enable */

/**
 * Toggles the enabled/disabled state of form elements.
 * For fieldsets, recursively applies to all child elements.
 *
 * @param element the element to toggle
 * @param value force state (optional): `true` to enable/`false` to disable
 * @param toggleHidden optionally toggle element.hidden inversely with disabled state
 */
export function toggleEnabled(element:HTMLElement, value?:boolean, toggleHidden?:boolean) {
  // Handle hidden property if requested
  if (toggleHidden) {
    if (typeof value === 'undefined') {
      element.hidden = !element.hidden;
    } else {
      element.hidden = !value;
    }
  }

  if (
    element instanceof HTMLInputElement ||
    element instanceof HTMLSelectElement ||
    element instanceof HTMLTextAreaElement ||
    element instanceof HTMLButtonElement ||
    element instanceof HTMLFieldSetElement
  ) {
    if (typeof value === 'undefined') {
      element.disabled = !element.disabled;
    } else {
      element.disabled = !value;
    }
  }

  if (element instanceof HTMLFieldSetElement) {
    Array.from(element.elements).forEach((child) => {
      toggleEnabled(child as HTMLElement, !element.disabled, toggleHidden);
    });
  }
}

export const enableElement = (element:HTMLElement) => toggleEnabled(element, true);
export const disableElement = (element:HTMLElement) => toggleEnabled(element, false);

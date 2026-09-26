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

import Mousetrap from 'mousetrap';
import { createEvent, fireEvent } from '@testing-library/dom';
import { clearSelectionOnEscape } from './selection-escape';

describe('clearSelectionOnEscape', () => {
  let fixtures:Element[];

  beforeEach(() => {
    fixtures = [];
  });

  afterEach(() => {
    fixtures.forEach((fixture) => fixture.remove());
  });

  function mount(html:string):HTMLElement {
    const wrapper = document.createElement('div');
    wrapper.innerHTML = html;
    const element = wrapper.firstElementChild as HTMLElement;
    document.body.appendChild(element);
    fixtures.push(element);
    return element;
  }

  function keydown(key = 'Escape'):KeyboardEvent {
    return createEvent.keyDown(document, { key }) as KeyboardEvent;
  }

  function dispatch(target:EventTarget, event:KeyboardEvent, hasState = true) {
    const clear = vi.fn();
    const listener = (received:Event) => clearSelectionOnEscape(received as KeyboardEvent, () => hasState, clear);
    document.addEventListener('keydown', listener);
    try {
      fireEvent(target as Element, event);
    } finally {
      document.removeEventListener('keydown', listener);
    }
    return { event, clear };
  }

  it('clears both roots on one event', () => {
    const first = vi.fn();
    const second = vi.fn();
    const event = keydown();
    fireEvent(document.body, event);
    clearSelectionOnEscape(event, () => true, first);
    clearSelectionOnEscape(event, () => true, second);
    expect(first).toHaveBeenCalledOnce();
    expect(second).toHaveBeenCalledOnce();
    expect(event.defaultPrevented).toBe(true);
  });

  it.each([
    ['body', () => document.body],
    ['button', () => mount('<button>Act</button>')],
    ['link', () => mount('<a href="#">Go</a>')],
    ['focusable row', () => mount('<div><span tabindex="0">Row</span></div>').firstElementChild!],
  ])('clears from a plain %s target and consumes the key', (_name, target) => {
    const { event, clear } = dispatch(target(), keydown());
    expect(clear).toHaveBeenCalledOnce();
    expect(event.defaultPrevented).toBe(true);
  });

  it.each([
    ['input', '<input>'],
    ['textarea', '<textarea></textarea>'],
    ['select', '<select><option>1</option></select>'],
    ['contenteditable', '<span contenteditable="true">Edit</span>'],
    ['role=dialog descendant', '<div role="dialog"><button>Inside</button></div>'],
    ['role=menu descendant', '<div role="menu"><span role="menuitem" tabindex="0">Item</span></div>'],
    ['role=listbox descendant', '<div role="listbox"><span role="option">Opt</span></div>'],
  ])('leaves Escape to a %s', (_name, html) => {
    const owner = mount(html);
    const target = owner.querySelector('button, [role="menuitem"], [role="option"]') ?? owner;
    const { event, clear } = dispatch(target, keydown());
    expect(clear).not.toHaveBeenCalled();
    expect(event.defaultPrevented).toBe(false);
  });

  it('ignores other keys', () => {
    const { event, clear } = dispatch(document.body, keydown('Enter'));
    expect(clear).not.toHaveBeenCalled();
    expect(event.defaultPrevented).toBe(false);
  });

  it('leaves an Escape another owner already consumed alone', () => {
    const event = keydown();
    event.preventDefault();
    const { clear } = dispatch(document.body, event);
    expect(clear).not.toHaveBeenCalled();
  });

  it('does not consume Escape when there is nothing to clear', () => {
    const { event, clear } = dispatch(document.body, keydown(), false);
    expect(clear).not.toHaveBeenCalled();
    expect(event.defaultPrevented).toBe(false);
  });

  describe('open overlays anywhere in the document', () => {
    it.each([
      ['native dialog', '<dialog><button>Inside</button></dialog>',
        (el:HTMLElement) => (el as HTMLDialogElement).show(), (el:HTMLElement) => (el as HTMLDialogElement).close()],
      ['popover', '<div popover="auto">Menu</div>',
        (el:HTMLElement) => el.showPopover(), (el:HTMLElement) => el.hidePopover()],
      ['legacy context menu with a persistent container',
        '<div class="op-context-menu--overlay"><div role="menu"><span role="menuitem">Item</span></div></div>',
        () => undefined, (el:HTMLElement) => el.querySelector('[role="menu"]')!.remove()],
      ['legacy modal overlay', '<div class="spot-modal-overlay" role="dialog"><button>Inside</button></div>',
        (el:HTMLElement) => el.classList.add('spot-modal-overlay_active'),
        (el:HTMLElement) => el.classList.remove('spot-modal-overlay_active')],
      ['Spot drop modal', '<spot-drop-modal class="spot-drop-modal"><div role="note">Picker</div></spot-drop-modal>',
        (el:HTMLElement) => el.classList.add('spot-drop-modal_opened'),
        (el:HTMLElement) => el.classList.remove('spot-drop-modal_opened')],
    ])('defers to an open %s and clears once it is closed', (_name, html, open, close) => {
      const invoker = mount('<button>Open</button>');
      const overlay = mount(html);
      open(overlay);

      const owned = dispatch(invoker, keydown());
      expect(owned.clear).not.toHaveBeenCalled();
      expect(owned.event.defaultPrevented).toBe(false);

      close(overlay);
      expect(overlay.isConnected).toBe(true);
      const free = dispatch(invoker, keydown());
      expect(free.clear).toHaveBeenCalledOnce();
      expect(free.event.defaultPrevented).toBe(true);
    });
  });

  it('skips an Escape a Mousetrap binding registered earlier has prevented', () => {
    const row = mount('<div tabindex="0">Row</div>');
    const reset = vi.fn();
    Mousetrap.bind('esc', (event) => {
      event.preventDefault();
      reset();
    });
    try {
      const event = createEvent.keyDown(row, { key: 'Escape', keyCode: 27, which: 27 }) as KeyboardEvent;
      const { clear } = dispatch(row, event);
      expect(reset).toHaveBeenCalledOnce();
      expect(clear).not.toHaveBeenCalled();
      expect(event.defaultPrevented).toBe(true);
    } finally {
      Mousetrap.unbind('esc');
    }
  });
});

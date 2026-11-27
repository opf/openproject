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

import { createEvent, fireEvent, within } from '@testing-library/dom';
import { HotkeyDispatcher, HotkeyDispatcherOptions, HotkeyHandler } from './hotkey-dispatcher';

type Key = string|KeyboardEventInit;

describe('HotkeyDispatcher', () => {
  let fixture:HTMLElement;
  let dispatchers:HotkeyDispatcher[];

  beforeEach(() => {
    fixture = document.createElement('div');
    document.body.appendChild(fixture);
    dispatchers = [];
  });

  afterEach(() => {
    dispatchers.forEach((dispatcher) => dispatcher.stop());
    fixture.remove();
  });

  function start(handlers:Record<string, HotkeyHandler>, options?:HotkeyDispatcherOptions):HotkeyDispatcher {
    const dispatcher = new HotkeyDispatcher(handlers, options);
    dispatcher.start();
    dispatchers.push(dispatcher);
    return dispatcher;
  }

  function press(...keys:Key[]):boolean[] {
    return keys.map((key) => {
      const init = typeof key === 'string' ? { key } : key;
      return fireEvent.keyDown(document.body, { ...init, composed: true });
    });
  }

  function typingElement(html:string):Element {
    fixture.innerHTML = html;
    return within(fixture).getByTestId('typing');
  }

  describe('firing', () => {
    it('calls the handler of a single-key hotkey and cancels the key', () => {
      const more = vi.fn();
      start({ m: more });

      const [notCancelled] = press('m');

      expect(more).toHaveBeenCalledOnce();
      expect(notCancelled).toBe(false);
    });

    it('calls the handler after a sequence', () => {
      const workPackages = vi.fn();
      start({ 'g w p': workPackages });

      press('g', 'w');
      expect(workPackages).not.toHaveBeenCalled();

      press('p');
      expect(workPackages).toHaveBeenCalledOnce();
    });

    it('matches a hotkey bound with and without Shift', () => {
      const help = vi.fn();
      start({ '?': help, 'Shift+?': help });

      press('?', { key: '?', shiftKey: true });

      expect(help).toHaveBeenCalledTimes(2);
    });

    it('ignores a key pressed with Control, Meta or Alt', () => {
      const handler = vi.fn();
      start({ s: handler, p: handler, m: handler });

      const results = press(
        { key: 's', ctrlKey: true },
        { key: 'p', metaKey: true },
        { key: 'm', altKey: true },
      );

      expect(handler).not.toHaveBeenCalled();
      expect(results).toEqual([true, true, true]);
    });
  });

  describe('Caps Lock', () => {
    it('matches a sequence typed with Caps Lock on', () => {
      const workPackages = vi.fn();
      start({ 'g w p': workPackages });

      press('G', 'W', 'P');

      expect(workPackages).toHaveBeenCalledOnce();
    });

    it('repeats a held key with Caps Lock on', () => {
      const next = vi.fn();
      start({ j: next }, { repeat: ['j'] });

      press('J', { key: 'J', repeat: true });

      expect(next).toHaveBeenCalledTimes(2);
    });

    it('keeps a letter typed with Shift distinct', () => {
      const search = vi.fn();
      start({ s: search });

      press({ key: 'S', shiftKey: true });

      expect(search).not.toHaveBeenCalled();
    });
  });

  describe('typing guard', () => {
    it.each([
      ['text input', '<input data-testid="typing" type="text">'],
      ['checkbox', '<input data-testid="typing" type="checkbox">'],
      ['textarea', '<textarea data-testid="typing"></textarea>'],
      ['select', '<select data-testid="typing"><option>1</option></select>'],
      ['contenteditable', '<div contenteditable="true"><p data-testid="typing">Text</p></div>'],
    ])('does not fire while typing in a %s', (_name, html) => {
      const search = vi.fn();
      start({ s: search });

      const notCancelled = fireEvent.keyDown(typingElement(html), { key: 's', composed: true });

      expect(search).not.toHaveBeenCalled();
      expect(notCancelled).toBe(true);
    });

    it('does not fire from a contenteditable inside an open shadow root', () => {
      const search = vi.fn();
      const editor = document.createElement('div');
      editor.contentEditable = 'true';
      const paragraph = document.createElement('p');
      editor.append(paragraph);
      fixture.attachShadow({ mode: 'open' }).append(editor);
      start({ s: search });

      const notCancelled = fireEvent.keyDown(paragraph, { key: 's', composed: true });

      expect(search).not.toHaveBeenCalled();
      expect(notCancelled).toBe(true);
    });

    it('ignores defaultPrevented and isComposing events', () => {
      const more = vi.fn();
      start({ m: more });

      const prevented = createEvent.keyDown(document.body, { key: 'm', composed: true });
      prevented.preventDefault();
      fireEvent(document.body, prevented);
      press({ key: 'm', isComposing: true });

      expect(more).not.toHaveBeenCalled();
    });
  });

  describe('sequences', () => {
    it('restarts a sequence from the key that broke it', () => {
      const more = vi.fn();
      const myPage = vi.fn();
      start({ m: more, 'g w p': myPage });

      press('g', 'm');

      expect(more).toHaveBeenCalledOnce();
      expect(myPage).not.toHaveBeenCalled();
    });

    it('forgets a half-typed sequence when a key is typed in a form field', () => {
      const more = vi.fn();
      const myPage = vi.fn();
      start({ m: more, 'g m': myPage });

      press('g');
      fireEvent.keyDown(typingElement('<input data-testid="typing" type="text">'), { key: 'x', composed: true });
      press('m');

      expect(more).toHaveBeenCalledOnce();
      expect(myPage).not.toHaveBeenCalled();
    });

    it('does not cancel prefix keys', () => {
      start({ 'g m': vi.fn() });

      const [notCancelled] = press('g');

      expect(notCancelled).toBe(true);
    });
  });

  describe('key repeat', () => {
    it('ignores auto-repeated keydowns', () => {
      const more = vi.fn();
      start({ m: more });

      press('m', { key: 'm', repeat: true });

      expect(more).toHaveBeenCalledOnce();
    });

    it('fires auto-repeated keydowns for keys listed in options.repeat', () => {
      const next = vi.fn();
      start({ j: next }, { repeat: ['j'] });

      press('j', { key: 'j', repeat: true });

      expect(next).toHaveBeenCalledTimes(2);
    });

    it('ignores auto-repeated keydowns within a sequence', () => {
      const next = vi.fn();
      const jump = vi.fn();
      start({ j: next, 'g j': jump }, { repeat: ['j'] });

      press('g', { key: 'j', repeat: true });

      expect(next).not.toHaveBeenCalled();
      expect(jump).not.toHaveBeenCalled();
    });
  });

  describe('stop', () => {
    it('resets a half-typed sequence and removes the listener', () => {
      const myPage = vi.fn();
      const dispatcher = start({ 'g m': myPage });

      press('g');
      dispatcher.stop();
      press('m');
      dispatcher.start();
      press('m');

      expect(myPage).not.toHaveBeenCalled();
    });
  });
});

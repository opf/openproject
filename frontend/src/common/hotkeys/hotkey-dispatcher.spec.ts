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
import { HotkeyDispatcher, registerHotkeyAction } from './hotkey-dispatcher';

type Key = string|{ key:string, shiftKey?:boolean, repeat?:boolean };

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

  function start({ enabled = true } = {}):HotkeyDispatcher {
    const dispatcher = new HotkeyDispatcher(fixture);
    dispatcher.setEnabled(enabled);
    dispatcher.start();
    dispatchers.push(dispatcher);
    return dispatcher;
  }

  function mount(html:string):void {
    fixture.innerHTML = html;
  }

  function element(testId:string):HTMLElement {
    return within(fixture).getByTestId(testId);
  }

  function clicks(testId:string) {
    const spy = vi.fn();
    element(testId).addEventListener('click', (event) => {
      event.preventDefault();
      spy();
    });
    return spy;
  }

  function press(...keys:Key[]):void {
    keys.forEach((key) => {
      const init = typeof key === 'string' ? { key } : key;
      fireEvent.keyDown(document.body, { ...init, composed: true });
    });
  }

  describe('firing', () => {
    it('clicks the owner of a single-key hotkey', () => {
      mount('<button data-testid="more" data-hotkey="m">More</button>');
      const clicked = clicks('more');
      start();

      press('m');

      expect(clicked).toHaveBeenCalledOnce();
    });

    it('clicks after a sequence', () => {
      mount('<button data-testid="wp" data-hotkey="g w p">Work packages</button>');
      const clicked = clicks('wp');
      start();

      press('g', 'w');
      expect(clicked).not.toHaveBeenCalled();

      press('p');
      expect(clicked).toHaveBeenCalledOnce();
    });

    it('matches Shift+? and ?', () => {
      mount('<a data-testid="help" href="#" data-hotkey="?,Shift+?">Shortcuts</a>');
      const clicked = clicks('help');
      start();

      press('?', { key: '?', shiftKey: true });

      expect(clicked).toHaveBeenCalledTimes(2);
    });

    it('focuses a form field owner instead of clicking it', () => {
      mount('<input data-testid="search" type="search" data-hotkey="s">');
      const clicked = clicks('search');
      start();

      press('s');

      expect(clicked).not.toHaveBeenCalled();
      expect(document.activeElement).toBe(element('search'));
    });
  });

  describe('typing guard', () => {
    it.each([
      ['text input', '<input data-testid="typing" type="text">'],
      ['checkbox', '<input data-testid="typing" type="checkbox">'],
      ['radio', '<input data-testid="typing" type="radio">'],
      ['textarea', '<textarea data-testid="typing"></textarea>'],
      ['select', '<select data-testid="typing"><option>1</option></select>'],
      ['contenteditable', '<div contenteditable="true"><p data-testid="typing">Text</p></div>'],
    ])('does not fire from a %s', (_name, html) => {
      mount(`<button data-testid="search" data-hotkey="s">Search</button>${html}`);
      const clicked = clicks('search');
      start();

      const notCancelled = fireEvent.keyDown(element('typing'), { key: 's', composed: true });

      expect(clicked).not.toHaveBeenCalled();
      expect(notCancelled).toBe(true);
    });

    it('does not fire from a contenteditable inside an open shadow root', () => {
      mount('<button data-testid="search" data-hotkey="s">Search</button><div data-testid="host"></div>');
      const shadow = element('host').attachShadow({ mode: 'open' });
      shadow.innerHTML = '<div contenteditable="true"><p>Text</p></div>';
      const clicked = clicks('search');
      start();

      const notCancelled = fireEvent.keyDown(shadow.querySelector('p')!, { key: 's', composed: true });

      expect(clicked).not.toHaveBeenCalled();
      expect(notCancelled).toBe(true);
    });

    it('ignores defaultPrevented and isComposing events', () => {
      mount('<button data-testid="more" data-hotkey="m">More</button>');
      const clicked = clicks('more');
      start();

      const prevented = createEvent.keyDown(document.body, { key: 'm', composed: true });
      prevented.preventDefault();
      fireEvent(document.body, prevented);
      fireEvent.keyDown(document.body, { key: 'm', isComposing: true, composed: true });

      expect(clicked).not.toHaveBeenCalled();
    });
  });

  describe('ownership', () => {
    it('picks the first visible non-fallback owner', () => {
      mount(`
        <a data-testid="hidden" href="#" data-hotkey="g e" accesskey="3" style="display:none">Edit</a>
        <a data-testid="visible" href="#" data-hotkey="g e" accesskey="3">Edit</a>
      `);
      const hiddenClicked = clicks('hidden');
      const visibleClicked = clicks('visible');
      start();

      press('g', 'e');

      expect(visibleClicked).toHaveBeenCalledOnce();
      expect(hiddenClicked).not.toHaveBeenCalled();
      expect(element('visible').getAttribute('accesskey')).toBe('3');
      expect(element('hidden').hasAttribute('accesskey')).toBe(false);
      expect(element('hidden').dataset.hotkeyYieldedAccesskey).toBe('3');
    });

    it('fallback yields hotkey and accesskey while an owner is connected', () => {
      mount(`
        <a data-testid="fallback" href="#" data-hotkey="n w p" data-hotkey-fallback accesskey="2">New</a>
        <button data-testid="owner" data-hotkey="n w p" accesskey="2">Create</button>
      `);
      const fallbackClicked = clicks('fallback');
      const ownerClicked = clicks('owner');
      const dispatcher = start();

      press('n', 'w', 'p');

      expect(ownerClicked).toHaveBeenCalledOnce();
      expect(fallbackClicked).not.toHaveBeenCalled();
      expect(element('fallback').hasAttribute('accesskey')).toBe(false);

      element('owner').remove();
      dispatcher.reconcile();
      press('n', 'w', 'p');

      expect(fallbackClicked).toHaveBeenCalledOnce();
      expect(element('fallback').getAttribute('accesskey')).toBe('2');
      expect(element('fallback').hasAttribute('data-hotkey-yielded-accesskey')).toBe(false);
    });

    it.each([
      ['with the yield marker kept', (_el:HTMLElement) => undefined],
      ['with the yield marker removed', (el:HTMLElement) => el.removeAttribute('data-hotkey-yielded-accesskey')],
    ])('restores ownership after an attribute-only change %s', (_name, morphMarker) => {
      mount(`
        <button data-testid="list-more" data-hotkey="m" data-hotkey-fallback accesskey="7">More</button>
        <button data-testid="details-more" data-hotkey="m" accesskey="7">More</button>
      `);
      const dispatcher = start();
      const fallback = element('list-more');
      expect(fallback.hasAttribute('accesskey')).toBe(false);

      fallback.setAttribute('accesskey', '7');
      morphMarker(fallback);
      dispatcher.reconcile();

      expect(Array.from(fixture.querySelectorAll('[accesskey="7"]'))).toEqual([element('details-more')]);
      expect(fallback.dataset.hotkeyYieldedAccesskey).toBe('7');
    });

    it('applies the owner rule to access keys without a hotkey', () => {
      mount(`
        <button data-testid="first" accesskey="3">Edit</button>
        <button data-testid="second" accesskey="3">Edit</button>
      `);
      start();

      expect(Array.from(fixture.querySelectorAll('[accesskey="3"]'))).toEqual([element('first')]);
    });

    it('follows a changed data-hotkey value', () => {
      mount('<button data-testid="target" data-hotkey="m">Target</button>');
      const clicked = clicks('target');
      const dispatcher = start();

      element('target').dataset.hotkey = 'x';
      dispatcher.reconcile();
      press('m');
      expect(clicked).not.toHaveBeenCalled();

      press('x');
      expect(clicked).toHaveBeenCalledOnce();
    });
  });

  describe('sequences', () => {
    it('swallows a known sequence with no owner', () => {
      mount('<button data-testid="project" data-hotkey="p">Projects</button>');
      const clicked = clicks('project');
      start();

      press('n', 'w', 'p');
      expect(clicked).not.toHaveBeenCalled();

      press('p');
      expect(clicked).toHaveBeenCalledOnce();
    });

    it('restarts a sequence from the key that broke it', () => {
      mount(`
        <button data-testid="wp" data-hotkey="g w p">Work packages</button>
        <button data-testid="project" data-hotkey="p">Projects</button>
      `);
      const wpClicked = clicks('wp');
      const projectClicked = clicks('project');
      start();

      press('g', 'g', 'w', 'p');

      expect(wpClicked).toHaveBeenCalledOnce();
      expect(projectClicked).not.toHaveBeenCalled();
    });

    it('fires a single-key owner that breaks a prefix', () => {
      mount(`
        <button data-testid="my-page" data-hotkey="g m">My page</button>
        <button data-testid="search" data-hotkey="s">Search</button>
      `);
      const searchClicked = clicks('search');
      start();

      press('g', 's');

      expect(searchClicked).toHaveBeenCalledOnce();
    });

    it('swallows a restarted known sequence with no owner', () => {
      mount('<button data-testid="project" data-hotkey="p">Projects</button>');
      const clicked = clicks('project');
      start();

      press('n', 'n', 'w', 'p');

      expect(clicked).not.toHaveBeenCalled();
    });

    it('does not cancel prefix keys', () => {
      mount('<button data-testid="wp" data-hotkey="g w p">Work packages</button>');
      clicks('wp');
      start();

      const notCancelled = ['g', 'w'].map((key) => fireEvent.keyDown(document.body, { key, composed: true }));
      const lastNotCancelled = fireEvent.keyDown(document.body, { key: 'p', composed: true });

      expect(notCancelled).toEqual([true, true]);
      expect(lastNotCancelled).toBe(false);
    });

    it('cancels the last key of a known sequence with no owner', () => {
      mount('');
      start();

      const notCancelled = ['n', 'w', 'p'].map((key) => fireEvent.keyDown(document.body, { key, composed: true }));

      expect(notCancelled).toEqual([true, true, false]);
    });
  });

  describe('key repeat', () => {
    it('ignores auto-repeated keydowns', () => {
      mount('<button data-testid="more" data-hotkey="m">More</button>');
      const clicked = clicks('more');
      start();

      press('m', { key: 'm', repeat: true }, { key: 'm', repeat: true });

      expect(clicked).toHaveBeenCalledOnce();
    });

    it('fires auto-repeated keydowns for a data-hotkey-repeat owner', () => {
      mount('<button data-testid="next" data-hotkey="j" data-hotkey-repeat>Next</button>');
      const clicked = clicks('next');
      start();

      press('j', { key: 'j', repeat: true }, { key: 'j', repeat: true });

      expect(clicked).toHaveBeenCalledTimes(3);
    });

    it('ignores auto-repeated keydowns within a sequence', () => {
      mount(`
        <button data-testid="wp" data-hotkey="g w p" data-hotkey-repeat>Work packages</button>
        <button data-testid="next" data-hotkey="j" data-hotkey-repeat>Next</button>
      `);
      const wpClicked = clicks('wp');
      const nextClicked = clicks('next');
      start();

      press('g', { key: 'g', repeat: true }, 'w', 'p', { key: 'p', repeat: true });
      expect(wpClicked).toHaveBeenCalledOnce();

      press('g', { key: 'j', repeat: true });
      expect(nextClicked).not.toHaveBeenCalled();
    });
  });

  describe('actions and enabled state', () => {
    it('runs a registered data-hotkey-action instead of clicking', () => {
      mount('<button data-testid="next" data-hotkey="j" data-hotkey-action="spec-next">Next</button>');
      const clicked = clicks('next');
      const action = vi.fn();
      const unregister = registerHotkeyAction('spec-next', action);
      start();

      try {
        press('j');
        expect(action).toHaveBeenCalledExactlyOnceWith(element('next'));
        expect(clicked).not.toHaveBeenCalled();
      } finally {
        unregister();
      }

      press('j');
      expect(action).toHaveBeenCalledOnce();
    });

    it('keeps a newer registration when a stale unregister runs', () => {
      mount('<button data-hotkey="s" data-hotkey-action="spec-search">Search</button>');
      const stale = vi.fn();
      const current = vi.fn();
      const unregisterStale = registerHotkeyAction('spec-search', stale);
      const unregisterCurrent = registerHotkeyAction('spec-search', current);
      start();

      try {
        unregisterStale();
        press('s');
        expect(current).toHaveBeenCalledOnce();
        expect(stale).not.toHaveBeenCalled();
      } finally {
        unregisterCurrent();
      }
    });

    it('stops dispatching when enabled is false and resumes when true', () => {
      mount('<button data-testid="more" data-hotkey="m">More</button>');
      const moreClicked = clicks('more');
      const dispatcher = start();

      dispatcher.setEnabled(false);
      fixture.insertAdjacentHTML('beforeend', '<button data-testid="late" data-hotkey="x">Late</button>');
      const lateClicked = clicks('late');
      dispatcher.reconcile();
      press('m', 'x');

      expect(moreClicked).not.toHaveBeenCalled();
      expect(lateClicked).not.toHaveBeenCalled();

      dispatcher.setEnabled(true);
      press('m', 'x');

      expect(moreClicked).toHaveBeenCalledOnce();
      expect(lateClicked).toHaveBeenCalledOnce();
    });

    it('keeps the access key owner rule while disabled', () => {
      mount(`
        <button data-testid="first" accesskey="7">More</button>
        <button data-testid="second" accesskey="7">More</button>
      `);
      start({ enabled: false });

      expect(Array.from(fixture.querySelectorAll('[accesskey="7"]'))).toEqual([element('first')]);
    });

    it('stop resets a half-typed sequence', () => {
      mount(`
        <button data-testid="my-page" data-hotkey="g m">My page</button>
        <button data-testid="more" data-hotkey="m">More</button>
      `);
      const myPageClicked = clicks('my-page');
      const moreClicked = clicks('more');
      const first = start();

      press('g');
      first.stop();
      first.setEnabled(true);
      first.start();
      press('m');

      expect(moreClicked).toHaveBeenCalledOnce();
      expect(myPageClicked).not.toHaveBeenCalled();
    });
  });
});

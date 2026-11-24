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

import { Application } from '@hotwired/stimulus';
import { fireEvent, within } from '@testing-library/dom';
import { nextTask } from 'core-common/testing/timing';
import HotkeysController from './hotkeys.controller';

describe('HotkeysController', () => {
  let application:Application;
  let fixture:HTMLElement;

  beforeEach(async () => {
    fixture = document.createElement('div');
    fixture.innerHTML = `
      <div data-testid="body" data-controller="hotkeys" data-hotkeys-enabled-value="true">
        <button data-testid="more" data-hotkey="m">More</button>
      </div>
    `;
    document.body.appendChild(fixture);

    application = Application.start(fixture);
    application.register('hotkeys', HotkeysController);
    await nextTask();
  });

  afterEach(async () => {
    vi.restoreAllMocks();
    fixture.replaceChildren();
    await nextTask();
    application.stop();
    fixture.remove();
  });

  function element(testId:string):HTMLElement {
    return within(fixture).getByTestId(testId);
  }

  function clicks(testId:string) {
    const spy = vi.fn();
    element(testId).addEventListener('click', spy);
    return spy;
  }

  function press(key:string):void {
    fireEvent.keyDown(document.body, { key, composed: true });
  }

  it('reconciles a target added after connect', async () => {
    element('body').insertAdjacentHTML('beforeend', '<button data-testid="late" data-hotkey="x">Late</button>');
    const clicked = clicks('late');
    await nextTask();

    press('x');

    expect(clicked).toHaveBeenCalledOnce();
  });

  it('fires a target added just before the key press', async () => {
    element('body').insertAdjacentHTML('beforeend', '<button data-testid="late" data-hotkey="x">Late</button>');
    const clicked = clicks('late');
    await Promise.resolve();

    press('x');

    expect(clicked).toHaveBeenCalledOnce();
  });

  it('reconciles when the owner of a hotkey is removed', async () => {
    element('body').insertAdjacentHTML('beforeend', `
      <div data-testid="row"><button data-hotkey="y">Row</button></div>
      <button data-testid="fallback" data-hotkey="y" data-hotkey-fallback>Fallback</button>
    `);
    const clicked = clicks('fallback');
    await nextTask();

    element('row').remove();
    await Promise.resolve();
    press('y');

    expect(clicked).toHaveBeenCalledOnce();
  });

  it('hands a removed owner\'s access key to the fallback at once', async () => {
    element('body').dataset.hotkeysEnabledValue = 'false';
    element('body').insertAdjacentHTML('beforeend', `
      <div data-testid="toolbar"><button accesskey="2">Create</button></div>
      <a data-testid="fallback" href="#" accesskey="2" data-hotkey-fallback>New work package</a>
    `);
    await nextTask();
    expect(element('fallback')).not.toHaveAttribute('accesskey');

    element('toolbar').remove();
    await Promise.resolve();

    expect(element('fallback')).toHaveAttribute('accesskey', '2');
  });

  it('stops on disconnect', async () => {
    const clicked = clicks('more');
    element('body').removeAttribute('data-controller');
    await nextTask();

    press('m');

    expect(clicked).not.toHaveBeenCalled();
  });

  it('fires each key once across reconnects on the same element', async () => {
    const host = element('body');

    for (let cycle = 1; cycle <= 3; cycle += 1) {
      host.removeAttribute('data-controller');
      await nextTask();
      host.setAttribute('data-controller', 'hotkeys');
      await nextTask();

      host.insertAdjacentHTML('beforeend', `<button data-testid="late-${cycle}" data-hotkey="${cycle}">Late</button>`);
      const clicked = clicks(`late-${cycle}`);
      await nextTask();
      press(String(cycle));

      expect(clicked).toHaveBeenCalledOnce();
    }
  });

  it('follows data-hotkeys-enabled-value changes on the same element', async () => {
    const clicked = clicks('more');

    element('body').dataset.hotkeysEnabledValue = 'false';
    await nextTask();
    press('m');
    expect(clicked).not.toHaveBeenCalled();

    element('body').dataset.hotkeysEnabledValue = 'true';
    await nextTask();
    press('m');
    expect(clicked).toHaveBeenCalledOnce();
  });
});

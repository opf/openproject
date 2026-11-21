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
import { fireEvent, waitFor, within } from '@testing-library/dom';
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

  it('reconciles after the element resizes', async () => {
    element('body').insertAdjacentHTML('beforeend', `
      <button data-testid="wide" accesskey="9">Wide</button>
      <button data-testid="narrow" accesskey="9" style="display:none">Narrow</button>
    `);
    await waitFor(() => expect(element('narrow')).not.toHaveAttribute('accesskey'));

    element('wide').style.display = 'none';
    element('narrow').style.display = '';
    element('body').style.width = '200px';

    await waitFor(() => expect(element('narrow')).toHaveAttribute('accesskey', '9'));
    expect(element('wide')).not.toHaveAttribute('accesskey');
  });

  it('stops on disconnect', async () => {
    const clicked = clicks('more');
    element('body').removeAttribute('data-controller');
    await nextTask();

    press('m');

    expect(clicked).not.toHaveBeenCalled();
  });

  it('keeps one mutation and one resize observer across reconnects on the same element', async () => {
    const host = element('body');
    const observeMutations = vi.spyOn(MutationObserver.prototype, 'observe');
    const observeResizes = vi.spyOn(ResizeObserver.prototype, 'observe');

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

    const hotkeyMutationObservers = observeMutations.mock.calls
      .map(([target, options], index) => ({ target, options, observer: observeMutations.mock.contexts[index] }))
      .filter(({ target, options }) => target === host && options?.attributeFilter?.includes('data-hotkey'))
      .map(({ observer }) => observer);
    const hostResizeObservers = observeResizes.mock.calls
      .map(([target], index) => ({ target, observer: observeResizes.mock.contexts[index] }))
      .filter(({ target }) => target === host)
      .map(({ observer }) => observer);

    expect(new Set(hotkeyMutationObservers).size).toBe(1);
    expect(new Set(hostResizeObservers).size).toBe(1);
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

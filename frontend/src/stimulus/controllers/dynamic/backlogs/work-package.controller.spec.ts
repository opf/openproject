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

import { Application } from '@hotwired/stimulus';

import type WorkPackageControllerType from './work-package.controller';

interface WorkPackageNavigation {
  openSplitPane(this:void):void;
  openFullPane(this:void):void;
}

describe('Backlogs work package controller', () => {
  const nextFrame = () => new Promise<void>((resolve) => requestAnimationFrame(() => resolve()));

  let application:Application;
  let fixture:HTMLElement;
  let WorkPackageController:typeof WorkPackageControllerType;
  let navigation:WorkPackageNavigation;

  beforeAll(async () => {
    ({ default: WorkPackageController } = await import('./work-package.controller'));
  });

  beforeEach(() => {
    // Stub the navigation so activating a card neither hits Turbo nor leaves
    // the test page; the spies double as activation assertions.
    navigation = WorkPackageController.prototype as unknown as WorkPackageNavigation;
    vi.spyOn(navigation, 'openSplitPane').mockReturnValue(undefined);
    vi.spyOn(navigation, 'openFullPane').mockReturnValue(undefined);

    fixture = document.createElement('div');
    document.body.appendChild(fixture);

    application = Application.start();
    application.register('backlogs--work-package', WorkPackageController);
  });

  afterEach(async () => {
    fixture.remove();
    await nextFrame();
    application.stop();
    vi.restoreAllMocks();
  });

  function renderWorkPackage() {
    fixture.innerHTML = `
      <article
        data-controller="backlogs--work-package"
        data-backlogs--work-package-id-value="42"
        data-backlogs--work-package-display-id-value="SP-42"
        data-backlogs--work-package-split-url-value="/projects/demo/backlogs/details/SP-42"
        data-backlogs--work-package-full-url-value="/work_packages/42"
        tabindex="0"
      >
        Work package
      </article>
    `;

    return fixture.querySelector<HTMLElement>('[data-controller="backlogs--work-package"]')!;
  }

  function keydown(target:HTMLElement, key:string, init:KeyboardEventInit = {}) {
    const event = new KeyboardEvent('keydown', {
      key, bubbles: true, cancelable: true, ...init,
    });
    target.dispatchEvent(event);
    return event;
  }

  it('lets Space scroll the page natively without hijacking it', async () => {
    const workPackage = renderWorkPackage();

    await nextFrame();
    const event = keydown(workPackage, ' ');

    expect(event.defaultPrevented).toBe(false);
    expect(navigation.openSplitPane).not.toHaveBeenCalled();
    expect(navigation.openFullPane).not.toHaveBeenCalled();
  });

  it('opens the split pane when Enter is pressed', async () => {
    const workPackage = renderWorkPackage();

    await nextFrame();
    const event = keydown(workPackage, 'Enter');

    expect(event.defaultPrevented).toBe(true);
    expect(navigation.openSplitPane).toHaveBeenCalledTimes(1);
    expect(navigation.openFullPane).not.toHaveBeenCalled();
  });

  it('opens the full pane when Shift+Enter is pressed', async () => {
    const workPackage = renderWorkPackage();

    await nextFrame();
    const event = keydown(workPackage, 'Enter', { shiftKey: true });

    expect(event.defaultPrevented).toBe(true);
    expect(navigation.openFullPane).toHaveBeenCalledTimes(1);
    expect(navigation.openSplitPane).not.toHaveBeenCalled();
  });

  it('ignores Space inside a form field so typing and scrolling stay native', async () => {
    const workPackage = renderWorkPackage();
    const input = document.createElement('input');
    workPackage.appendChild(input);

    await nextFrame();
    const event = keydown(input, ' ');

    expect(event.defaultPrevented).toBe(false);
    expect(navigation.openSplitPane).not.toHaveBeenCalled();
    expect(navigation.openFullPane).not.toHaveBeenCalled();
  });

  it('marks the card as selected immediately on click, before the pane opens', async () => {
    const workPackage = renderWorkPackage();

    await nextFrame();
    workPackage.dispatchEvent(new MouseEvent('click', { bubbles: true }));

    expect(workPackage.hasAttribute('data-selected')).toBe(true);
    expect(workPackage.hasAttribute('aria-current')).toBe(false);
    expect(navigation.openSplitPane).not.toHaveBeenCalled();
  });

  it('cancels a pending click activation when the card disconnects', async () => {
    const workPackage = renderWorkPackage();

    await nextFrame();
    vi.useFakeTimers();

    try {
      workPackage.dispatchEvent(new MouseEvent('click', { bubbles: true }));
      fixture.remove();
      await Promise.resolve();
      await Promise.resolve();
      vi.advanceTimersByTime(250);

      expect(navigation.openSplitPane).not.toHaveBeenCalled();
    } finally {
      vi.useRealTimers();
    }
  });

  it('marks the card as selected when Enter opens the split pane', async () => {
    const workPackage = renderWorkPackage();

    await nextFrame();
    keydown(workPackage, 'Enter');

    expect(workPackage.hasAttribute('data-selected')).toBe(true);
    expect(navigation.openSplitPane).toHaveBeenCalledTimes(1);
  });

  it('clears the selection of other work packages when a card is selected', async () => {
    const workPackage = renderWorkPackage();
    const other = document.createElement('article');
    other.setAttribute('data-controller', 'backlogs--work-package');
    fixture.appendChild(other);

    await nextFrame();
    other.setAttribute('data-selected', '');
    workPackage.dispatchEvent(new MouseEvent('click', { bubbles: true }));

    expect(other.hasAttribute('data-selected')).toBe(false);
    expect(workPackage.hasAttribute('data-selected')).toBe(true);
  });

  it('syncs selection and aria-current from the visited URL', async () => {
    const workPackage = renderWorkPackage();

    await nextFrame();
    document.dispatchEvent(new CustomEvent('turbo:visit', {
      detail: { url: '/projects/demo/backlogs/details/SP-42' },
    }));

    expect(workPackage.getAttribute('aria-current')).toBe('true');
    expect(workPackage.hasAttribute('data-selected')).toBe(true);

    document.dispatchEvent(new CustomEvent('turbo:visit', {
      detail: { url: '/projects/demo/backlogs' },
    }));

    expect(workPackage.hasAttribute('aria-current')).toBe(false);
    expect(workPackage.hasAttribute('data-selected')).toBe(false);
  });
});

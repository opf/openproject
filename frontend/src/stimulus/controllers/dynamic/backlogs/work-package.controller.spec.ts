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

  // The card is wrapped in its row, matching production: `data-batch-selected`
  // is written on the row (the <li>), never on the card itself (see
  // sortable-lists/selection.ts). This controller only ever touches the card
  // (`this.element`), so wrapping it here is what makes "leaves batch
  // membership alone" below a meaningful assertion instead of one that would
  // pass unchanged even if the two elements were confused.
  function renderWorkPackage() {
    fixture.innerHTML = `
      <li>
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
      </li>
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
    expect(workPackage.hasAttribute('aria-current')).toBe(false);
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

  it('does not mark a card as current merely because it was clicked', async () => {
    const workPackage = renderWorkPackage();

    await nextFrame();
    workPackage.dispatchEvent(new MouseEvent('click', { bubbles: true }));

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

  // The pressed state is visual only — data-activating, never ARIA — so
  // every user gets synchronous feedback regardless of batch selection
  // being enabled for them.
  describe('activation feedback', () => {
    it('shows pressed feedback synchronously on click, before any navigation', async () => {
      const workPackage = renderWorkPackage();

      await nextFrame();
      workPackage.dispatchEvent(new MouseEvent('click', { bubbles: true }));

      expect(workPackage.hasAttribute('data-activating')).toBe(true);
      expect(workPackage.hasAttribute('aria-current')).toBe(false);
      expect(navigation.openSplitPane).not.toHaveBeenCalled();
    });

    it('shows pressed feedback synchronously on Enter', async () => {
      const workPackage = renderWorkPackage();

      await nextFrame();
      keydown(workPackage, 'Enter');

      expect(workPackage.hasAttribute('data-activating')).toBe(true);
      expect(workPackage.hasAttribute('aria-current')).toBe(false);
    });

    it('clears pressed feedback when the visit lands on the card', async () => {
      const workPackage = renderWorkPackage();

      await nextFrame();
      workPackage.dispatchEvent(new MouseEvent('click', { bubbles: true }));
      document.dispatchEvent(new CustomEvent('turbo:visit', {
        detail: { url: '/projects/demo/backlogs/details/SP-42' },
      }));

      expect(workPackage.hasAttribute('data-activating')).toBe(false);
      expect(workPackage.getAttribute('aria-current')).toBe('true');
    });

    it('clears pressed feedback when the visit lands elsewhere', async () => {
      const workPackage = renderWorkPackage();

      await nextFrame();
      workPackage.dispatchEvent(new MouseEvent('click', { bubbles: true }));
      document.dispatchEvent(new CustomEvent('turbo:visit', {
        detail: { url: '/projects/demo/backlogs' },
      }));

      expect(workPackage.hasAttribute('data-activating')).toBe(false);
      expect(workPackage.hasAttribute('aria-current')).toBe(false);
    });

    it('clears pressed feedback when a double-click cancels the pending click', async () => {
      const workPackage = renderWorkPackage();

      await nextFrame();
      workPackage.dispatchEvent(new MouseEvent('click', { bubbles: true }));
      workPackage.dispatchEvent(new MouseEvent('dblclick', { bubbles: true }));

      expect(workPackage.hasAttribute('data-activating')).toBe(false);
      expect(navigation.openFullPane).toHaveBeenCalledTimes(1);
    });

    it('clears pressed feedback when the card disconnects', async () => {
      const workPackage = renderWorkPackage();

      await nextFrame();
      workPackage.dispatchEvent(new MouseEvent('click', { bubbles: true }));
      fixture.remove();
      await nextFrame();

      expect(workPackage.hasAttribute('data-activating')).toBe(false);
    });
  });

  it('marks the card as current when the URL points at it', async () => {
    const workPackage = renderWorkPackage();

    await nextFrame();
    document.dispatchEvent(new CustomEvent('turbo:visit', {
      detail: { url: '/projects/demo/backlogs/details/SP-42' },
    }));

    expect(workPackage.getAttribute('aria-current')).toBe('true');
  });

  it('unmarks the card as current once the URL moves elsewhere', async () => {
    const workPackage = renderWorkPackage();

    await nextFrame();
    document.dispatchEvent(new CustomEvent('turbo:visit', {
      detail: { url: '/projects/demo/backlogs/details/SP-42' },
    }));
    document.dispatchEvent(new CustomEvent('turbo:visit', {
      detail: { url: '/projects/demo/backlogs' },
    }));

    expect(workPackage.hasAttribute('aria-current')).toBe(false);
  });

  it('leaves batch membership alone when the URL changes', async () => {
    const workPackage = renderWorkPackage();
    const row = workPackage.parentElement!;

    await nextFrame();
    row.setAttribute('data-batch-selected', '');

    document.dispatchEvent(new CustomEvent('turbo:visit', {
      detail: { url: '/projects/demo/backlogs/details/SP-42' },
    }));
    expect(row.hasAttribute('data-batch-selected')).toBe(true);

    document.dispatchEvent(new CustomEvent('turbo:visit', {
      detail: { url: '/projects/demo/backlogs' },
    }));
    expect(row.hasAttribute('data-batch-selected')).toBe(true);
  });
});

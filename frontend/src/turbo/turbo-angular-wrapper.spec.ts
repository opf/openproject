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

import {
  afterEach, beforeEach, describe, expect, it, vi,
} from 'vitest';
import type { ApplicationRef, ComponentRef } from '@angular/core';
import type { OpenProjectPluginContext } from 'core-app/features/plugins/plugin-context';
import { addTurboAngularWrapper } from './turbo-angular-wrapper';

describe('addTurboAngularWrapper — Angular re-bootstrap on Turbo navigation', () => {
  let controller:AbortController;
  let target:EventTarget;

  // The destroy-and-rebuild contract operates on the plugin context's appRef.
  // We drive it with fakes so the spec never touches `window.OpenProject` or a
  // real Angular application.
  function makeAppRef(components:ComponentRef<unknown>[]):ApplicationRef {
    return { components, detachView: vi.fn() } as unknown as ApplicationRef;
  }

  // The handler awaits the plugin-context promise; yield a macrotask so the
  // whole microtask queue drains (any chain depth) before assertions run.
  async function flush():Promise<void> {
    await new Promise((resolve) => { setTimeout(resolve); });
  }

  beforeEach(() => {
    controller = new AbortController();
    target = new EventTarget();
  });

  afterEach(() => {
    controller.abort();
  });

  it('re-bootstraps the Angular app on the second turbo:load', async () => {
    const appRef = makeAppRef([]);
    const bootstrap = vi.fn();
    const getPluginContext = () => Promise.resolve({ appRef } as OpenProjectPluginContext);

    addTurboAngularWrapper({
      target, signal: controller.signal, getPluginContext, bootstrap,
    });

    target.dispatchEvent(new Event('turbo:load')); // initial load — already bootstrapped
    await flush();
    target.dispatchEvent(new Event('turbo:load')); // navigation — must re-bootstrap
    await flush();

    expect(bootstrap).toHaveBeenCalledTimes(1);
    expect(bootstrap).toHaveBeenCalledWith(appRef);
  });

  it('tears down every existing root component before re-bootstrapping', async () => {
    // Hold the mocks as locals so the assertions never reference an unbound
    // method off the fake (eslint @typescript-eslint/unbound-method).
    const firstDestroy = vi.fn();
    const secondDestroy = vi.fn();
    const first = { hostView: {}, destroy: firstDestroy } as unknown as ComponentRef<unknown>;
    const second = { hostView: {}, destroy: secondDestroy } as unknown as ComponentRef<unknown>;
    const detachView = vi.fn();
    const appRef = { components: [first, second], detachView } as unknown as ApplicationRef;
    const bootstrap = vi.fn();
    const getPluginContext = () => Promise.resolve({ appRef } as OpenProjectPluginContext);

    addTurboAngularWrapper({
      target, signal: controller.signal, getPluginContext, bootstrap,
    });

    target.dispatchEvent(new Event('turbo:load')); // initial load — skipped
    await flush();
    target.dispatchEvent(new Event('turbo:load')); // navigation
    await flush();

    expect(detachView).toHaveBeenCalledWith(first.hostView);
    expect(detachView).toHaveBeenCalledWith(second.hostView);
    expect(firstDestroy).toHaveBeenCalledOnce();
    expect(secondDestroy).toHaveBeenCalledOnce();
    // Teardown must complete before the fresh bootstrap.
    expect(firstDestroy).toHaveBeenCalledBefore(bootstrap);
    expect(secondDestroy).toHaveBeenCalledBefore(bootstrap);
  });

  it('does not re-bootstrap on the initial turbo:load', async () => {
    const appRef = makeAppRef([]);
    const bootstrap = vi.fn();
    const getPluginContext = vi.fn(() => Promise.resolve({ appRef } as OpenProjectPluginContext));

    addTurboAngularWrapper({
      target, signal: controller.signal, getPluginContext, bootstrap,
    });

    target.dispatchEvent(new Event('turbo:load')); // initial load only
    await flush();

    expect(getPluginContext).not.toHaveBeenCalled();
    expect(bootstrap).not.toHaveBeenCalled();
  });

  it('stops re-bootstrapping once the signal aborts', async () => {
    const appRef = makeAppRef([]);
    const bootstrap = vi.fn();
    const getPluginContext = () => Promise.resolve({ appRef } as OpenProjectPluginContext);

    addTurboAngularWrapper({
      target, signal: controller.signal, getPluginContext, bootstrap,
    });

    controller.abort();

    target.dispatchEvent(new Event('turbo:load'));
    await flush();
    target.dispatchEvent(new Event('turbo:load'));
    await flush();

    expect(bootstrap).not.toHaveBeenCalled();
  });

  describe('pageshow (Back/Forward Cache) handling', () => {
    let windowTarget:EventTarget;

    beforeEach(() => {
      windowTarget = new EventTarget();
    });

    function pageshow(persisted:boolean):Event {
      const event = new Event('pageshow') as PageTransitionEvent;
      Object.defineProperty(event, 'persisted', { value: persisted });
      return event;
    }

    it('forces a replace visit when the page is resumed from bfcache', () => {
      const visit = vi.fn();

      addTurboAngularWrapper({
        target, windowTarget, signal: controller.signal, visit,
      });

      windowTarget.dispatchEvent(pageshow(true));

      expect(visit).toHaveBeenCalledWith(window.location.href, { action: 'replace' });
    });

    it('does nothing on a normal (non-persisted) pageshow', () => {
      const visit = vi.fn();

      addTurboAngularWrapper({
        target, windowTarget, signal: controller.signal, visit,
      });

      windowTarget.dispatchEvent(pageshow(false));

      expect(visit).not.toHaveBeenCalled();
    });

    it('stops forcing visits once the signal aborts', () => {
      const visit = vi.fn();

      addTurboAngularWrapper({
        target, windowTarget, signal: controller.signal, visit,
      });

      controller.abort();
      windowTarget.dispatchEvent(pageshow(true));

      expect(visit).not.toHaveBeenCalled();
    });
  });
});

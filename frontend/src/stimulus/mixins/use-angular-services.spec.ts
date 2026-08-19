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

import { waitFor } from '@testing-library/dom';
import { vi } from 'vitest';
import { Controller } from '@hotwired/stimulus';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import { useAngularServices, type ServiceKey } from './use-angular-services';

interface Deferred<T> {
  promise:Promise<T>;
  resolve:(value:T) => void;
}

function deferred<T>():Deferred<T> {
  let resolve!:(value:T) => void;
  const promise = new Promise<T>((r) => { resolve = r; });
  return { promise, resolve };
}

class TestController extends Controller<HTMLElement> {
  static services:ServiceKey[] = ['halEvents', 'i18n'];

  declare halEvents:unknown;
  declare i18n:unknown;
  declare services:Promise<Record<string, unknown>>;
  declare pluginContext:Promise<unknown>;

  servicesConnectedCount = 0;

  initialize() {
    useAngularServices(this);
  }

  servicesConnected() {
    this.servicesConnectedCount += 1;
  }
}

class BadServiceController extends Controller<HTMLElement> {
  static services = ['unknownService'] as unknown as ServiceKey[];

  initialize() {
    useAngularServices(this);
  }
}

class PlainController extends Controller<HTMLElement> {
  declare services:Promise<Record<string, unknown>>;

  initialize() {
    useAngularServices(this);
  }
}

describe('useAngularServices', () => {
  let ctx:StimulusTestContext;
  let originalOpenProject:typeof window.OpenProject;
  let halEvents:{ service:string };
  let i18n:{ service:string };
  let timezone:{ service:string };
  let pluginContext:{ services:Record<string, unknown> };

  function stubPluginContext(getPluginContext:() => Promise<unknown>) {
    window.OpenProject = { getPluginContext } as unknown as typeof window.OpenProject;
  }

  beforeEach(async () => {
    halEvents = { service: 'halEvents' };
    i18n = { service: 'i18n' };
    timezone = { service: 'timezone' };
    pluginContext = { services: { halEvents, i18n, timezone } };

    originalOpenProject = window.OpenProject;
    stubPluginContext(() => Promise.resolve(pluginContext));

    ctx = await setupStimulusTest({
      controllers: {
        'use-services-test': TestController,
        'use-services-bad': BadServiceController,
        'use-services-plain': PlainController,
      },
    });
  });

  afterEach(() => {
    ctx.dispose();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  async function mountController<T extends Controller>(identifier:string):Promise<{ controller:T, element:HTMLElement }> {
    await ctx.mount(`<div data-controller="${identifier}"></div>`);
    const element = ctx.container.querySelector<HTMLElement>(`[data-controller="${identifier}"]`)!;
    const controller = ctx.getController<T>(identifier, element);
    return { controller, element };
  }

  it('binds the declared services on the controller and then calls servicesConnected', async () => {
    const { controller } = await mountController<TestController>('use-services-test');

    await waitFor(() => { expect(controller.servicesConnectedCount).toBe(1); });

    expect(controller.halEvents).toBe(halEvents);
    expect(controller.i18n).toBe(i18n);
  });

  it('calls servicesConnected again on every reconnect', async () => {
    const { controller, element } = await mountController<TestController>('use-services-test');
    await waitFor(() => { expect(controller.servicesConnectedCount).toBe(1); });

    element.remove();
    await ctx.nextFrame();
    ctx.container.append(element);

    await waitFor(() => { expect(controller.servicesConnectedCount).toBe(2); });
  });

  it('does not call servicesConnected when disconnected before the context resolves', async () => {
    const context = deferred<unknown>();
    stubPluginContext(() => context.promise);

    const { controller, element } = await mountController<TestController>('use-services-test');

    element.remove();
    await ctx.nextFrame();

    context.resolve(pluginContext);
    await ctx.nextFrame();

    expect(controller.servicesConnectedCount).toBe(0);
    expect(controller.halEvents).toBeUndefined();
  });

  it('ignores a stale resolution from before a reconnect', async () => {
    const first = deferred<unknown>();
    const second = deferred<unknown>();
    const getPluginContext = vi.fn()
      .mockReturnValueOnce(first.promise)
      .mockReturnValueOnce(second.promise);
    stubPluginContext(getPluginContext as () => Promise<unknown>);

    const { controller, element } = await mountController<TestController>('use-services-test');

    element.remove();
    await ctx.nextFrame();
    ctx.container.append(element);
    await waitFor(() => { expect(getPluginContext).toHaveBeenCalledTimes(2); });

    second.resolve(pluginContext);
    await waitFor(() => { expect(controller.servicesConnectedCount).toBe(1); });

    first.resolve(pluginContext);
    await ctx.nextFrame();

    expect(controller.servicesConnectedCount).toBe(1);
  });

  it('exposes a services promise resolving to the declared subset', async () => {
    const { controller } = await mountController<TestController>('use-services-test');

    const services = await controller.services;

    expect(services).toEqual({ halEvents, i18n });
  });

  it('never resolves a pending services promise after disconnect', async () => {
    const context = deferred<unknown>();
    stubPluginContext(() => context.promise);

    const { controller, element } = await mountController<TestController>('use-services-test');

    const resolved = vi.fn();
    void controller.services.then(resolved);

    element.remove();
    await ctx.nextFrame();

    context.resolve(pluginContext);
    await ctx.nextFrame();

    expect(resolved).not.toHaveBeenCalled();
  });

  it('never resolves a services promise obtained after disconnect', async () => {
    const context = deferred<unknown>();
    stubPluginContext(() => context.promise);

    const { controller, element } = await mountController<TestController>('use-services-test');

    element.remove();
    await ctx.nextFrame();

    const resolved = vi.fn();
    void controller.services.then(resolved);

    context.resolve(pluginContext);
    await ctx.nextFrame();

    expect(resolved).not.toHaveBeenCalled();
  });

  it('never resolves a services promise requested while disconnected once reconnected', async () => {
    const context = deferred<unknown>();
    stubPluginContext(() => context.promise);

    const { controller, element } = await mountController<TestController>('use-services-test');

    element.remove();
    await ctx.nextFrame();

    const resolved = vi.fn();
    void controller.services.then(resolved);

    ctx.container.append(element);
    await ctx.nextFrame();

    context.resolve(pluginContext);
    await ctx.nextFrame();

    expect(resolved).not.toHaveBeenCalled();
  });

  it('exposes a pluginContext promise resolving to the full context', async () => {
    const { controller } = await mountController<TestController>('use-services-test');

    await expect(controller.pluginContext).resolves.toBe(pluginContext);
  });

  it('reports an error when a declared service does not exist', async () => {
    const handleError = vi.fn();
    ctx.application.handleError = handleError;

    await mountController<BadServiceController>('use-services-bad');

    await waitFor(() => { expect(handleError).toHaveBeenCalled(); });
    expect((handleError.mock.calls[0][0] as Error).message).toContain('unknownService');
  });

  it('works without a static services list and without a servicesConnected hook', async () => {
    const { controller } = await mountController<PlainController>('use-services-plain');

    await expect(controller.services).resolves.toEqual({});
  });
});

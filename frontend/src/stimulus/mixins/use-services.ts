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

import type { Controller } from '@hotwired/stimulus';
import type { OpenProjectPluginContext } from 'core-app/features/plugins/plugin-context';

export type ServiceKey = keyof OpenProjectPluginContext['services'];

export type PickedServices<K extends ServiceKey = ServiceKey> = Pick<OpenProjectPluginContext['services'], K>;

interface ServiceConsumer {
  servicesConnected?:() => void;
}

/**
 * Binds Angular plugin context services to a Stimulus controller, owning all
 * the `window.OpenProject.getPluginContext()` boilerplate and its
 * disconnect-before-resolve races.
 *
 * Usage:
 *
 *     export default class ListRefreshController extends Controller<HTMLElement> {
 *       static services:ServiceKey[] = ['halEvents'];
 *       declare halEvents:HalEventsService;
 *
 *       initialize() {
 *         useServices(this);
 *       }
 *
 *       // Fires after every connect(), once the context has resolved and the
 *       // element is still connected.
 *       servicesConnected() {
 *         this.subscription = this.halEvents.aggregated$('WorkPackage')...
 *       }
 *     }
 *
 * For use outside `servicesConnected()` (e.g. event handlers), the mixin also
 * defines two promise properties on the controller (add matching `declare`
 * lines to get typing):
 *
 * - `this.services` — resolves to the declared subset of context services
 * - `this.pluginContext` — resolves to the full `OpenProjectPluginContext`,
 *   the escape hatch for `classes`, `helpers` and `injector`
 *
 * Both promises never settle while the controller is disconnected at context
 * resolution time — whether obtained before or after the disconnect — so code
 * after an `await` cannot act on a dead element.
 */
export function useServices(controller:Controller):void {
  const declaredServices = (controller.constructor as unknown as { services?:ServiceKey[] }).services ?? [];

  // Each disconnect invalidates anything still pending from the previous
  // connection — replaces the per-controller Symbol-token pattern.
  let epoch = 0;

  const guarded = <T>(map:(context:OpenProjectPluginContext) => T):Promise<T> => {
    const token = epoch;
    return window.OpenProject.getPluginContext().then((context) => {
      if (token !== epoch || !controller.element.isConnected) {
        return new Promise<T>(() => {
          // Disconnected while pending — never settle (see doc block above).
        });
      }
      return map(context);
    });
  };

  const pickServices = (context:OpenProjectPluginContext):Record<string, unknown> => {
    const picked:Record<string, unknown> = {};
    declaredServices.forEach((key) => {
      if (!(key in context.services)) {
        throw new Error(`useServices: unknown plugin context service "${key}"`);
      }
      picked[key] = context.services[key];
    });
    return picked;
  };

  const connectServices = async () => {
    const token = epoch;
    try {
      const context = await window.OpenProject.getPluginContext();
      if (token !== epoch || !controller.element.isConnected) {
        return;
      }
      Object.assign(controller, pickServices(context));
      (controller as ServiceConsumer).servicesConnected?.();
    } catch (error) {
      controller.application.handleError(
        error as Error,
        `Error connecting plugin context services for "${controller.identifier}"`,
        {},
      );
    }
  };

  const originalConnect = controller.connect.bind(controller);
  const originalDisconnect = controller.disconnect.bind(controller);

  controller.connect = () => {
    originalConnect();
    void connectServices();
  };

  controller.disconnect = () => {
    epoch += 1;
    originalDisconnect();
  };

  Object.defineProperty(controller, 'services', {
    get: () => guarded(pickServices),
    configurable: true,
  });

  Object.defineProperty(controller, 'pluginContext', {
    get: () => guarded((context) => context),
    configurable: true,
  });
}

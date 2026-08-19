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

import { skip } from 'rxjs/operators';
import { fromEvent } from 'rxjs';
import type { ApplicationRef } from '@angular/core';
import { runBootstrap } from 'core-app/app.module';
import { OpenProjectPluginContext } from 'core-app/features/plugins/plugin-context';

export interface AngularTurboBridgeOptions {
  // The event source the bridge listens on. Defaults to the global `document`;
  // a spec can pass its own `EventTarget` to drive synthetic `turbo:load`
  // events in isolation.
  target?:EventTarget;
  // Aborts the `turbo:load` subscription so a spec (or future caller) can tear
  // the bridge down between cases.
  signal?:AbortSignal;
  // Resolves the Angular plugin context carrying the `appRef`. Defaults to the
  // real `window.OpenProject` lookup; injected so specs need no global.
  getPluginContext?:() => Promise<OpenProjectPluginContext>;
  // Re-bootstraps the root application onto a fresh `appBaseSelector`. Defaults
  // to `app.module`'s `runBootstrap`.
  bootstrap?:(appRef:ApplicationRef) => void;
}

export function addTurboAngularWrapper(options:AngularTurboBridgeOptions = {}) {
  const {
    target = document,
    signal,
    getPluginContext = () => window.OpenProject.getPluginContext(),
    bootstrap = runBootstrap,
  } = options;

  // When turbo:load fires, the angular application needs to be rebootstrapped.
  // However, we don't want this to happen on the initial page load
  const subscription = fromEvent(target, 'turbo:load')
    .pipe(
      skip(1), // Skip the first turbo:load event
    )
    .subscribe(() => {
      void getPluginContext()
        .then((pluginContext:OpenProjectPluginContext) => {
          const appRef = pluginContext.appRef;

          // Remove all previous references to components
          // This is mainly the base component
          appRef.components.slice().forEach((component) => {
            appRef.detachView(component.hostView);
            component.destroy();
          });

          // Run bootstrap again to initialize the new application
          bootstrap(appRef);
        });
    });

  signal?.addEventListener('abort', () => subscription.unsubscribe(), { once: true });
}

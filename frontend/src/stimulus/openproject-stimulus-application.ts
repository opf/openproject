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

import { ControllerConstructor } from '@hotwired/stimulus/dist/types/core/controller';
import { Application } from '@hotwired/stimulus';

export type DynamicControllerLoader = () => Promise<{ default:ControllerConstructor }>;

export class OpenProjectStimulusApplication extends Application {
  /** A map of controllers that have been preregistered. */
  static controllers = new Map<string, ControllerConstructor>();

  /** A map of a dynamic controller loader to load when the controller name is found */
  static dynamicImports = new Map<string, DynamicControllerLoader>();

  /**
   * Register a controller to be used in the application,
   * allowing it to be registered before the Stimulus application is being initialized.
   *
   * This is useful for plugins that execute code before we call setup.ts
   *
   * @param name - The name/identifier of the controller
   * @param controller - The controller class
   */
  static preregister(name:string, controller:ControllerConstructor) {
    this.controllers.set(name, controller);
  }

  /**
   * Register a dynamic controller to be imported using the given path,
   * allowing it to be defined somewhere else than within the dynamic/ subfolder.
   *
   * This is useful for plugins that want to define new dynamic controllers.
   * How to use this: In your plugin's main.ts, call this
   *
   * @example
   * ```ts
   * OpenProjectStimulusApplication.preregisterDynamic(
   *   'test',
   *   () => import('./test.controller')
   * );
   * ```
   *
   * @param name - The name/identifier of the controller
   * @param loader - A callback to provide the controller asynchronously.
   */
  static preregisterDynamic(name:string, loader:DynamicControllerLoader) {
    this.dynamicImports.set(name, loader);
  }

  async start():Promise<void> {
    this.preregisteredControllers.forEach((controller, name) => {
      this.register(name, controller);
    });

    await super.start();
  }

  get preregisteredControllers() {
    return OpenProjectStimulusApplication.controllers;
  }
}

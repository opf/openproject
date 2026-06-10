/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { Application, Controller } from '@hotwired/stimulus';
import { type ControllerConstructor } from '@hotwired/stimulus/dist/types/core/controller';
import { getQueriesForElement, queries, type BoundFunctions } from '@testing-library/dom';

export interface StimulusTestContext {
  application:Application;
  container:HTMLElement;
  screen:BoundFunctions<typeof queries>;
  appendHTML(html:string):void;
  mount(html:string):Promise<void>;
  getController<T extends Controller>(identifier:string, element?:Element):T;
  nextFrame():Promise<void>;
  dispose():void;
}

export interface SetupOptions {
  controllers:Record<string, ControllerConstructor>;
}

export async function setupStimulusTest(options:SetupOptions):Promise<StimulusTestContext> {
  const container = document.createElement('div');
  document.body.appendChild(container);

  const application = Application.start(container);
  const stimulusErrors:Error[] = [];
  application.handleError = (error:Error, message:string, detail:Record<string, unknown>) => {
    console.error(error, message, detail);
    stimulusErrors.push(error);
  };

  for (const [identifier, ctor] of Object.entries(options.controllers)) {
    application.register(identifier, ctor);
  }

  const screen = getQueriesForElement(container);

  const ctx:StimulusTestContext = {
    application,
    container,
    screen,

    appendHTML(html:string) {
      const template = document.createElement('template');
      template.innerHTML = html.trim();
      container.appendChild(template.content.cloneNode(true));
    },

    async mount(html:string) {
      this.appendHTML(html);
      await this.nextFrame();
    },

    getController<T extends Controller>(identifier:string, element?:Element):T {
      const el = element ?? container.querySelector(`[data-controller~="${identifier}"]`);
      if (!el) {
        throw new Error(`No element found matching [data-controller~="${identifier}"]`);
      }
      const controller = application.getControllerForElementAndIdentifier(el, identifier);
      if (!controller) {
        throw new Error(`Controller "${identifier}" not connected on element`);
      }
      return controller as T;
    },

    nextFrame() {
      return new Promise<void>((resolve) => requestAnimationFrame(() => resolve()));
    },

    dispose() {
      application.stop();
      container.remove();
      if (stimulusErrors.length > 0) {
        throw stimulusErrors[0];
      }
    },
  };

  await ctx.nextFrame();
  return ctx;
}

export function createControllerInstance<T extends Controller>(
  ControllerClass:{ new (...args:unknown[]):T; prototype:T },
):T {
  return Object.create(ControllerClass.prototype) as T;
}

//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import { OpenProjectPluginContext } from 'core-app/modules/plugins/plugin-context';
import { input, InputState } from 'reactivestates';
import { take } from 'rxjs/operators';
import { GlobalHelpers } from "core-app/globals/global-helpers";

/**
 * OpenProject instance methods
 */
export class OpenProject {

  public pluginContext:InputState<OpenProjectPluginContext> = input<OpenProjectPluginContext>();

  public helpers = new GlobalHelpers();

  /** Globally setable variable whether the page was edited */
  public pageWasEdited = false;
  /** Globally setable variable whether the page form is submitted.
   * Necessary to avoid a data loss warning on beforeunload */
  public pageIsSubmitted = false;
  /** Globally setable variable whether any of the EditFormComponent
   * contain changes.
   * Necessary to show a data loss warning on beforeunload when clicking
   * on a link out of the Angular app (ie: main side menu)
   * */
  public editFormsContainModelChanges:boolean;

  public getPluginContext():Promise<OpenProjectPluginContext> {
    return this.pluginContext
      .values$()
      .pipe(take(1))
      .toPromise();
  }

  public get urlRoot():string {
    return jQuery('meta[name=app_base_path]').attr('content') || '';
  }

  public get environment():string {
    return jQuery('meta[name=openproject_initializer]').data('environment');
  }

  public get edition():string {
    return jQuery('meta[name=openproject_initializer]').data('edition');
  }

  public get isStandardEdition():boolean {
    return this.edition === "standard";
  }

  public get isBimEdition():boolean {
    return this.edition === "bim";
  }

  /**
   * Guard access to reads and writes to the localstorage due to corrupted local databases
   * in Firefox happening in one larger client.
   *
   * NS_ERROR_FILE_CORRUPTED
   *
   * @param {string} key
   * @param {string} newValue
   * @returns {string | undefined}
   */
  public guardedLocalStorage(key:string, newValue?:string):string | void {
    try {
      if (newValue !== undefined) {
        window.localStorage.setItem(key, newValue);
      } else {
        const value = window.localStorage.getItem(key);
        return value === null ? undefined : value;
      }
    } catch (e) {
      console.error('Failed to access your browsers local storage. Is your local database corrupted?');
    }
  }
}

window.OpenProject = new OpenProject();

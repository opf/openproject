//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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
// See doc/COPYRIGHT.rdoc for more details.
//++

import {$currentInjector} from "core-components/angular/angular-injector-bridge.functions";

export class OpenProjectAngularHelpers {
  private memoizedCompileScope: any = null;

  public get injector() {
    return $currentInjector();
  }

  public get compileScope() {
    if (!this.memoizedCompileScope) {
      this.memoizedCompileScope = this.injector.get('$rootScope').$new();
    }

    return this.memoizedCompileScope;
  }

  public compile(html: string) {
    const compile = this.injector.get('$compile');
    return compile(html)(this.compileScope);
  }
}

/**
* OpenProject instance methods
*/
export class OpenProject {

  public get urlRoot(): string {
    return jQuery('meta[name=app_base_path]').attr('content') || '';
  }

  public get environment():string {
    return jQuery('meta[name=openproject_initializer]').data('environment');
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
  public guardedLocalStorage(key:string, newValue?:string):string|void {
    try {
      if (newValue !== undefined) {
        window.localStorage.setItem(key, newValue);
      } else {
        const value = window.localStorage.getItem(key)
        return value === null ? undefined : value;
      }
    } catch (e) {
      console.error('Failed to access your browsers local storage. Is your local database corrupted?');
    }
  }

  public get Helpers() {
    return {
      Angular: new OpenProjectAngularHelpers()
    };
  }
}

window.OpenProject = new OpenProject();


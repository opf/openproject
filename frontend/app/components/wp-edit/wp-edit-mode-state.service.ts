// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {openprojectModule} from "../../angular-modules";
import {WorkPackageEditFormController} from "./wp-edit-form.directive";

export class WorkPackageEditModeStateService {
  public form: WorkPackageEditFormController;
  public _active: boolean = false;

  constructor(protected $rootScope, protected $window, protected I18n) {

    $rootScope.$on('$stateChangeStart', function (event, toState, toParams, fromState, fromParams) {
      if (this.form && fromParams.workPackageId
        && toParams.workPackageId !== fromParams.workPackageId) {

        if (!$window.confirm(I18n.t('js.text_are_you_sure'))) {
          return event.preventDefault();
        }

        this.cancel();
      }
    });
  }

  public start() {
    if (!this.active) {
      this.form.toggleEditMode(true);
      this._active = true;
    }
  }

  public cancel() {
    if (this.active) {
      this.form.toggleEditMode(false);
      this._active = false;
    }
  }
  
  public save() {
    if (this.active) {
      this.form.updateWorkPackage().then(() => {
        // Doesn't use cancel() since that resets all values
        this.form.closeAllFields();
        this._active = false;
      });
    }
  }
  
  public register(form: WorkPackageEditFormController) {
    this.form = form;
  }

  public get active() {
    return this._active;
  }
}


openprojectModule.service('wpEditModeState', WorkPackageEditModeStateService)

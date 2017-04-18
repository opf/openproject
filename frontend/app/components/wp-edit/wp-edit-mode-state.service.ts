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
  public form:WorkPackageEditFormController;

  private _active:boolean = false;

  constructor(
    protected $rootScope:ng.IRootScopeService,
    protected ConfigurationService:any,
    protected $window:ng.IWindowService,
    protected $q:ng.IQService,
    protected I18n:op.I18n) {
    const confirmText = I18n.t('js.work_packages.confirm_edit_cancel');
    const requiresConfirmation = ConfigurationService.warnOnLeavingUnsaved();

    $rootScope.$on('$stateChangeStart', (event, toState, toParams, fromState, fromParams) => {
      // Show confirmation message when transitioning to a new state
      // that's not withing the edit mode.
      if (this.active && !this.allowedStateChange(toState, toParams, fromState, fromParams)) {
        if (requiresConfirmation && !$window.confirm(confirmText)) {
          return event.preventDefault();
        }

        this.cancel();
      }
    });
  }

  public start():boolean {
    if (!this.active && !!this.form) {
      this.form.toggleEditMode(true);
    }
    return this._active = true;
  }

  public cancel() {
    if (this.active && !!this.form) {
      this.form.toggleEditMode(false);
    }
    return this._active = false;
  }

  public onSaved() {
    // Doesn't use cancel() since that resets all values
    this.form.closeAllFields();
    this._active = false;
  }

  public save() {
    if (this.active) {
      return this.form.updateWorkPackage().then(wp => {
        this.onSaved();
        return wp;
      });
    }

    return this.$q.reject();
  }

  public register(form:WorkPackageEditFormController) {
    this.form = form;

    // Activate form when it registers after the
    // edit mode has been requested.
    if (this.active) {
      form.toggleEditMode(true);
    }
  }

  public get active() {
    return this._active;
  }

  private allowedStateChange(toState:any, toParams:any, fromState:any, fromParams:any) {

    // In new/copy mode, transitions to the same controller are allowed
    if (fromState.name.match(/\.(new|copy)$/)) {
      return fromState.controller === toState.controller;
    }

    // When editing an existing WP, transitions on the same WP id are allowed
    return toParams.workPackageId !== undefined && toParams.workPackageId === fromParams.workPackageId;
  }
}


openprojectModule.service('wpEditModeState', WorkPackageEditModeStateService);

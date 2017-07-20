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

import {WorkPackageEditFieldController} from './wp-edit-field.directive';
import {States} from '../../states.service';
import {opWorkPackagesModule} from '../../../angular-modules';
import {WorkPackageEditingService} from '../../wp-edit-form/work-package-editing-service';
import {WorkPackageEditForm} from '../../wp-edit-form/work-package-edit-form';
import {SingleViewEditContext} from '../../wp-edit-form/single-view-edit-context';
import {input} from 'reactivestates';
import {scopeDestroyed$} from '../../../helpers/angular-rx-utils';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';

export class WorkPackageEditFieldGroupController {
  public workPackageId:string;
  public inEditMode:boolean;
  public fields:{ [attribute:string]:WorkPackageEditFieldController } = {};
  private registeredFields = input<string[]>();

  constructor(protected $scope:ng.IScope,
              protected states:States,
              protected wpEditing:WorkPackageEditingService,
              protected $rootScope:ng.IRootScopeService,
              protected $window:ng.IWindowService,
              protected ConfigurationService:any,
              protected $q:ng.IQService,
              protected I18n:op.I18n) {
    const confirmText = I18n.t('js.work_packages.confirm_edit_cancel');
    const requiresConfirmation = ConfigurationService.warnOnLeavingUnsaved();

    $rootScope.$on('$stateChangeStart', (event, toState, toParams, fromState, fromParams) => {
      // Show confirmation message when transitioning to a new state
      // that's not withing the edit mode.
      if (this.isEditing && !this.allowedStateChange(toState, toParams, fromState, fromParams)) {
        if (requiresConfirmation && !$window.confirm(confirmText)) {
          return event.preventDefault();
        }

        this.stop();
      }
    });
  }

  public $onInit() {
    this.states.workPackages.get(this.workPackageId)
      .values$()
      .takeUntil(scopeDestroyed$(this.$scope))
      .subscribe((wp) => {
        _.each(this.fields, (ctrl) => this.update(ctrl, wp));
      });

    if (this.inEditMode) {
      this.start();
    }
  }

  public get isEditing() {
    const form = this.editingForm;
    return (form && form.editMode);
  }

  public register(field:WorkPackageEditFieldController) {
    this.fields[field.fieldName] = field;
    this.registeredFields.putValue(_.keys(this.fields));
    const form = this.editingForm;

    if (form && form.editMode) {
      field.activateOnForm(form, true);
    } else {
      this.states.workPackages
        .get(this.workPackageId)
        .valuesPromise()
        .then(wp => this.update(field, wp!));
    }
  }

  public waitForField(name:string):Promise<WorkPackageEditFieldController> {
    return this.registeredFields
      .values$()
      .filter(keys => keys.indexOf(name) >= 0)
      .take(1)
      .map(() => this.fields[name])
      .toPromise();
  }

  public start() {
    const form = this.wpEditing.startEditing(this.workPackageId, this.editContext, true);
    _.each(this.fields, ctrl => form.activate(ctrl.fieldName));
  }

  public stop() {
    this.wpEditing.stopEditing(this.workPackageId);
  }

  private update(field:WorkPackageEditFieldController, wp:WorkPackageResourceInterface) {
    field.workPackage = wp;
    field.render();
  }

  private get editContext() {
    return new SingleViewEditContext(this);
  }

  private get editingForm():WorkPackageEditForm | undefined {
    const state = this.wpEditing.editState(this.workPackageId);
    return state.value;
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

opWorkPackagesModule.directive('wpEditFieldGroup', function() {
  return {
    restrict: 'EA',
    controller: WorkPackageEditFieldGroupController,
    bindToController: true,
    scope: {
      workPackageId: '=',
      inEditMode: '=?'
    }
  };
});


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
import {WorkPackageTableSelection} from '../../wp-fast-table/state/wp-table-selection.service';
import {WorkPackageNotificationService} from '../wp-notification.service';

export class WorkPackageEditFieldGroupController {
  public workPackage:WorkPackageResourceInterface
  public successState?:string;
  public inEditMode:boolean;
  public form:WorkPackageEditForm;
  public fields:{ [attribute:string]:WorkPackageEditFieldController } = {};
  private registeredFields = input<string[]>();
  private unregisterListener:Function;

  constructor(protected $scope:ng.IScope,
              protected $state:ng.ui.IStateService,
              protected states:States,
              protected wpEditing:WorkPackageEditingService,
              protected wpNotificationsService:WorkPackageNotificationService,
              protected wpTableSelection:WorkPackageTableSelection,
              protected $rootScope:ng.IRootScopeService,
              protected $window:ng.IWindowService,
              protected ConfigurationService:any,
              protected $q:ng.IQService,
              protected I18n:op.I18n) {
    const confirmText = I18n.t('js.work_packages.confirm_edit_cancel');
    const requiresConfirmation = ConfigurationService.warnOnLeavingUnsaved();

    this.unregisterListener = $rootScope.$on('$stateChangeStart', (event, toState, toParams, fromState, fromParams) => {
      if (!this.editMode) {
        return;
      }

      // Show confirmation message when transitioning to a new state
      // that's not withing the edit mode.
      if (!this.allowedStateChange(toState, toParams, fromState, fromParams)) {
        if (requiresConfirmation && !$window.confirm(confirmText)) {
          return event.preventDefault();
        }

        this.stop();
      }
    });
    
    $scope.$on('$destroy', () => {
      this.unregisterListener();
      this.form.destroy();
    });
  }

  public $onInit() {
    const context = new SingleViewEditContext(this);
    this.form = WorkPackageEditForm.createInContext(context, this.workPackage, this.inEditMode);

    this.states.workPackages.get(this.workPackage.id)
      .values$()
      .takeUntil(scopeDestroyed$(this.$scope))
      .subscribe((wp) => {
        _.each(this.fields, (ctrl) => this.updateDisplayField(ctrl, wp));
      });

    if (this.inEditMode) {
      this.start();
    }
  }

  public get editMode() {
    return this.inEditMode && this.form.editMode;
  }

  public register(field:WorkPackageEditFieldController) {
    this.fields[field.fieldName] = field;
    this.registeredFields.putValue(_.keys(this.fields));

    if (this.inEditMode) {
      field.activateOnForm(this.form, true);
    } else {
      this.states.workPackages
        .get(this.workPackage.id)
        .valuesPromise()
        .then(wp => this.updateDisplayField(field, wp!));
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
    _.each(this.fields, ctrl => this.form.activate(ctrl.fieldName));
  }

  public stop() {
    this.wpEditing.stopEditing(this.workPackage.id);
  }

  public saveWorkPackage() {
    const isInitial = this.workPackage.isNew;
    return this.form
      .submit()
      .then((savedWorkPackage) => {
        this.wpEditing.stopEditing(this.workPackage.id);

        if (this.successState) {
          this.$state.go(this.successState, {workPackageId: savedWorkPackage.id})
            .then(() => {
              this.wpTableSelection.focusOn(savedWorkPackage.id);
              this.wpNotificationsService.showSave(savedWorkPackage, isInitial);
            });
        }
      });
  }

  private updateDisplayField(field:WorkPackageEditFieldController, wp:WorkPackageResourceInterface) {
    field.workPackage = wp;
    field.render();
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
    controllerAs: '$fieldGroupCtrl',
    scope: {
      workPackage: '=',
      successState: '=?',
      inEditMode: '=?'
    }
  };
});


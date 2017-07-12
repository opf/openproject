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

import {scopeDestroyed$} from '../../../helpers/angular-rx-utils';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {ContextMenuService} from '../../context-menus/context-menu.service';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {WorkPackageNotificationService} from '../wp-notification.service';
import {opWorkPackagesModule} from '../../../angular-modules';
import {States} from '../../states.service';
import {InputState} from 'reactivestates';
import {WorkPackageEditForm} from '../../wp-edit-form/work-package-edit-form';
import {SingleViewEditContext} from '../../wp-edit-form/single-view-edit-context';
import {DisplayFieldRenderer} from '../../wp-edit-form/display-field-renderer';
import {WorkPackageEditFieldGroupController} from './wp-edit-field-group.directive';
import {WorkPackageEditingService} from '../../wp-edit-form/work-package-editing-service';

export class WorkPackageEditFieldController {
  public wpEditFieldGroup:WorkPackageEditFieldGroupController;
  public fieldName:string;
  public displayPlaceholder:string;
  public workPackageId:string;
  public workPackage:WorkPackageResourceInterface;
  public fieldRenderer = new DisplayFieldRenderer('single-view');

  constructor(protected states:States,
              protected $scope:ng.IScope,
              protected $element:ng.IAugmentedJQuery,
              protected $timeout:ng.ITimeoutService,
              protected $q:ng.IQService,
              protected wpEditing:WorkPackageEditingService,
              protected FocusHelper:any,
              protected NotificationsService:any,
              protected wpNotificationsService:WorkPackageNotificationService,
              protected ConfigurationService:any,
              protected contextMenu:ContextMenuService,
              protected wpCacheService:WorkPackageCacheService,
              protected ENTER_KEY:any,
              protected I18n:op.I18n) {

  }

  public $onInit() {
    this.wpEditFieldGroup.register(this);
    this.states.workPackages.get(this.workPackageId)
      .values$()
      .takeUntil(scopeDestroyed$(this.$scope))
      .subscribe((wp) => {
        this.workPackage = wp;
        this.render();
      });
  }

  public render() {
    const el = this.fieldRenderer.render(this.workPackage, this.fieldName, this.displayPlaceholder);
    this.displayContainer[0].innerHTML = '';
    this.displayContainer[0].appendChild(el);
  }

  public deactivate(focus:boolean = false) {
    this.editContainer.empty().hide();
    this.displayContainer.show();

    if (focus) {
      this.FocusHelper.focusElement(this.displayContainer);
    }
  }

  public get isEditable() {
    const fieldSchema = this.workPackage.schema[this.fieldName] as op.FieldSchema;
    return this.workPackage.isEditable && fieldSchema && fieldSchema.writable;
  }

  public activateIfEditable(event:JQueryEventObject) {
    if (this.isEditable) {
      this.handleUserActivate();
    }

    this.contextMenu.close();
    event.stopImmediatePropagation();
  }

  public activate(noWarnings:boolean = false) {
    // Get any existing edit state for this work package
    let state = this.states.editing.get(this.workPackage.id);
    let form = state.value || this.startEditing(state);

    form.editContext = new SingleViewEditContext(this.workPackage.id, this.wpEditFieldGroup);
    // Activate the field
    const promise = form.activate(this.fieldName, noWarnings);
    promise.catch(() => this.deactivate(true))

    return promise;
  }

  public handleUserActivate() {
    this.activate()
      .then((handler) => {
        handler.focus();
      });
  }

  public get displayContainer() {
    return this.$element.find('.wp-edit-field--display-container');
  }

  public get editContainer() {
    return this.$element.find('.wp-edit-field--edit-container');
  }

  private startEditing(state:InputState<WorkPackageEditForm>):WorkPackageEditForm {
    let form = new WorkPackageEditForm(this.workPackage.id, this.wpEditFieldGroup.inEditMode);
    state.putValue(form);
    return form;
  }

  public reset(workPackage:WorkPackageResourceInterface) {
    this.workPackage = workPackage;
    this.render();

    this.deactivate();
  }

}
opWorkPackagesModule.component('wpEditField', {
  templateUrl: '/components/wp-edit/wp-edit-field/wp-edit-field.directive.html',
  controller: WorkPackageEditFieldController,
  controllerAs: 'vm',
  bindings: {
    fieldName: '<',
    wrapperClasses: '<?',
    workPackageId: '<',
    displayPlaceholder: '<?'
  },
  require: {
    wpEditFieldGroup: '^wpEditFieldGroup'
  }
});

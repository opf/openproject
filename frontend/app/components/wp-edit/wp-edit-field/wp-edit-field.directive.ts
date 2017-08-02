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
import {WorkPackageEditForm} from '../../wp-edit-form/work-package-edit-form';
import {SingleViewEditContext} from '../../wp-edit-form/single-view-edit-context';
import {
  displayClassName,
  DisplayFieldRenderer,
  editFieldContainerClass
} from '../../wp-edit-form/display-field-renderer';
import {WorkPackageEditFieldGroupController} from './wp-edit-field-group.directive';
import {ClickPositionMapper} from '../../common/set-click-position/set-click-position';
import {WorkPackageEditFieldHandler} from '../../wp-edit-form/work-package-edit-field-handler';
import {WorkPackageEditingService} from '../../wp-edit-form/work-package-editing-service';

export class WorkPackageEditFieldController {
  public wpEditFieldGroup:WorkPackageEditFieldGroupController;
  public fieldName:string;
  public displayPlaceholder:string;
  public workPackageId:string;
  public workPackage:WorkPackageResourceInterface;
  public fieldRenderer = new DisplayFieldRenderer('single-view');
  public editFieldContainerClass = editFieldContainerClass;
  private active = false;

  constructor(protected states:States,
              protected $scope:ng.IScope,
              protected $element:ng.IAugmentedJQuery,
              protected $timeout:ng.ITimeoutService,
              protected $q:ng.IQService,
              protected NotificationsService:any,
              protected wpNotificationsService:WorkPackageNotificationService,
              protected ConfigurationService:any,
              protected contextMenu:ContextMenuService,
              protected wpEditing:WorkPackageEditingService,
              protected wpCacheService:WorkPackageCacheService,
              protected ENTER_KEY:any,
              protected I18n:op.I18n) {

  }

  public $onInit() {
    this.wpEditFieldGroup.register(this);
  }

  public render() {
    const el = this.fieldRenderer.render(this.resource, this.fieldName, this.displayPlaceholder);
    this.displayContainer[0].innerHTML = '';
    this.displayContainer[0].appendChild(el);
  }

  public deactivate(focus:boolean = false) {
    this.editContainer.empty().hide();
    this.displayContainer.show();

    this.$scope.$evalAsync(() => this.active = false);
    if (focus) {
      this.$element.find(`.${displayClassName}`).focus();
    }
  }

  public get resource() {
    return this.wpEditing
      .temporaryEditResource(this.workPackage.id)
      .getValueOr(this.workPackage);
  }

  public get isEditable() {
    const fieldSchema = this.resource.schema[this.fieldName] as op.FieldSchema;
    return this.resource.isEditable && fieldSchema && fieldSchema.writable;
  }

  public activateIfEditable(event:JQueryEventObject) {
    if (this.isEditable) {
      this.handleUserActivate(event);
    }

    this.contextMenu.close();
    event.stopImmediatePropagation();
  }

  public activate(noWarnings:boolean = false):Promise<WorkPackageEditFieldHandler> {
    return this.activateOnForm(this.wpEditFieldGroup.form, noWarnings);
  }

  public activateOnForm(form:WorkPackageEditForm, noWarnings:boolean = false) {
    // Activate the field
    const promise = form.activate(this.fieldName, noWarnings);
    promise
      .then(() => this.active = true)
      .catch(() => this.deactivate(true))

    return promise;
  }

  public handleUserActivate(evt:JQueryEventObject|null) {
    // Get the position where the user clicked.
    const positionOffset = evt ? ClickPositionMapper.getPosition(evt) : 0;

    this.activate()
      .then((handler) => {
        handler.focus();
        const input = handler.element.find('input');
        ClickPositionMapper.setPosition(input, positionOffset);
      });
  }

  public get displayContainer() {
    return this.$element.find('.__d_display_container');
  }

  public get editContainer() {
    return this.$element.find('.__d_edit_container');
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

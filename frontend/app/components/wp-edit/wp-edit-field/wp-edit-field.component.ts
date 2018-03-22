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

import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {WorkPackageNotificationService} from '../wp-notification.service';
import {opWorkPackagesModule} from '../../../angular-modules';
import {States} from '../../states.service';
import {WorkPackageEditForm} from '../../wp-edit-form/work-package-edit-form';
import {
  displayClassName,
  DisplayFieldRenderer,
  editFieldContainerClass
} from '../../wp-edit-form/display-field-renderer';
import {ClickPositionMapper} from '../../common/set-click-position/set-click-position';
import {WorkPackageEditFieldHandler} from '../../wp-edit-form/work-package-edit-field-handler';
import {WorkPackageEditingService} from '../../wp-edit-form/work-package-editing-service';
import {SelectionHelpers} from '../../../helpers/selection-helpers';
import {debugLog} from '../../../helpers/debug_output';
import {downgradeComponent} from '@angular/upgrade/static';
import {Component, ElementRef, Inject, Input, OnInit} from '@angular/core';
import {I18nToken, NotificationsServiceToken} from 'core-app/angular4-transition-utils';
import {WorkPackageEditFieldGroupComponent} from 'core-components/wp-edit/wp-edit-field/wp-edit-field-group.directive';
import {ConfigurationService} from 'core-components/common/config/configuration.service';
import {OPContextMenuService} from "core-components/op-context-menu/op-context-menu.service";

@Component({
  templateUrl: './wp-edit-field.html',
  selector: 'wp-edit-field',
})
export class WorkPackageEditFieldComponent implements OnInit {
  @Input('fieldName') public fieldName:string;
  @Input('workPackageId') public workPackageId:string;
  @Input('wrapperClasses') public wrapperClasses?:string;
  @Input('displayPlaceholder') public displayPlaceholder?:string;

  public workPackage:WorkPackageResourceInterface;
  public fieldRenderer = new DisplayFieldRenderer('single-view');
  public editFieldContainerClass = editFieldContainerClass;
  private active = false;
  private $element:ng.IAugmentedJQuery;

  constructor(protected states:States,
              protected elementRef:ElementRef,
              protected wpNotificationsService:WorkPackageNotificationService,
              protected ConfigurationService:ConfigurationService,
              protected opContextMenu:OPContextMenuService,
              protected wpEditing:WorkPackageEditingService,
              protected wpCacheService:WorkPackageCacheService,
              // Get parent field group from injector
              protected wpEditFieldGroup:WorkPackageEditFieldGroupComponent,
              @Inject(NotificationsServiceToken) protected NotificationsService:any,
              @Inject(I18nToken) readonly I18n:op.I18n) {

  }

  public ngOnInit() {
    this.$element = angular.element(this.elementRef.nativeElement);
    this.wpEditFieldGroup.register(this);
  }

  public render() {
    const el = this.fieldRenderer.render(this.resource, this.fieldName, null, this.displayPlaceholder);
    this.displayContainer[0].innerHTML = '';
    this.displayContainer[0].appendChild(el);
  }

  public deactivate(focus:boolean = false) {
    this.editContainer.empty().hide();
    this.displayContainer.show();

    this.active = false;
    if (focus) {
      this.$element.find(`.${displayClassName}`).focus();
    }
  }

  public get resource() {
    return this.wpEditing
      .temporaryEditResource(this.workPackageId)
      .getValueOr(this.wpEditFieldGroup.workPackage);
  }

  public get isEditable() {
    const fieldSchema = this.resource.schema[this.fieldName] as op.FieldSchema;
    return this.resource.isEditable && fieldSchema && fieldSchema.writable;
  }

  public activateIfEditable(event:JQueryEventObject) {
    // Ignore selections
    if (SelectionHelpers.hasSelectionWithin(event.target)) {
      debugLog(`Not activating ${this.fieldName} because of active selection within`);
      return true;
    }

    if (this.isEditable) {
      this.handleUserActivate(event);
    }

    this.opContextMenu.close();
    event.stopImmediatePropagation();

    return false;
  }

  public activate(noWarnings:boolean = false):Promise<WorkPackageEditFieldHandler> {
    return this.activateOnForm(this.wpEditFieldGroup.form, noWarnings);
  }

  public activateOnForm(form:WorkPackageEditForm, noWarnings:boolean = false) {
    // Activate the field
    const promise = form.activate(this.fieldName, noWarnings);
    promise
      .then(() => this.active = true)
      .catch(() => this.deactivate(true));

    return promise;
  }

  public handleUserActivate(evt:JQueryEventObject|null) {
    let positionOffset = 0;

    if (evt) {
      // Skip activation if the user clicked on a link
      const target = jQuery(evt.target);

      if (target.closest('a', this.displayContainer[0]).length > 0) {
        return true;
      }

      // Get the position where the user clicked.
      positionOffset = ClickPositionMapper.getPosition(evt);
    }

    this.activate()
      .then((handler) => {
        handler.focus();
        const input = handler.element.find('input');
        ClickPositionMapper.setPosition(input, positionOffset);
      });

    return false;
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

opWorkPackagesModule.component('wpEditField',
  downgradeComponent({component: WorkPackageEditFieldComponent})
);


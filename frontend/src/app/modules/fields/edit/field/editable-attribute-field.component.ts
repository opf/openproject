// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// ++

import {WorkPackageCacheService} from 'core-components/work-packages/work-package-cache.service';
import {HalResourceNotificationService} from "core-app/modules/hal/services/hal-resource-notification.service";
import {States} from 'core-components/states.service';
import {
  displayClassName,
  DisplayFieldRenderer,
  editFieldContainerClass
} from 'core-components/wp-edit-form/display-field-renderer';

import {HalResourceEditingService} from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import {SelectionHelpers} from '../../../../helpers/selection-helpers';
import {debugLog} from '../../../../helpers/debug_output';
import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Injector,
  Input,
  OnDestroy,
  OnInit,
  ViewChild
} from '@angular/core';
import {ConfigurationService} from 'core-app/modules/common/config/configuration.service';
import {OPContextMenuService} from "core-components/op-context-menu/op-context-menu.service";
import {NotificationsService} from 'core-app/modules/common/notifications/notifications.service';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {IFieldSchema} from "core-app/modules/fields/field.base";
import {ClickPositionMapper} from "core-app/modules/common/set-click-position/set-click-position";
import {EditFormComponent} from "core-app/modules/fields/edit/edit-form/edit-form.component";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";

@Component({
  selector: 'editable-attribute-field',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './editable-attribute-field.component.html'
})
export class EditableAttributeFieldComponent extends UntilDestroyedMixin implements OnInit, OnDestroy {
  @Input('fieldName') public fieldName:string;
  @Input('resource') public resource:HalResource;
  @Input('wrapperClasses') public wrapperClasses?:string;
  @Input('displayFieldOptions') public displayFieldOptions:any = {};
  @Input('displayPlaceholder') public displayPlaceholder?:string;
  @Input('isDropTarget') public isDropTarget?:boolean = false;

  @ViewChild('displayContainer', { static: true }) readonly displayContainer:ElementRef;
  @ViewChild('editContainer', { static: true }) readonly editContainer:ElementRef;

  public fieldRenderer:DisplayFieldRenderer;
  public editFieldContainerClass = editFieldContainerClass;
  public active = false;
  private $element:JQuery;

  public destroyed:boolean = false;

  constructor(protected states:States,
              protected injector:Injector,
              protected elementRef:ElementRef,
              protected halNotification:HalResourceNotificationService,
              protected ConfigurationService:ConfigurationService,
              protected opContextMenu:OPContextMenuService,
              protected halEditing:HalResourceEditingService,
              protected wpCacheService:WorkPackageCacheService,
              // Get parent field group from injector
              protected editForm:EditFormComponent,
              protected NotificationsService:NotificationsService,
              protected cdRef:ChangeDetectorRef,
              protected I18n:I18nService) {
    super();
  }

  public setActive(active:boolean = true) {
    this.active = active;
    if (!this.componentDestroyed) {
      this.cdRef.detectChanges();
    }
  }

  public ngOnInit() {
    this.fieldRenderer = new DisplayFieldRenderer(this.injector, 'single-view', this.displayFieldOptions);
    this.$element = jQuery(this.elementRef.nativeElement);
    this.editForm.register(this);

    this.halEditing
      .temporaryEditResource(this.resource)
      .values$()
      .pipe(
        this.untilDestroyed()
      )
      .subscribe(resource => {
        this.resource = resource;
        this.render();
      });
  }

  // Open the field when its closed and relay drag & drop events to it.
  public startDragOverActivation(event:JQuery.TriggeredEvent) {
    if (!this.isDropTarget || !this.isEditable || this.active) {
      return true;
    }

    this.handleUserActivate(null);
    event.preventDefault();
    return false;
  }

  public render() {
    const el = this.fieldRenderer.render(this.resource, this.fieldName, null, this.displayPlaceholder);
    this.displayContainer.nativeElement.innerHTML = '';
    this.displayContainer.nativeElement.appendChild(el);
  }

  public deactivate(focus:boolean = false) {
    this.editContainer.nativeElement.innerHTML = '';
    this.editContainer.nativeElement.hidden = true;
    this.setActive(false);

    if (focus) {
      setTimeout(() => this.$element.find(`.${displayClassName}`).focus(), 20);
    }
  }

  public get isEditable() {
    const fieldSchema = this.resource.schema[this.fieldName] as IFieldSchema;
    return this.resource.isAttributeEditable(this.fieldName) && fieldSchema && fieldSchema.writable;
  }

  public activateIfEditable(event:JQuery.TriggeredEvent) {
    // Ignore selections
    if (SelectionHelpers.hasSelectionWithin(event.target)) {
      debugLog(`Not activating ${this.fieldName} because of active selection within`);
      return true;
    }

    // Skip activation if the user clicked on a link or within a macro
    const target = jQuery(event.target);
    if (target.closest('a,macro', this.displayContainer.nativeElement).length > 0) {
      return true;
    }

    if (this.isEditable) {
      this.handleUserActivate(event);
    }

    this.opContextMenu.close();
    event.preventDefault();
    event.stopImmediatePropagation();

    return false;
  }

  public activateOnForm(noWarnings:boolean = false) {
    // Activate the field
    this.setActive(true);

    return this.editForm
      .activate(this.fieldName, noWarnings)
      .catch(() => this.deactivate(true));
  }

  public handleUserActivate(evt:JQuery.TriggeredEvent|null) {
    let positionOffset = 0;

    if (evt) {
      // Get the position where the user clicked.
      positionOffset = ClickPositionMapper.getPosition(evt);
    }

    this.activateOnForm()
      .then((handler) => {
        if (!handler) {
          return;
        }

        handler.$onUserActivate.next();
        handler.focus(positionOffset);
      });

    return false;
  }

  public reset() {
    this.render();
    this.deactivate();
  }

}

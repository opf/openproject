//-- copyright
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
//++

import {StateService} from '@uirouter/core';
import {OPContextMenuService} from "core-components/op-context-menu/op-context-menu.service";
import {Directive, ElementRef, Inject, Input} from "@angular/core";
import {OpContextMenuTrigger} from "core-components/op-context-menu/handlers/op-context-menu-trigger.directive";
import {WorkPackageEditingService} from "core-components/wp-edit-form/work-package-editing-service";
import {WorkPackageNotificationService} from "core-components/wp-edit/wp-notification.service";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {CollectionResource} from 'core-app/modules/hal/resources/collection-resource';
import {IWorkPackageEditingServiceToken} from "../../wp-edit-form/work-package-editing.service.interface";
import {Highlighting} from "core-components/wp-fast-table/builders/highlighting/highlighting.functions";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {WorkPackageEventsService} from "core-app/modules/work_packages/events/work-package-events.service";

@Directive({
  selector: '[wpStatusDropdown]'
})
export class WorkPackageStatusDropdownDirective extends OpContextMenuTrigger {
  @Input('wpStatusDropdown-workPackage') public workPackage:WorkPackageResource;

  constructor(readonly elementRef:ElementRef,
              readonly opContextMenu:OPContextMenuService,
              readonly $state:StateService,
              protected wpNotificationsService:WorkPackageNotificationService,
              protected notificationService:NotificationsService,
              @Inject(IWorkPackageEditingServiceToken) protected wpEditing:WorkPackageEditingService,
              protected I18n:I18nService,
              protected wpEvents:WorkPackageEventsService) {

    super(elementRef, opContextMenu);
  }

  protected open(evt:JQuery.TriggeredEvent) {
    const changeset = this.wpEditing.changesetFor(this.workPackage);

    changeset.getForm().then((form:any) => {
      const statuses = form.schema.status.allowedValues;
      this.buildItems(statuses);

      const writable = changeset.isWritable('status');
      if (!writable) {
        this.notificationService.addError(this.I18n.t('js.work_packages.message_work_package_status_blocked'));
      } else {
        this.opContextMenu.show(this, evt);
      }
    });
  }

  public get locals() {
    return {
      items: this.items,
      contextMenuId: 'wp-status-context-menu'
    };
  }

  private updateStatus(status:HalResource) {
    const changeset = this.wpEditing.changesetFor(this.workPackage);
    changeset.setValue('status', status);

    if (!this.workPackage.isNew) {
      changeset.save().then(() => {
        this.wpNotificationsService.showSave(this.workPackage);

        this.wpEvents.push({ type: 'updated', id: this.workPackage.id! });
      });
    }
  }

  private buildItems(statuses:CollectionResource<HalResource>) {
    this.items = statuses.map((status:HalResource) => {
      return {
        disabled: false,
        linkText: status.name,
        postIcon: status.isReadonly ? 'icon-locked' : null,
        postIconTitle: this.I18n.t('js.work_packages.message_work_package_read_only'),
        class: Highlighting.inlineClass('status', status.id!),
        onClick: () => {
          this.updateStatus(status);
          return true;
        }
      };
    });
  }
}


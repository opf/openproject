//-- copyright
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
//++

import {StateService} from '@uirouter/core';
import {OPContextMenuService} from "core-components/op-context-menu/op-context-menu.service";
import {Directive, ElementRef, Input} from "@angular/core";
import {OpContextMenuTrigger} from "core-components/op-context-menu/handlers/op-context-menu-trigger.directive";

import {HalResourceEditingService} from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {CollectionResource} from 'core-app/modules/hal/resources/collection-resource';
import {Highlighting} from "core-components/wp-fast-table/builders/highlighting/highlighting.functions";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {HalEventsService} from "core-app/modules/hal/services/hal-events.service";
import {WorkPackageNotificationService} from "core-app/modules/work_packages/notifications/work-package-notification.service";

@Directive({
  selector: '[wpStatusDropdown]'
})
export class WorkPackageStatusDropdownDirective extends OpContextMenuTrigger {
  @Input('wpStatusDropdown-workPackage') public workPackage:WorkPackageResource;

  constructor(readonly elementRef:ElementRef,
              readonly opContextMenu:OPContextMenuService,
              readonly $state:StateService,
              protected workPackageNotificationService:WorkPackageNotificationService,
              protected halEditing:HalResourceEditingService,
              protected notificationService:NotificationsService,
              protected I18n:I18nService,
              protected halEvents:HalEventsService) {

    super(elementRef, opContextMenu);
  }

  protected open(evt:JQuery.TriggeredEvent) {
    const change = this.halEditing.changeFor(this.workPackage);

    change.getForm().then((form:any) => {
      const statuses = form.schema.status.allowedValues;
      this.buildItems(statuses);

      const writable = change.schema.status.writable;
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
    const change = this.halEditing.changeFor(this.workPackage);
    change.projectedResource.status = status;

    if (!this.workPackage.isNew) {
      this.halEditing
        .save(change)
        .then(() => {
          this.workPackageNotificationService.showSave(this.workPackage);
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


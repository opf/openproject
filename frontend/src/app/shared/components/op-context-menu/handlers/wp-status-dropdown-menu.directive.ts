//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Directive, Input, inject } from '@angular/core';
import { OpActionMenuItems } from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu-items';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import {
  HalResourceEditingService,
} from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { StatusResource } from 'core-app/features/hal/resources/status-resource';
import {
  Highlighting,
} from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/highlighting.functions';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import {
  WorkPackageNotificationService,
} from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import { HalError } from 'core-app/features/hal/services/hal-error';
import { IOPFieldSchema } from 'core-app/features/hal/interfaces';

@Directive({
  // eslint-disable-next-line @angular-eslint/directive-selector
  selector: '[wpStatusDropdown]',
})
export class WorkPackageStatusDropdownDirective extends OpActionMenuItems {
  protected workPackageNotificationService = inject(WorkPackageNotificationService);
  protected halEditing = inject(HalResourceEditingService);
  protected toastService = inject(ToastService);
  protected I18n = inject(I18nService);

  // eslint-disable-next-line @angular-eslint/no-input-rename
  @Input('wpStatusDropdown-workPackage') public workPackage:WorkPackageResource;

  protected buildItems():Promise<OpContextMenuItem[]> {
    const change = this.halEditing.changeFor(this.workPackage);

    return change.getForm().then((form) => {
      const { writable } = change.schema.status as IOPFieldSchema;
      if (!writable) {
        this.toastService.addError(this.I18n.t('js.work_packages.message_work_package_status_blocked'));
        return [];
      }

      const statuses = form.schema.status!.allowedValues as HalResource[];
      return statuses.map((status) => this.buildItem(status));
    });
  }

  private buildItem(status:HalResource):OpContextMenuItem {
    const readonly = !!status.isReadonly;

    return {
      linkText: status.name,
      title: readonly ? this.I18n.t('js.work_packages.message_work_package_read_only') : undefined,
      ...(readonly
        ? { octicon: 'lock' as const, octiconClass: Highlighting.foregroundClass('status', status.id!) }
        : { labelClass: Highlighting.dotClass('status', status.id!) }),
      onClick: () => {
        this.updateStatus(status);
        return true;
      },
    };
  }

  private updateStatus(status:HalResource) {
    const change = this.halEditing.changeFor(this.workPackage);
    change.projectedResource.status = status as StatusResource;

    if (!isNewResource(this.workPackage)) {
      this.halEditing
        .save(change)
        .then(() => {
          this.workPackageNotificationService.showSave(this.workPackage);
        })
        .catch((e:unknown) => {
          this.workPackageNotificationService.showError((e as HalError).resource!, change.projectedResource);
        });
    }
  }
}

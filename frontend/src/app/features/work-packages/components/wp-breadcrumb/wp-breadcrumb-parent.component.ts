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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  Component, Input, EventEmitter, Output,
} from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageRelationsHierarchyService } from 'core-app/features/work-packages/components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';

@Component({
  templateUrl: './wp-breadcrumb-parent.html',
  selector: 'wp-breadcrumb-parent',
})
export class WorkPackageBreadcrumbParentComponent {
  @Input('workPackage') workPackage:WorkPackageResource;

  @Output('onSwitch') onSwitch = new EventEmitter<boolean>();

  public isSaving = false;

  public text = {
    edit_parent: this.I18n.t('js.relation_buttons.change_parent'),
    set_or_remove_parent: this.I18n.t('js.relations_autocomplete.parent_placeholder'),
    remove_parent: this.I18n.t('js.relation_buttons.remove_parent'),
    set_parent: this.I18n.t('js.relation_buttons.set_parent'),
  };

  private editing:boolean;

  public constructor(
    protected readonly I18n:I18nService,
    protected readonly wpRelationsHierarchy:WorkPackageRelationsHierarchyService,
    protected readonly notificationService:WorkPackageNotificationService,
  ) {
  }

  public canModifyParent():boolean {
    return !!this.workPackage.changeParent;
  }

  public get parent() {
    return this.workPackage && this.workPackage.parent;
  }

  public get active():boolean {
    return this.editing;
  }

  public close():void {
    this.toggle(false);
  }

  public open():void {
    this.toggle(true);
  }

  public updateParent(newParent:WorkPackageResource|null) {
    this.close();
    const newParentId = newParent ? newParent.id : null;
    if (_.get(this.parent, 'id', null) === newParentId) {
      return;
    }

    this.isSaving = true;
    this.wpRelationsHierarchy.changeParent(this.workPackage, newParentId)
      .catch((error:any) => {
        this.notificationService.handleRawError(error, this.workPackage);
      })
      .then(() => this.isSaving = false); // Behaves as .finally()
  }

  private toggle(state:boolean) {
    if (this.editing !== state) {
      this.editing = state;
      this.onSwitch.emit(this.editing);
    }
  }
}

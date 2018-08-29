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

import {Component, EventEmitter, Inject, Output} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {WorkPackageEditFieldGroupComponent} from "core-components/wp-edit/wp-edit-field/wp-edit-field-group.directive";

@Component({
  templateUrl: './wp-edit-actions-bar.html',
  selector: 'wp-edit-actions-bar',
})
export class WorkPackageEditActionsBarComponent {
  @Output('onSave') public onSave = new EventEmitter<void>();
  @Output('onCancel') public onCancel = new EventEmitter<void>();
  public saving:boolean = false;

  public text = {
    save: this.I18n.t('js.button_save'),
    cancel: this.I18n.t('js.button_cancel')
  };

  constructor(readonly I18n:I18nService,
              readonly wpEditFieldGroup:WorkPackageEditFieldGroupComponent) {
  }

  public save():void {
    if (this.saving) {
      return;
    }

    this.saving = true;
    this.wpEditFieldGroup
      .saveWorkPackage()
      .then(() => {
        this.saving = false;
        this.onSave.emit();
      })
      .catch(() => {
        this.saving = false;
      });
  }

  public cancel():void {
    this.wpEditFieldGroup.stop();
    this.onCancel.emit();
  }
}

//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Output } from '@angular/core';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { EditFormComponent } from "core-app/modules/fields/edit/edit-form/edit-form.component";

@Component({
  templateUrl: './wp-edit-actions-bar.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'wp-edit-actions-bar',
})
export class WorkPackageEditActionsBarComponent {
  @Output('onSave') public onSave = new EventEmitter<void>();
  @Output('onCancel') public onCancel = new EventEmitter<void>();
  public _saving = false;

  public text = {
    save: this.I18n.t('js.button_save'),
    cancel: this.I18n.t('js.button_cancel')
  };

  constructor(private I18n:I18nService,
              private editForm:EditFormComponent,
              private cdRef:ChangeDetectorRef) {
  }

  public set saving(active:boolean) {
    this._saving = active;
    this.cdRef.detectChanges();
  }

  public get saving() {
    return this._saving;
  }

  public save():void {
    if (this.saving) {
      return;
    }

    this.saving = true;
    this.editForm
      .submit()
      .then(() => {
        this.saving = false;
        this.onSave.emit();
      })
      .catch(() => {
        this.saving = false;
      });
  }

  public cancel():void {
    this.editForm.cancel();
    this.onCancel.emit();
  }
}

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

import {
  ChangeDetectorRef, Component, DoCheck, EventEmitter, Input, Output, inject,
} from '@angular/core';

export interface EditFieldControl {
  required:boolean;
  isEmpty?():boolean;
}

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'edit-field-controls',
  templateUrl: './edit-field-controls.component.html',
  standalone: false,
})
export class EditFieldControlsComponent implements DoCheck {
  private readonly cdRef = inject(ChangeDetectorRef);

  @Input() public cancelTitle:string;

  @Input() public saveTitle:string;

  // eslint-disable-next-line @angular-eslint/no-input-rename
  @Input('fieldController') public field:EditFieldControl;

  // eslint-disable-next-line @angular-eslint/no-output-on-prefix
  @Output() public onSave = new EventEmitter<void>();

  // eslint-disable-next-line @angular-eslint/no-output-on-prefix
  @Output() public onCancel = new EventEmitter<void>();

  protected saveDisabled = false;

  ngDoCheck():void {
    const saveDisabled = this.field.required && (this.field.isEmpty?.() ?? true);
    if (saveDisabled !== this.saveDisabled) {
      this.saveDisabled = saveDisabled;
      this.cdRef.markForCheck();
    }
  }

  public save() {
    this.onSave.emit();
  }

  public cancel() {
    this.onCancel.emit();
  }
}

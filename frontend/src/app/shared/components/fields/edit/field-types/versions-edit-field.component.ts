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

import { ChangeDetectionStrategy, Component } from '@angular/core';
import {
  MultiSelectEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/multi-select-edit-field.component';
import { ValueOption } from 'core-app/shared/components/fields/edit/field-types/select-edit-field/select-edit-field.component';

/**
 * Edit field for the targetVersions attribute of work packages.
 *
 * The attribute always reads and writes a collection, but as long as the
 * multiple versions setting is inactive, the schema restricts it to a single
 * value (options.multiple). In that mode the field mimics the single select
 * fields it stands in for: no save/cancel controls, saving right on selection.
 */
@Component({
  templateUrl: './versions-edit-field.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class VersionsEditFieldComponent extends MultiSelectEditFieldComponent {
  /** Whether the schema allows assigning more than one version. */
  public get allowMultiple():boolean {
    return (this.schema.options as { multiple?:boolean }|undefined)?.multiple !== false;
  }

  /**
   * The ng-select model: the selected options in multiple mode,
   * the single selected option (or null) otherwise.
   */
  public get model():ValueOption[]|ValueOption|null {
    if (this.allowMultiple) {
      return this.selectedOption;
    }

    return this.selectedOption[0] ?? null;
  }

  public set model(val:ValueOption[]|ValueOption|null) {
    this.selectedOption = val == null ? [] : [val].flat();
  }

  /**
   * In single value mode the field saves right after selection, mirroring the
   * behavior of the single select edit fields it stands in for.
   */
  public onSelectionChange():void {
    if (!this.allowMultiple) {
      void this.handler.handleUserSubmit();
    }
  }
}

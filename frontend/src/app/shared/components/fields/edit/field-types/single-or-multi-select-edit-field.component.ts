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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  MultiSelectEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/multi-select-edit-field.component';
import { ValueOption } from 'core-app/shared/components/fields/edit/field-types/select-edit-field/select-edit-field.component';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

/**
 * Base for edit fields whose attribute always reads and writes a collection but
 * whose schema may restrict it to a single value (options.multiple) — which the
 * attributes replacing a deprecated single-valued one do as long as their feature
 * is inactive.
 *
 * In single value mode the field mimics the single select field it stands in for:
 * an explicit "-" option, no save/cancel controls, saving right on selection.
 *
 * Subclasses supply the template.
 */
export class SingleOrMultiSelectEditFieldComponent extends MultiSelectEditFieldComponent {
  private noValueOption:ValueOption = { name: this.text.placeholder, href: null };

  /** Whether the schema allows assigning more than one value. */
  public get allowMultiple():boolean {
    return (this.schema.options as { multiple?:boolean }|undefined)?.multiple !== false;
  }

  /** Memoized options of the selectableOptions getter, keyed by the array they were built from. */
  private selectableOptionsSource:unknown = null;

  private selectableOptionsBuilt:ValueOption[] = [];

  /**
   * The selectable options, extended by an explicit "-" option to unset
   * the value in single value mode (mirroring the single select fields).
   *
   * The getter is bound in the template, so it must return a stable array
   * reference while the available options stay the same — a fresh array per
   * change detection cycle would make ng-select reprocess the whole list on
   * every tick.
   */
  public get selectableOptions():HalResource[]|ValueOption[] {
    if (this.allowMultiple || this.required) {
      return this.availableOptions as HalResource[];
    }

    if (this.selectableOptionsSource !== this.availableOptions) {
      this.selectableOptionsSource = this.availableOptions;
      this.selectableOptionsBuilt = [this.noValueOption, ...(this.availableOptions as ValueOption[])];
    }

    return this.selectableOptionsBuilt;
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
    const values = val == null ? [] : [val].flat();
    // Selecting the "-" option unsets the value.
    this.selectedOption = values.filter((option) => option.href != null);
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

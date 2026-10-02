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

import { ChangeDetectionStrategy, Component } from '@angular/core';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import {
  InlineOptionsEditFieldDirective,
} from 'core-app/shared/components/fields/edit/field-types/inline-options-edit-field/inline-options-edit-field.directive';

@Component({
  templateUrl: './checkboxes-edit-field.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class CheckboxesEditFieldComponent extends InlineOptionsEditFieldDirective {
  public isChecked(option:HalResource):boolean {
    return this.selected.some((value) => value.href === option.href);
  }

  public toggle(option:HalResource, checked:boolean):void {
    this.values[this.name] = this.availableOptions.filter((candidate) => {
      if (candidate.href === option.href) {
        return checked;
      }

      return this.isChecked(candidate);
    });
  }

  private get selected():HalResource[] {
    const current = this.values[this.name] as HalResource[]|null|undefined;

    return (current ?? []).filter((value) => !!value?.href);
  }
}

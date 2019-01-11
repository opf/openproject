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

import {Component} from "@angular/core";
import {HalResourceSortingService} from "core-app/modules/hal/services/hal-resource-sorting.service";
import {CollectionResource} from "core-app/modules/hal/resources/collection-resource";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {EditFieldComponent} from "../edit-field.component";
import {AngularTrackingHelpers} from "core-components/angular/tracking-functions";

export interface ValueOption {
  name:string;
  $href:string | null;
}

@Component({
  templateUrl: './select-edit-field.component.html'
})
export class SelectEditFieldComponent extends EditFieldComponent {
  public options:any[];
  public valueOptions:ValueOption[];
  public template:string = '/components/wp-edit/field-types/wp-edit-select-field.directive.html';
  public text:{ requiredPlaceholder:string, placeholder:string };

  public halSorting:HalResourceSortingService;

  protected initialize() {
    this.halSorting = this.injector.get(HalResourceSortingService);

    this.text = {
      requiredPlaceholder: this.I18n.t('js.placeholders.selection'),
      placeholder: this.I18n.t('js.placeholders.default')
    };

    if (Array.isArray(this.schema.allowedValues)) {
      this.setValues(this.schema.allowedValues);
    } else if (this.schema.allowedValues) {
      this.schema.allowedValues.$load().then((values:CollectionResource) => {
        this.setValues(values.elements);
      });
    } else {
      this.setValues([]);
    }
  }

  public get selectedOption() {
    const href = this.value ? this.value.$href : null;
    return _.find(this.valueOptions, o => o.$href === href)!;
  }

  public set selectedOption(val:ValueOption) {
    let option = _.find(this.options, o => o.$href === val.$href);

    // Special case 'null' value, which angular
    // only understands in ng-options as an empty string.
    if (option && option.$href === '') {
      option.$href = null;
    }

    this.value = option;
  }

  private setValues(availableValues:HalResource[]) {
    this.options = this.halSorting.sort(availableValues);
    this.addEmptyOption();
    this.valueOptions = this.options.map(el => {
      return {name: el.name, $href: el.$href};
    });
  }

  public get currentValueInvalid():boolean {
    return !!(
      (this.value && !_.some(this.options, (option:HalResource) => (option.$href === this.value.$href)))
      ||
      (!this.value && this.schema.required)
    );
  }

  private addEmptyOption() {
    // Empty options are not available for required fields
    if (this.schema.required) {
      return;
    }

    // Since we use the original schema values, avoid adding
    // the option if one is returned / exists already.
    const emptyOption = _.find(this.options, el => el.name === this.text.placeholder);
    if (emptyOption === undefined) {
      this.options.unshift({
        name: this.text.placeholder,
        $href: ''
      });
    }
  }
}

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

import {CollectionResource} from 'core-app/modules/hal/resources/collection-resource';
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {Component, OnInit} from "@angular/core";
import {EditFieldComponent} from "core-app/modules/fields/edit/edit-field.component";
import {ValueOption} from "core-app/modules/fields/edit/field-types/select-edit-field.component";

@Component({
  templateUrl: './multi-select-edit-field.component.html'
})
export class MultiSelectEditFieldComponent extends EditFieldComponent implements OnInit {
  readonly I18n:I18nService = this.injector.get(I18nService);
  public options:any[];
  public valueOptions:ValueOption[];
  public text = {
    requiredPlaceholder: this.I18n.t('js.placeholders.selection'),
    placeholder: this.I18n.t('js.placeholders.default'),
    save: this.I18n.t('js.inplace.button_save', { attribute: this.schema.name }),
    cancel: this.I18n.t('js.inplace.button_cancel', { attribute: this.schema.name }),
    switch_to_single_select: this.I18n.t('js.work_packages.label_switch_to_single_select'),
    switch_to_multi_select: this.I18n.t('js.work_packages.label_switch_to_multi_select'),
  };
  public isMultiselect:boolean;

  public currentValueInvalid:boolean = false;
  private nullOption:ValueOption;
  private _selectedOption:ValueOption|ValueOption[];

  ngOnInit() {
    this.isMultiselect = this.isValueMulti();

    this.nullOption = { name: this.text.placeholder, $href: null };

    if (Array.isArray(this.schema.allowedValues)) {
      this.setValues(this.schema.allowedValues);
    } else if (this.schema.allowedValues) {
      this.schema.allowedValues.$load().then((values:CollectionResource) => {
        // The select options of the project shall be sorted
        if (values.count > 0 && (values.elements[0] as any)._type === 'Project') {
          this.setValues(values.elements, true);
        } else {
          this.setValues(values.elements);
        }
      });
    } else {
      this.setValues([]);
    }
  }

  public get value() {
    const val = this.changeset.value(this.name);

    if (!Array.isArray(val) || this.isMultiselect) {
      return val;
    } else {
      return val[0];
    }
  }

  /**
   * Map the selected hal resource(s) to the value options so that ngOptions will track them.
   * We cannot pass the HalResources themselves as angular will copy them on every digest due to trackBy
   * @returns {any}
   */
  public buildSelectedOption() {
    const value:HalResource|HalResource[] = this.changeset.value(this.name);

    if (this.isMultiselect) {
      if (!Array.isArray(value)) {
        return [this.findValueOption(value)];
      }

      return value.map(val => this.findValueOption(val));
    }

    if (!Array.isArray(value)) {
      return this.findValueOption(value);
    } else if (value.length > 0) {
      return this.findValueOption(value[0]);
    }

    return this.nullOption;
  }

  public get selectedOption() {
    return this._selectedOption;
  }

  /**
   * Map the ValueOption to the actual HalResource option
   * @param val
   */
  public set selectedOption(val:ValueOption|ValueOption[]) {
    this._selectedOption = val;
    let selected:any;
    let mapper = (val:ValueOption) => {
      let option = _.find(this.options, o => o.$href === val.$href) || this.nullOption;

      // Special case 'null' value, which angular
      // only understands in ng-options as an empty string.
      if (option && option.$href === '') {
        option.$href = null;
      }

      return option;
    };

    const value = _.castArray(val).map(el => mapper(el));
    this.changeset.setValue(this.name, value);
  }

  public isValueMulti() {
    const val = this.changeset.value(this.name);
    return val && val.length > 1;
  }

  public toggleMultiselect() {
    this.isMultiselect = !this.isMultiselect;
    this._selectedOption = this.buildSelectedOption();
  }

  public submitOnSingleSelect() {
    if (!this.isMultiselect) {
      this.handler.handleUserSubmit();
    }
  }

  private findValueOption(option?:HalResource):ValueOption {
    let result;

    if (option) {
      result = _.find(this.valueOptions, (valueOption) => valueOption.$href === option.$href)!;
    }

    return result || this.nullOption;
  }

  private setValues(availableValues:any[], sortValuesByName:boolean = false) {
    if (sortValuesByName) {
      availableValues.sort(function (a:any, b:any) {
        var nameA = a.name.toLowerCase();
        var nameB = b.name.toLowerCase();
        return nameA < nameB ? -1 : nameA > nameB ? 1 : 0;
      });
    }

    this.options = availableValues;
    this.addEmptyOption();
    this.valueOptions = this.options.map(el => {
      return { name: el.name, $href: el.$href };
    });
    this._selectedOption = this.buildSelectedOption();
    this.checkCurrentValueValidity();
  }

  private checkCurrentValueValidity() {
    if (this.value) {
      this.currentValueInvalid = !!(
        // (If value AND)
        // MultiSelect AND there is no value which href is not in the options hrefs OR
        // SingleSelect AND the given values href is not within the options hrefs
        (this.isMultiselect && !_.some(this.value, (value:HalResource) => {
          return _.some(this.options, (option) => (option.$href === value.$href))
        })) ||
        (!this.isMultiselect && !_.some(this.options,
          (option) => (option.$href === this.value.$href)))
      );
    }
    else {
      // If no value but required
      this.currentValueInvalid = !!this.schema.required;
    }
  }

  private addEmptyOption() {
    // Empty options are not available for required fields
    if (this.schema.required) {
      return;
    }

    // Since we use the original schema values, avoid adding
    // the option if one is returned / exists already.
    const emptyOption = _.find(this.options, { name: this.text.placeholder });
    if (emptyOption === undefined) {
      this.options.unshift(this.nullOption);
    }
  }
}

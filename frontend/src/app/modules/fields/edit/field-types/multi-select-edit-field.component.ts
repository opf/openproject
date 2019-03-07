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
import {NgSelectComponent} from "@ng-select/ng-select";
import {ViewChild} from "@angular/core";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";

@Component({
  templateUrl: './multi-select-edit-field.component.html'
})
export class MultiSelectEditFieldComponent extends EditFieldComponent implements OnInit {
  @ViewChild(NgSelectComponent) public ngSelectComponent:NgSelectComponent;

  readonly I18n:I18nService = this.injector.get(I18nService);
  public options:any[];
  public valueOptions:ValueOption[];
  public text = {
    requiredPlaceholder: this.I18n.t('js.placeholders.selection'),
    placeholder: this.I18n.t('js.placeholders.default'),
    save: this.I18n.t('js.inplace.button_save', { attribute: this.schema.name }),
    cancel: this.I18n.t('js.inplace.button_cancel', { attribute: this.schema.name }),
  };

  public appendTo:any = null;
  private hiddenOverflowContainer = '.__hidden_overflow_container';

  public currentValueInvalid:boolean = false;
  private nullOption:ValueOption;
  private _selectedOption:ValueOption[];

  ngOnInit() {
    this.nullOption = { name: this.text.placeholder, $href: null };

    const loadingPromise = this.loadValues();
    this.handler
      .$onUserActivate
      .pipe(
        untilComponentDestroyed(this),
      )
      .subscribe(() => {
        loadingPromise.then(() => this.openAutocompleteSelectField())
      });

    super.ngOnInit();
    this.appendTo = this.overflowingSelector;
  }

  public get value() {
    const val = this.changeset.value(this.name);
    return val[0];
  }

  /**
   * Map the selected hal resource(s) to the value options so that ngOptions will track them.
   * We cannot pass the HalResources themselves as angular will copy them on every digest due to trackBy
   * @returns {any}
   */
  public buildSelectedOption() {
    const value:HalResource[] = this.changeset.value(this.name);
    return value.map(val => this.findValueOption(val));
  }

  public get selectedOption() {
    return this._selectedOption;
  }

  /**
   * Map the ValueOption to the actual HalResource option
   * @param val
   */
  public set selectedOption(val:ValueOption[]) {
    this._selectedOption = val;
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

  public onOpen() {
    jQuery(this.hiddenOverflowContainer).addClass('-hidden-overflow');
  }

  public onClose() {
    jQuery(this.hiddenOverflowContainer).removeClass('-hidden-overflow');
  }

  private openAutocompleteSelectField() {
    // The timeout takes care that the opening is added to the end of the current call stack.
    // Thus we can be sure that the autocompleter is rendered and ready to be opened.
    let that = this;
    window.setTimeout(function () {
      that.ngSelectComponent.open();
    }, 0);
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
    this.valueOptions = this.options.map(el => {
      return { name: el.name, $href: el.$href };
    });
    this._selectedOption = this.buildSelectedOption();
    this.checkCurrentValueValidity();
  }

  private loadValues() {
    let allowedValues = this.schema.allowedValues;
    if (Array.isArray(allowedValues)) {
      this.setValues(allowedValues);
    } else if (this.schema.allowedValues) {
      return this.schema.allowedValues.$load().then((values:CollectionResource) => {
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
    return Promise.resolve();
  }

  private checkCurrentValueValidity() {
    if (this.value) {
      this.currentValueInvalid = !!(
        // (If value AND)
        // MultiSelect AND there is no value which href is not in the options hrefs
        (!_.some(this.value, (value:HalResource) => {
          return _.some(this.options, (option) => (option.$href === value.$href))
        }))
      );
    }
    else {
      // If no value but required
      this.currentValueInvalid = !!this.schema.required;
    }
  }
}

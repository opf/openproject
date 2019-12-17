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

import {Component, OnInit, ViewChild} from "@angular/core";
import {HalResourceSortingService} from "core-app/modules/hal/services/hal-resource-sorting.service";
import {CollectionResource} from "core-app/modules/hal/resources/collection-resource";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {EditFieldComponent} from "../edit-field.component";
import {AngularTrackingHelpers} from "core-components/angular/tracking-functions";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {NgSelectComponent} from "@ng-select/ng-select";
import {CreateAutocompleterComponent} from "core-app/modules/common/autocomplete/create-autocompleter.component";
import {SelectAutocompleterRegisterService} from "app/modules/fields/edit/field-types/select-autocompleter-register.service";

export interface ValueOption {
  name:string;
  $href:string|null;
}

@Component({
  templateUrl: './select-edit-field.component.html'
})
export class SelectEditFieldComponent extends EditFieldComponent implements OnInit {
  public selectAutocompleterRegister = this.injector.get(SelectAutocompleterRegisterService);

  public availableOptions:any[];
  public valueOptions:ValueOption[];
  public text:{ requiredPlaceholder:string, placeholder:string };

  public appendTo:any = null;
  private hiddenOverflowContainer = '.__hidden_overflow_container';

  public halSorting:HalResourceSortingService;

  private _autocompleterComponent:CreateAutocompleterComponent;

  public referenceOutputs = {
    onCreate: (newElement:HalResource) => this.onCreate(newElement),
    onChange: (value:HalResource) => this.onChange(value),
    onKeydown: (event:JQuery.TriggeredEvent) => this.handler.handleUserKeydown(event, true),
    onOpen: () => this.onOpen(),
    onClose: () => this.onClose(),
    onAfterViewInit: (component:CreateAutocompleterComponent) => this._autocompleterComponent = component
  };

  protected initialize() {
    this.halSorting = this.injector.get(HalResourceSortingService);
    this.text = {
      requiredPlaceholder: this.I18n.t('js.placeholders.selection'),
      placeholder: this.I18n.t('js.placeholders.default')
    };

    const loadingPromise = this.loadValues();
    this.handler
      .$onUserActivate
      .pipe(
        untilComponentDestroyed(this)
      )
      .subscribe(() => {
        loadingPromise.then(() => {
          this._autocompleterComponent.openDirectly = true;
        });
      });
  }

  public autocompleterComponent() {
    let type = this.schema.type;
    return this.selectAutocompleterRegister.getAutocompleterOfAttribute(type) || CreateAutocompleterComponent;
  }

  public ngOnInit() {
    super.ngOnInit();
    this.appendTo = this.overflowingSelector;
  }

  public get selectedOption() {
    const href = this.value ? this.value.$href : null;
    return _.find(this.valueOptions, o => o.$href === href)!;
  }

  public set selectedOption(val:ValueOption) {
    let option = _.find(this.availableOptions, o => o.$href === val.$href);

    // Special case 'null' value, which angular
    // only understands in ng-options as an empty string.
    if (option && option.$href === '') {
      option.$href = null;
    }

    this.value = option;
  }

  private setValues(availableValues:HalResource[]) {
    this.availableOptions = this.halSorting.sort(availableValues);
    this.addEmptyOption();
    this.valueOptions = this.availableOptions.map(el => {
      return {name: el.name, $href: el.$href};
    });
  }

  private loadValues() {
    let allowedValues = this.schema.allowedValues;
    if (Array.isArray(allowedValues)) {
      this.setValues(allowedValues);
    } else if (allowedValues) {
      return allowedValues.$load(false).then((values:CollectionResource) => {
        this.setValues(values.elements);
      });
    } else {
      this.setValues([]);
    }
    return Promise.resolve();
  }

  private addValue(val:HalResource) {
    this.availableOptions.push(val);
    this.valueOptions.push({name: val.name, $href: val.$href});
  }

  public get currentValueInvalid():boolean {
    return !!(
      (this.value && !_.some(this.availableOptions, (option:HalResource) => (option.$href === this.value.$href)))
      ||
      (!this.value && this.schema.required)
    );
  }

  public onCreate(newElement:HalResource) {
    this.addValue(newElement);
    this.selectedOption = {name: newElement.name, $href: newElement.$href};
    this.handler.handleUserSubmit();
  }

  public onOpen() {
    jQuery(this.hiddenOverflowContainer).one('scroll', () => {
      this._autocompleterComponent.closeSelect();
    });
  }

  public onClose() {
    // Nothing to do
  }

  public onChange(value:HalResource|undefined) {
    if (value !== undefined) {
      this.selectedOption = {name: value.name, $href: value.$href};
      this.handler.handleUserSubmit();
      return;
    }

    const emptyOption = this.getEmptyOption();

    if (emptyOption) {
      this.selectedOption = emptyOption;
      this.handler.handleUserSubmit();
    }
  }

  private addEmptyOption() {
    // Empty options are not available for required fields
    if (this.schema.required) {
      return;
    }

    // Since we use the original schema values, avoid adding
    // the option if one is returned / exists already.
    const emptyOption = this.getEmptyOption();
    if (emptyOption === undefined) {
      this.availableOptions.unshift({
        name: this.text.placeholder,
        $href: ''
      });
    }
  }

  private getEmptyOption():ValueOption|undefined {
    return _.find(this.availableOptions, el => el.name === this.text.placeholder);
  }
}

//-- copyright
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
//++


import {filtersModule} from '../../../angular-modules';
filtersModule.directive('toggledMultiselect', toggledMultiselect);

export class ToggledMultiselectController {
  public isMultiselect: boolean;

  // The current filter object
  public filter:{name: string, values: any};
  public availableOptions:any;
  public disabled:boolean;

  public text:{ [key: string]: string; };

  constructor(public $scope, public I18n:op.I18n) {
    this.isMultiselect = this.isValueMulti();

    // We need to extract a value returned from filter query
    // if we are single select
    if (this.isArray && this.value.length === 1) {
      this.value = this.value[0];
    }

    this.text = {
      enableMulti: I18n.t('js.work_packages.label_enable_multi_select'),
      disableMulti: I18n.t('js.work_packages.label_disable_multi_select'),
    };
  }

  /**
   * The filter values we receive from the API are correctly typed
   * (e.g., User ID number:1).
   *
   * Values from the query props however are returned as string.
   * Prior to Angular 1.4., this check was identical but now we compare strings explicitly.
   */
  public filterValue(val) {
    if (val == null) {
      return val;
    }

    return val.toString();
  }

  public get value() {
    return this.filter.values;
  }

  public set value(val) {
    this.filter.values = val;
  }

  public get isArray() {
    return Array.isArray(this.value);
  }

  public isValueMulti() {
    return this.isArray && this.value.length > 1;
  }

  public toggleMultiselect() {
    if (this.isMultiselect) {
      this.switchToSingleSelect();
    } else {
      this.switchToMultiSelect();
    }

    this.isMultiselect = !this.isMultiselect;
  };

  private switchToMultiSelect() {
    if (!this.isArray) {
      this.value = [this.value];
    }
  }

  private switchToSingleSelect() {
    if (this.isArray) {
      this.value = this.value[0];
    }
  }

}

function toggledMultiselect() {
  return {
    restrict: 'EA',
    replace: true,
    scope: {
      name: '=',
      filter: '=',
      availableOptions: '=',
      disabled: '=isDisabled'
    },
    templateUrl: '/components/filters/toggled-multiselect/toggled_multiselect.html',
    controller: ToggledMultiselectController,
    bindToController: true,
    controllerAs: '$ctrl'
  };
};

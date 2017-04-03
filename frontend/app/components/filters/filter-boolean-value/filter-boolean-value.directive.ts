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
import {QueryFilterInstanceResource} from '../../api/api-v3/hal-resources/query-filter-instance-resource.service';

export class BooleanValueController {
  public filter:QueryFilterInstanceResource;

  public text:{ [key: string]: string; };

  constructor(public $scope:ng.IScope,
              private I18n:op.I18n) {
    this.text = {
      placeholder: I18n.t('js.placeholders.selection'),
      true: I18n.t('js.general_text_Yes'),
      false: I18n.t('js.general_text_No')
    };
  }

  public get value() {
    return this.filter.values[0];
  }

  public set value(val) {
    this.filter.values[0] = val;
  }

  public get hasNoValue() {
    return _.isEmpty(this.filter.values);
  }

  public get availableOptions() {
    return [true, false];
  }
}

function booleanValue() {
  return {
    restrict: 'E',
    replace: true,
    scope: {
      filter: '=',
    },
    templateUrl: '/components/filters/filter-boolean-value/filter-boolean-value.directive.html',
    controller: BooleanValueController,
    bindToController: true,
    controllerAs: '$ctrl'
  };
};

filtersModule.directive('filterBooleanValue', booleanValue);

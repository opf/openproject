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

// TODO we still have non-upgraded components depending on the ng1 datepicker
// Remove when this is no longer the case and migrate to the ng2 component instead.

import {DatePicker} from 'core-components/wp-edit/op-date-picker/datepicker';

class OPDatePickerController {
  public onChange?:Function;
  public onClose?:Function;
  public initialDate?:String;

  private datePickerInstance:any;
  private input:JQuery;

  public constructor(private $element:ng.IAugmentedJQuery,
                     private ConfigurationService:any,
                     private TimezoneService:any) {
    'ngInject';
  }


  public $onInit() {
    // Added for compatibility
  }

  public $postLink() {
    // we don't want the date picker in the accessibility mode
    if (!this.ConfigurationService.accessibilityModeEnabled()) {
      this.input = this.$element.find('input');
      this.setup();
    }
  }

  public setup() {
    this.input.focus(() => this.showDatePicker());
    this.input.keydown((event) => {
      if (this.isEmpty()) {
        this.datePickerInstance.clear();
      }
    });
  }

  private isEmpty():boolean {
    return this.currentValue().trim() === '';
  }

  private currentValue() {
    return this.input.val();
  }

  private callbackIfSet(name:'onChange' | 'onClose') {
    if (this[name]) {
      this[name]!.bind(this).call();
    }
  }

  private showDatePicker() {
    let options:any = {
      onSelect: (date:any) => {
        this.datePickerInstance.hide();

        let val = date;

        if (this.isEmpty()) {
          val = null;
        }

        this.input.val(val);
        this.input.change();
        this.callbackIfSet('onChange');
      },
      onClose: () => this.callbackIfSet('onClose')
    };

    let initialValue;
    if (this.isEmpty && this.initialDate) {
      initialValue = this.TimezoneService.parseISODate(this.initialDate).toDate();
    } else {
      initialValue = this.currentValue();
    }

    this.datePickerInstance = new DatePicker(
      this.ConfigurationService,
      this.TimezoneService,
      this.input,
      initialValue,
      options
    );
    this.datePickerInstance.show();
  }
}

angular
  .module('openproject')
  .component('opDatePicker', {
    templateUrl: '/components/wp-edit/op-date-picker/op-date-picker.directive.html',
    transclude: true,
    controller: OPDatePickerController,
    bindings: {
      initialDate: '@?',
      onChange: '&?',
      onClose: '&?',
    }
  });

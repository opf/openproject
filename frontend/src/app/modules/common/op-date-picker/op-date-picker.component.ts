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

import {Component, ElementRef, EventEmitter, Inject, Input, OnDestroy, OnInit, Output} from '@angular/core';
import {ConfigurationService} from 'core-app/modules/common/config/configuration.service';
import {DatePicker} from 'core-app/modules/common/op-date-picker/datepicker';
import {TimezoneService} from 'core-components/datetime/timezone.service';

@Component({
  selector: 'op-date-picker',
  templateUrl: './op-date-picker.component.html'
})
export class OpDatePickerComponent implements OnInit, OnDestroy {
  @Output() public onChange = new EventEmitter<string>();
  @Output() public onClose = new EventEmitter<string>();
  @Input() public initialDate?:string;

  private $element:JQuery;
  private datePickerInstance:DatePicker;
  private input:JQuery;

  public constructor(private elementRef:ElementRef,
                     private ConfigurationService:ConfigurationService,
                     private timezoneService:TimezoneService) {
  }


  ngOnInit() {
    this.$element = jQuery(this.elementRef.nativeElement);

    this.input = this.$element.find('input');
    this.setup();
  }

  ngOnDestroy() {
    this.datePickerInstance && this.datePickerInstance.destroy();
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

  private currentValue():string {
    return this.input.val() as string;
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
        this.input.trigger('change');
        this.onChange.emit(val);
      },
      onClose: () => this.onClose.emit()
    };

    let initialValue;
    if (this.isEmpty && this.initialDate) {
      initialValue = this.timezoneService.parseISODate(this.initialDate).toDate();
    } else {
      initialValue = this.currentValue();
    }

    this.datePickerInstance = new DatePicker(
      this.ConfigurationService,
      this.timezoneService,
      this.input,
      initialValue,
      options
    );

    this.datePickerInstance.show();
  }
}

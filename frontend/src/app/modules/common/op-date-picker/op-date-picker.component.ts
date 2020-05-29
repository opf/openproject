// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {AfterViewInit, Component, ElementRef, EventEmitter, Input, OnDestroy, OnInit, Output} from '@angular/core';
import {ConfigurationService} from 'core-app/modules/common/config/configuration.service';
import {TimezoneService} from 'core-components/datetime/timezone.service';
import flatpickr from "flatpickr";
import {Instance} from "flatpickr/dist/types/instance";

@Component({
  selector: 'op-date-picker',
  templateUrl: './op-date-picker.component.html'
})
export class OpDatePickerComponent implements OnInit, OnDestroy, AfterViewInit {
  @Output() public onChange = new EventEmitter<string>();
  @Output() public onInputChange = new EventEmitter<string>();
  @Output() public onClose = new EventEmitter<string>();

  @Input() public initialDate:string = '';
  @Input() public appendTo?:HTMLElement = document.body;
  @Input() public classes:string = '';
  @Input() public id:string = '';
  @Input() public name:string = '';
  @Input() public required:boolean = false;
  @Input() public size:number = 20;
  @Input() public focus:boolean = false;

  private $element:JQuery;
  private datePickerInstance:Instance;
  private input:JQuery;

  public constructor(private elementRef:ElementRef,
                     private ConfigurationService:ConfigurationService,
                     private timezoneService:TimezoneService) {
    if (!this.id) {
      this.id = 'datepicker-input-' + Math.floor(Math.random() * 1000).toString(3);
    }
  }


  ngOnInit() {
    this.$element = jQuery(this.elementRef.nativeElement);

    this.input = this.$element.find('input');
    this.input.on('change', () => this.onInputChange.emit(this.currentValue()));

    this.setup();
  }

  ngAfterViewInit():void {
    this.initializeDatepicker();
  }

  ngOnDestroy() {
    this.datePickerInstance && this.datePickerInstance.destroy();
  }

  public setup() {
    this.input.click(() => this.datePickerInstance.open());
    this.input.blur(() => this.datePickerInstance.close());
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
  
  private initializeDatepicker() {
    let initialValue;
    if (this.isEmpty && this.initialDate) {
      initialValue = this.timezoneService.parseISODate(this.initialDate).toDate();
    } else {
      initialValue = this.currentValue();
    }

    var datePickerInstances = flatpickr('#' + this.id, {
      allowInput: true,
      appendTo: this.appendTo,
      defaultDate: initialValue,
      onChange:(selectedDates, dateStr) => {
        let val:string = dateStr;

        if (this.isEmpty()) {
          val = '';
        }

        this.input.val(val);
        this.input.trigger('change');
        this.onChange.emit(val);
      },
      onClose: () => this.onClose.emit()
    });

    this.datePickerInstance = Array.isArray(datePickerInstances)? datePickerInstances[0] : datePickerInstances;
  }
}

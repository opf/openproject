import { Component, ElementRef, forwardRef, OnInit } from '@angular/core';
import { OpDatePickerComponent } from "core-app/modules/common/op-date-picker/op-date-picker.component";
import { TimezoneService } from "core-components/datetime/timezone.service";
import { ConfigurationService } from 'core-app/modules/common/config/configuration.service';
import * as moment from "moment";
import { NG_VALUE_ACCESSOR } from "@angular/forms";

@Component({
  selector: 'op-date-picker-adapter',
  templateUrl: '../../../../../../op-date-picker/op-date-picker.component.html',
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => DatePickerAdapterComponent),
      multi: true
    }
  ]
})
export class DatePickerAdapterComponent extends OpDatePickerComponent implements OnInit {
  onControlChange = (_:any) => { }
  onControlTouch = () => { }

  constructor(
    elementRef:ElementRef,
    configurationService:ConfigurationService,
    timezoneService:TimezoneService,
    private _timezoneService:TimezoneService,
  ) {
    super(elementRef, configurationService, timezoneService);
  }

  writeValue(date:string):void {
    this.initialDate = this.formatter(date);
  }

  registerOnChange(fn: (_: any) => void): void {
    this.onControlChange = fn;
  }

  registerOnTouched(fn: any): void {
    this.onControlTouch = fn;
  }

  setDisabledState(disabled: boolean): void {
    this.disabled = disabled;
  }

  onInputChange(_event:KeyboardEvent) {
    if (this.isEmpty()) {
      this.datePickerInstance.clear();
    } else if (this.inputIsValidDate()) {
      const valueToEmit = this.parser(this.currentValue);
      this.onControlTouch();
      this.onControlChange(valueToEmit);
    }
  }

  closeOnOutsideClick(event:any) {
    super.closeOnOutsideClick(event);
    this.onControlTouch();
  }

  ngOnInit(): void {
  }

  public parser(data:any) {
    if (moment(data, 'YYYY-MM-DD', true).isValid()) {
      return data;
    } else {
      return null;
    }
  }

  public formatter(data:any):string {
    if (moment(data, 'YYYY-MM-DD', true).isValid()) {
      var d = this._timezoneService.parseDate(data);
      return this._timezoneService.formattedISODate(d);
    } else {
      return '';
    }
  }
}

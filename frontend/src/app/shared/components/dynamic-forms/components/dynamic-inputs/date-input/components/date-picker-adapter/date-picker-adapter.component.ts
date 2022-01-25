import {
  AfterViewInit, ChangeDetectorRef, Component, forwardRef, NgZone,
} from '@angular/core';
import { OpSingleDatePickerComponent } from 'core-app/shared/components/op-date-picker/op-single-date-picker/op-single-date-picker.component';
import * as moment from 'moment';
import { NG_VALUE_ACCESSOR } from '@angular/forms';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';

@Component({
  selector: 'op-date-picker-adapter',
  templateUrl: '../../../../../../op-date-picker/op-single-date-picker/op-single-date-picker.component.html',
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => DatePickerAdapterComponent),
      multi: true,
    },
  ],
})
export class DatePickerAdapterComponent extends OpSingleDatePickerComponent implements AfterViewInit {
  onControlChange = (_:any) => { };

  onControlTouch = () => { };

  constructor(
    timezoneService:TimezoneService,
    configurationService:ConfigurationService,
    private ngZone:NgZone,
    private changeDetectorRef:ChangeDetectorRef,
  ) {
    super(timezoneService, configurationService);
  }

  writeValue(date:string):void {
    this.initialDate = this.formatter(date);
  }

  registerOnChange(fn:(_:any) => void):void {
    this.onControlChange = fn;
  }

  registerOnTouched(fn:any):void {
    this.onControlTouch = fn;
  }

  setDisabledState(disabled:boolean):void {
    this.disabled = disabled;
  }

  ngAfterViewInit():void {
    this.ngZone.runOutsideAngular(() => {
      setTimeout(() => {
        this.initializeDatepicker();
        this.changeDetectorRef.detectChanges();
      });
    });
  }

  onInputChange():void {
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

  public parser(data:any) {
    if (moment(data, 'YYYY-MM-DD', true).isValid()) {
      return data;
    }
    return null;
  }

  public formatter(data:any):string {
    if (moment(data, 'YYYY-MM-DD', true).isValid()) {
      const d = this.timezoneService.parseDate(data);

      return this.timezoneService.formattedISODate(d);
    }
    return '';
  }
}

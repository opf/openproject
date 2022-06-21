import {
  AfterViewInit,
  Component,
  forwardRef,
  Input,
} from '@angular/core';
import * as moment from 'moment';
import {
  ControlValueAccessor,
  NG_VALUE_ACCESSOR,
} from '@angular/forms';
import { OpSingleDatePickerComponent } from 'core-app/shared/components/op-date-picker/op-single-date-picker/op-single-date-picker.component';

/* eslint-disable-next-line change-detection-strategy/on-push */
@Component({
  selector: 'op-date-picker-control',
  templateUrl: '../../../../../../op-date-picker/op-single-date-picker/op-single-date-picker.component.html',
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => DatePickerControlComponent),
      multi: true,
    },
  ],
})
export class DatePickerControlComponent extends OpSingleDatePickerComponent implements ControlValueAccessor, AfterViewInit {
  // Avoid Angular warning (It looks like you're using the disabled attribute with a reactive form directive...)
  /* eslint-disable-next-line @angular-eslint/no-input-rename */
  @Input('disable') disabled:boolean;

  // eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types
  onControlChange:(_?:unknown) => void = () => { };

  // eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types
  onControlTouch:(_?:unknown) => void = () => { };

  writeValue(date:string):void {
    this.initialDate = this.formatter(date);
  }

  registerOnChange(fn:(_:unknown) => void):void {
    this.onControlChange = fn;
  }

  registerOnTouched(fn:(_:unknown) => void):void {
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
    const valueToEmit = this.inputIsValidDate()
      ? this.parser(this.currentValue)
      : '';

    this.onControlChange(valueToEmit);
    this.onControlTouch();
  }

  closeOnOutsideClick(event:MouseEvent):void {
    super.closeOnOutsideClick(event);
    this.onControlTouch();
  }

  public parser(data:string):string|null {
    if (moment(data, 'YYYY-MM-DD', true).isValid()) {
      return data;
    }
    return null;
  }

  public formatter(data:string):string {
    if (moment(data, 'YYYY-MM-DD', true).isValid()) {
      const d = this.timezoneService.parseDate(data);

      return this.timezoneService.formattedISODate(d);
    }
    return '';
  }
}

import {
  Component,
  EventEmitter,
  forwardRef,
  HostBinding,
  Input,
  Output,
} from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';

export interface SpotToggleOption<T> {
  value:T;
  title:string;
};

@Component({
  selector: 'spot-toggle',
  templateUrl: './toggle.component.html',
  providers: [{
    provide: NG_VALUE_ACCESSOR,
    useExisting: forwardRef(() => SpotToggleComponent),
    multi: true,
  }],
})
export class SpotToggleComponent<T> implements ControlValueAccessor {
  // TODO: These old styles will need to be replaced
  @HostBinding('class.form--field-inline-buttons-container') public classNameOld = true;

  @HostBinding('class.spot-toggle') public className = true;

  @Output() valueChange = new EventEmitter<T>();

  @Input() options:SpotToggleOption<T>[] = [];

  @Input() name = `spot-toggle-${+(new Date())}`;

  @Input('value') public _value:T;

  public get value():T {
    return this._value;
  }

  public set value(value:T) {
    this._value = value;
    this.onChange(value);
    this.onTouched(value);
    this.valueChange.emit(value);
  }

  writeValue(value:T):void {
    this.value = value;
  }

  onChange: (t:T) => void = (_:T):void => {};

  onTouched: (t:T) => void = (_:T):void => {};

  registerOnChange(fn:(_:T) => void):void {
    this.onChange = fn;
  }

  registerOnTouched(fn:(_:T) => void):void {
    this.onTouched = fn;
  }
}

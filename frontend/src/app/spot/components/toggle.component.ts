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
  @HostBinding('class.spot-toggle') public className = true;

  @Output() checkedChange = new EventEmitter<boolean>();

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
  }

  writeValue(value:T) {
    this.value = value;
  }

  onChange = (_:T) => {};
  onTouched = (_:T) => {};

  registerOnChange(fn:any) {
    this.onChange = fn;
  }

  registerOnTouched(fn:any) {
    this.onTouched = fn;
  }
}


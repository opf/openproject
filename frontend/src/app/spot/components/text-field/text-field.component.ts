import {
  Component,
  ElementRef,
  ViewChild,
  forwardRef,
  HostBinding,
  HostListener,
  Input,
} from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';

@Component({
  selector: 'spot-text-field',
  templateUrl: './text-field.component.html',
  providers: [{
    provide: NG_VALUE_ACCESSOR,
    useExisting: forwardRef(() => SpotTextFieldComponent),
    multi: true,
  }],
})
export class SpotTextFieldComponent implements ControlValueAccessor {
  @HostBinding('class.spot-text-field') public className = true;

  @HostBinding('class.spot-text-field_focused') public focused = false;

  @HostListener('click') public onParentClick() {
    this.input.nativeElement.focus();
  }

  @ViewChild('input') public input:ElementRef;

  @Input() name = `spot-text-field-${+(new Date())}`;

  @Input() disabled = false;

  @Input() showClearButton = true;

  @Input() public placeholder = '';

  @Input('value') public _value = '';

  get value():string {
    return this._value;
  }

  set value(value:string) {
    this._value = value;
    this.onChange(value);
    this.onTouched(value);
  }

  writeValue(value:string) {
    this.value = value;
  }

  onChange = (_:string):void => {};

  onTouched = (_:string):void => {};

  registerOnChange(fn:(_:string) => void):void {
    this.onChange = fn;
  }

  registerOnTouched(fn:(_:string) => void):void {
    this.onTouched = fn;
  }
}

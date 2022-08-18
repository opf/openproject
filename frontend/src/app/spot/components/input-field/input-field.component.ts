import {
  Component,
  ElementRef,
  ViewChild,
  forwardRef,
  HostBinding,
  HostListener,
  Input,
  Output,
  EventEmitter,
} from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';

type AllowedInputTypes = 'text'|'number';

@Component({
  selector: 'spot-input-field',
  templateUrl: './input-field.component.html',
  providers: [{
    provide: NG_VALUE_ACCESSOR,
    useExisting: forwardRef(() => SpotInputFieldComponent),
    multi: true,
  }],
})
export class SpotInputFieldComponent implements ControlValueAccessor {
  @HostBinding('class.spot-input-field') public className = true;

  @HostBinding('class.spot-input-field_focused') public focused = false;

  @HostListener('click') public onParentClick() {
    this.input.nativeElement.focus();
  }

  @ViewChild('input') public input:ElementRef;

  @Input() name = `spot-input-field-${+(new Date())}`;

  @HostBinding('class.spot-input-field_disabled') @Input() disabled = false;

  @Input() showClearButton = true;

  @Input() public placeholder = '';

  @Input() public type:AllowedInputTypes = 'text';

  @Input('value') public _value = '';

  get value():string {
    return this._value;
  }

  set value(value:string) {
    this._value = value;
    this.onChange(value);
    this.onTouched(value);
  }

  @Output() public inputFocus = new EventEmitter<FocusEvent>();

  @Output() public inputBlur = new EventEmitter<FocusEvent>();

  onInputFocus(event:FocusEvent):void {
    this.focused = true;
    this.inputFocus.next(event);
  }

  onInputBlur(event:FocusEvent):void {
    this.focused = false;
    this.inputBlur.next(event);
  }

  writeValue(value:string) {
    this.value = value || '';
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

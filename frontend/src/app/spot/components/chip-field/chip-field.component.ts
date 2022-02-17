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
  selector: 'spot-chip-field',
  templateUrl: './chip-field.component.html',
  providers: [{
    provide: NG_VALUE_ACCESSOR,
    useExisting: forwardRef(() => SpotChipFieldComponent),
    multi: true,
  }],
})
export class SpotChipFieldComponent implements ControlValueAccessor {
  @HostBinding('class.spot-chip-field') public classNameChipField = true;
  @HostBinding('class.spot-text-field') public classNameTextField = true;

  @HostListener('click') public onParentClick() {
    this.input.nativeElement.focus();
  }

  @ViewChild('input') public input:ElementRef;

  @Input() name = `spot-chip-field-${+(new Date())}`;
  @Input() disabled = false;
  @Input() public placeholder = '';
  @Input('value') public _value:string[] = [];

  public textValue = '';

  public get value():string[] {
    return this._value;
  }

  public set value(value:string[]) {
    this._value = value;
    this.onChange(value);
    this.onTouched(value);
  }

  public remove(i:number) {
    this.value = this.value.slice(0, i).concat(this.value.slice(i + 1));
  }

  public onBackspace(e:KeyboardEvent) {
    if (this.textValue !== '') {
      return;
    }

    e.preventDefault();

    this.value = this.value.slice(0, this.value.length - 1);
  }

  public onEnter(e:KeyboardEvent) {
    e.stopPropagation();

    if (this.textValue === '') {
      return;
    }

    e.preventDefault();

    this.value = [
      ...this.value,
      this.textValue,
    ];

    this.textValue = '';
  }

  writeValue(value:string[]) {
    this.value = value;
  }

  onChange = (_:string[]) => {};
  onTouched = (_:string[]) => {};

  registerOnChange(fn:any) {
    this.onChange = fn;
  }

  registerOnTouched(fn:any) {
    this.onTouched = fn;
  }
}


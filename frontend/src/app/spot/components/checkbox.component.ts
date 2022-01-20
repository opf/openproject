import {
  Component,
  ElementRef,
  EventEmitter,
  ViewChild,
  forwardRef,
  HostBinding,
  Input,
  Output,
} from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';

export type SpotCheckboxState = true|false|null;

@Component({
  selector: 'spot-checkbox',
  templateUrl: './checkbox.component.html',
  providers: [{
    provide: NG_VALUE_ACCESSOR,
    useExisting: forwardRef(() => SpotCheckboxComponent),
    multi: true,
  }],
})
export class SpotCheckboxComponent implements ControlValueAccessor {
  @HostBinding('class.spot-checkbox') public className = true;

  @ViewChild('input') public input:ElementRef;

  @Input() name = `spot-checkbox-${+(new Date())}`;

  @Output() change = new EventEmitter<boolean>();

  onStateChange(e:Event) {
    console.log('Checkbox changed!', e);
  }

  onChange = (_:SpotCheckboxState) => {};

  onTouched = (_:SpotCheckboxState) => {};

  writeValue(value:SpotCheckboxState) {
    const input = this.input.nativeElement;
    if (value === null) {
      input.indeterminate = true;
      return;
    }

    input.indeterminate = false;
    input.checked = value;
  }

  registerOnChange(fn:any) {
    this.onChange = fn;
  }

  registerOnTouched(fn:any) {
    this.onTouched = fn;
  }
}

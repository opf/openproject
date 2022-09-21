import {
  Component,
  ElementRef,
  EventEmitter,
  forwardRef,
  HostBinding,
  Input,
  Output,
  ViewChild,
} from '@angular/core';
import {
  ControlValueAccessor,
  NG_VALUE_ACCESSOR,
} from '@angular/forms';

export type SpotSwitchState = boolean;

@Component({
  selector: 'spot-switch',
  templateUrl: './switch.component.html',
  providers: [{
    provide: NG_VALUE_ACCESSOR,
    useExisting: forwardRef(() => SpotSwitchComponent),
    multi: true,
  }],
})
export class SpotSwitchComponent implements ControlValueAccessor {
  @HostBinding('class.spot-switch') public className = true;

  @ViewChild('input') public input:ElementRef;

  @Input() tabindex = 0;

  @Input() disabled = false;

  @Input() name = `spot-switch-${+(new Date())}`;

  @Output() checkedChange = new EventEmitter<boolean>();

  @Input() public checked = false;

  onStateChange():void {
    const value = (this.input.nativeElement as HTMLInputElement).checked;
    this.checkedChange.emit(value);
    this.onChange(value);
    this.onTouched(value);
  }

  writeValue(value:SpotSwitchState):void {
    // This is set in a timeout because the initial value is set before the template is ready,
    // which causes the input nativeElement to not be available yet.
    setTimeout(() => {
      const input = this.input.nativeElement as HTMLInputElement;
      if (value === null) {
        input.indeterminate = true;
      } else {
        input.indeterminate = false;
      }

      this.checked = !!value;
    });
  }

  onChange = (_:SpotSwitchState):void => {};

  onTouched = (_:SpotSwitchState):void => {};

  registerOnChange(fn:(_:SpotSwitchState) => void):void {
    this.onChange = fn;
  }

  registerOnTouched(fn:(_:SpotSwitchState) => void):void {
    this.onTouched = fn;
  }
}

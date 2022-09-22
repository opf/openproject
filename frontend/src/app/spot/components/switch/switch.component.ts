import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
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
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';

export type SpotSwitchState = boolean;

export const spotSwitchSelector = 'spot-switch';

@Component({
  selector: spotSwitchSelector,
  templateUrl: './switch.component.html',
  providers: [{
    provide: NG_VALUE_ACCESSOR,
    useExisting: forwardRef(() => SpotSwitchComponent),
    multi: true,
  }],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SpotSwitchComponent implements ControlValueAccessor {
  @HostBinding('class.spot-switch') public className = true;

  @ViewChild('input') public input:ElementRef;

  @Input() tabindex = 0;

  @Input() disabled = false;

  @Input() name = `spot-switch-${+(new Date())}`;

  @Output() checkedChange = new EventEmitter<boolean>();

  @Input() public checked = false;

  constructor(
    public elementRef:ElementRef,
    public cdRef:ChangeDetectorRef,
  ) {
    populateInputsFromDataset(this);
  }

  onStateChange():void {
    const value = (this.input.nativeElement as HTMLInputElement).checked;
    this.checkedChange.emit(value);
    this.onChange(value);
    this.onTouched(value);
  }

  writeValue(value:SpotSwitchState):void {
    this.checked = !!value;
    this.cdRef.markForCheck();
  }

  onToggle(value:SpotSwitchState):void {
    this.writeValue(value);
    this.onChange(value);
    this.onTouched(value);
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

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
  ChangeDetectorRef,
} from '@angular/core';
import {
  ControlValueAccessor,
  NG_VALUE_ACCESSOR,
} from '@angular/forms';

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

  @HostListener('click')
  public onParentClick():void {
    this.input.nativeElement.focus();
  }

  @ViewChild('input') public input:ElementRef;

  @Input() name = `spot-text-field-${+(new Date())}`;

  @HostBinding('class.spot-text-field_disabled') @Input() disabled = false;

  @Input() showClearButton = true;

  @Input() public placeholder = '';

  @Input() public value = '';

  valueChanged(value:string):void {
    this.writeValue(value);
    this.onChange(value);
    this.onTouched(value);
  }

  @Output() public inputFocus = new EventEmitter<FocusEvent>();

  @Output() public inputBlur = new EventEmitter<FocusEvent>();

  constructor(
    private cdRef:ChangeDetectorRef,
  ) {}

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
    this.cdRef.markForCheck();
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

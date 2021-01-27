import {
  Component,
  Input,
  HostBinding,
  forwardRef,
} from "@angular/core";
import {
  ControlContainer,
  NG_VALUE_ACCESSOR,
  ControlValueAccessor,
} from "@angular/forms";

@Component({
  selector: 'op-form-field',
  templateUrl: './form-field.component.html',
  // Style is imported globally
  providers: [{
    provide: NG_VALUE_ACCESSOR,
    useExisting: forwardRef(() => OpFormFieldComponent),
    multi: true,
  }],
})
export class OpFormFieldComponent implements ControlValueAccessor {
  @HostBinding('class.op-form-field') className = true;
  @HostBinding('class.op-form-field_invalid') get errorClassName() {
    return this.isInvalid;
  }

  @Input() label:string = '';
  @Input() required:boolean = false;

  constructor(readonly controlContainer:ControlContainer) {}

  get formControl() {
    return this.controlContainer.control;
  }

  get isInvalid() {
    console.log(this.formControl?.status, this.formControl?.value);
    return this.formControl?.touched && this.formControl?.invalid;
  }

  writeValue() {}
  registerOnChange() {}
  registerOnTouched() {}
}

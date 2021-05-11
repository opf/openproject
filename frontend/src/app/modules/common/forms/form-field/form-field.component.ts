import {
  Component,
  Input,
  HostBinding,
  ContentChild,
  Optional,
} from "@angular/core";
import {
  NgControl,
  AbstractControl,
  FormGroupDirective,
} from "@angular/forms";

@Component({
  selector: 'op-form-field',
  templateUrl: './form-field.component.html',
})
export class OpFormFieldComponent {
  @HostBinding('class.op-form-field') className = true;
  @HostBinding('class.op-form-field_invalid') get errorClassName() {
    return this.showErrorMessage;
  }

  @Input() label = '';
  @Input() noWrapLabel = true;
  @Input() required = false;
  @Input() hidden = false;
  @Input() showValidationErrorOn:'change' | 'blur' | 'submit' | 'never' = 'submit';
  @Input() control?:AbstractControl;
  @Input() helpTextAttribute?:string;
  @Input() helpTextAttributeScope?:string;

  @ContentChild(NgControl) ngControl:NgControl;

  get formControl():AbstractControl|undefined|null {
    return this.ngControl?.control || this.control;
  }

  get showErrorMessage():boolean {
    let showErrorMessage = false;

    if (!this.formControl) {
      return false;
    }

    if (this.showValidationErrorOn === 'submit') {
      showErrorMessage =  this.formControl.invalid && this._formGroupDirective?.submitted;
    } else if (this.showValidationErrorOn === 'blur') {
      showErrorMessage =  this.formControl.invalid && this.formControl.touched;
    } else if (this.showValidationErrorOn === 'change') {
      showErrorMessage =  this.formControl.invalid && this.formControl.dirty;
    }

    return showErrorMessage;
  }

  constructor(
    @Optional() private _formGroupDirective:FormGroupDirective,
  ) {}
}

import {
  Component,
  Input,
  HostBinding,
  ContentChild,
} from "@angular/core";
import {
  NgControl,
  AbstractControl,
  FormGroupDirective,
} from "@angular/forms";
import { FormlyField } from "@ngx-formly/core";

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
  @Input() inlineLabel = true;
  @Input() required = false;
  @Input() showValidationErrorOn: 'change' | 'blur' | 'submit' | 'never' = 'submit';

  @ContentChild(NgControl) ngControl:NgControl;
  @ContentChild(FormlyField) dynamicControl:FormlyField;

  get formControl ():AbstractControl|undefined|null {
    return this.ngControl?.control || this.dynamicControl?.field?.formControl;
  }

  get showErrorMessage():boolean {
    if (!this.formControl) {
      return false;
    }

    if (this.showValidationErrorOn === 'submit') {
      return this.formControl.invalid && this._formGroupDirective?.submitted;
    } else if (this.showValidationErrorOn === 'blur') {
      return this.formControl.invalid && this.formControl.touched;
    } else if (this.showValidationErrorOn === 'change') {
      return this.formControl.invalid && this.formControl.dirty;
    } else {
      return false;
    }
  }

  constructor(
    private _formGroupDirective:FormGroupDirective,
  ) {}
}

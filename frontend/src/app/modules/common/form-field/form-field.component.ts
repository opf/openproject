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
    private _formGroupDirective:FormGroupDirective,
  ) {}
}

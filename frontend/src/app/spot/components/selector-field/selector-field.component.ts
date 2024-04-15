import {
  Component,
  ContentChild,
  HostBinding,
  Input,
  Optional,
} from '@angular/core';
import {
  AbstractControl,
  FormGroupDirective,
  NgControl,
} from '@angular/forms';

@Component({
  selector: 'spot-selector-field',
  templateUrl: './selector-field.component.html',
})
export class SpotSelectorFieldComponent {
  @HostBinding('class.spot-form-field') className = true;

  @HostBinding('class.spot-selector-field') classNameCheckbox = true;

  @HostBinding('class.spot-form-field_invalid') get errorClassName():boolean {
    return this.showErrorMessage;
  }

  /**
   * The text label of the input
   */
  @Input() label = '';

  /**
   * Whether the label should be in front of the input instead of after it
   */
  @Input() reverseLabel = false;

  /**
   * Whether the label should be in bold or regular font weight
   */
  @Input() labelWeight:'bold'|'regular' = 'bold';

  /**
   * Whether this input is required
   */
  @Input() required = false;

  /**
   * When to show validation errors. To remain consistent, you will almost never need to change this.
   * However, for some inputs or usecases it might be useful to show the validation error anyway.
   */
  @Input() showValidationErrorOn:'change'|'blur'|'submit'|'never' = 'submit';

  /**
   * The control of the input. This can be any interface that is compatible with `AbstractControl`,
   * but will almost always be a `FormControl`.
   *
   * The control is used to show disabled and invalid states.
   */
  @Input() control?:AbstractControl;

  /**
   * Hides the input. This is a utility input for usage of `spot-form-field` in dynamic forms.
   * Outside of dynamic forms, you should be hiding inputs via `*ngIf` or other methods.
   */
  @Input() hidden = false;

  @ContentChild(NgControl) ngControl:NgControl;

  internalID = `spot-selector-field-${+new Date()}`;

  get errorsID():string {
    return `${this.internalID}-errors`;
  }

  get descriptionID():string {
    return `${this.internalID}-description`;
  }

  get describedByID():string {
    return this.showErrorMessage ? this.errorsID : this.descriptionID;
  }

  get formControl():AbstractControl|undefined|null {
    return this.ngControl?.control || this.control;
  }

  get showErrorMessage():boolean {
    if (!this.formControl) {
      return false;
    }

    if (this.showValidationErrorOn === 'submit') {
      return this.formControl.invalid && this.formGroupDirective?.submitted;
    }
    if (this.showValidationErrorOn === 'blur') {
      return this.formControl.invalid && this.formControl.touched;
    }
    if (this.showValidationErrorOn === 'change') {
      return this.formControl.invalid && this.formControl.dirty;
    }

    return false;
  }

  constructor(
    @Optional() private formGroupDirective:FormGroupDirective,
  ) {}
}

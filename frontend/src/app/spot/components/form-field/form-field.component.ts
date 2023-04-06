import {
  Component, ContentChild, HostBinding, Input, Optional,
} from '@angular/core';
import { AbstractControl, FormGroupDirective, NgControl } from '@angular/forms';
import { I18nService } from 'core-app/core/i18n/i18n.service';

/* eslint-disable-next-line change-detection-strategy/on-push */
@Component({
  selector: 'spot-form-field',
  templateUrl: './form-field.component.html',
})
export class SpotFormFieldComponent {
  @HostBinding('class.spot-form-field') className = true;

  @HostBinding('class.spot-form-field_invalid') get errorClassName():boolean {
    return this.showErrorMessage;
  }

  /**
   * The text label of the input
   */
  @Input() label = '';

  /**
   * By default, the label wraps the input. For some input types this
   * leads to unwanted behavior because clicking in the input might focus
   * unrelated elements.
   *
   * One example of an input like is the CKEditor rich text editor.
   *
   * Setting noWrapLabel to `true` causes the label not to wrap the input.
   * This might slightly reduce the label functionality (e.g. clicking the label
   * does not focus the input) but is still preferred over more broken behavior.
   */
  @Input() noWrapLabel = false;

  /**
   * Whether this input is required
   */
  @Input() required = false;

  /**
   * When to show validation errors. To remain consistent, you will almost never need to change this.
   * However, for some inputs or usecases it might be useful to show the validation error anyway.
   */
  @Input() showValidationErrorOn:'change' | 'blur' | 'submit' | 'never' = 'submit';

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

  internalID = `spot-form-field-${+new Date()}`;

  text = {
    invalid: this.I18n.t('js.label_invalid'),
  };

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
      return this.formControl.invalid && this._formGroupDirective?.submitted;
    } if (this.showValidationErrorOn === 'blur') {
      return this.formControl.invalid && this.formControl.touched;
    } if (this.showValidationErrorOn === 'change') {
      return this.formControl.invalid && this.formControl.dirty;
    }

    return false;
  }

  constructor(
    @Optional() private _formGroupDirective:FormGroupDirective,
    readonly I18n:I18nService,
  ) {}
}

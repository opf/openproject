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

  @Input() label = '';

  @Input() noWrapLabel = false;

  @Input() required = false;

  @Input() hidden = false;

  @Input() showValidationErrorOn:'change' | 'blur' | 'submit' | 'never' = 'submit';

  @Input() control?:AbstractControl;

  @Input() helpTextAttribute?:string;

  @Input() helpTextAttributeScope?:string;

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

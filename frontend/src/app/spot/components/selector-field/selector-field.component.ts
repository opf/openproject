//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectionStrategy, Component, ContentChild, HostBinding, Input, inject } from '@angular/core';
import {
  AbstractControl,
  FormGroupDirective,
  NgControl,
} from '@angular/forms';

@Component({
  selector: 'spot-selector-field',
  templateUrl: './selector-field.component.html',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class SpotSelectorFieldComponent {
  private formGroupDirective = inject(FormGroupDirective, { optional: true });

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
   * Outside of dynamic forms, you should be hiding inputs via `@if` or other methods.
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
      return this.formControl.invalid && (this.formGroupDirective?.submitted ?? false);
    }
    if (this.showValidationErrorOn === 'blur') {
      return this.formControl.invalid && this.formControl.touched;
    }
    if (this.showValidationErrorOn === 'change') {
      return this.formControl.invalid && this.formControl.dirty;
    }

    return false;
  }
}

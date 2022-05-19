import { Directive, forwardRef, Input } from '@angular/core';
import {
  UntypedFormArray, UntypedFormControl, UntypedFormGroup, NgControl,
} from '@angular/forms';

export const formControlBinding = {
  provide: NgControl,
  // eslint-disable-next-line @typescript-eslint/no-use-before-define
  useExisting: forwardRef(() => SpotFormBindingDirective),
};

@Directive({
  selector: '[spotFormBinding]',
  providers: [formControlBinding],
  exportAs: 'ngForm',
})
export class SpotFormBindingDirective extends NgControl {
  @Input('spotFormBinding') form!:UntypedFormControl|UntypedFormGroup|UntypedFormArray;

  get control():UntypedFormControl|UntypedFormGroup|UntypedFormArray {
    return this.form;
  }

  viewToModelUpdate():void {}
}

import { Directive, forwardRef, Input } from '@angular/core';
import {
  UntypedFormArray, UntypedFormControl, UntypedFormGroup, NgControl,
} from '@angular/forms';

export const formControlBinding = {
  provide: NgControl,
  useExisting: forwardRef(() => SpotFormBindingDirective),
};

@Directive({
  selector: '[spotFormBinding]',
  providers: [formControlBinding],
  exportAs: 'ngForm',
  standalone: false,
})
export class SpotFormBindingDirective extends NgControl {
  @Input('spotFormBinding') form!:UntypedFormControl|UntypedFormGroup|UntypedFormArray;

  constructor() {
    super();
  }

  get control():UntypedFormControl|UntypedFormGroup|UntypedFormArray {
    return this.form;
  }

  viewToModelUpdate():void {}
}

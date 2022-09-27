import { Directive, forwardRef, Input } from '@angular/core';
import {
  FormArray, FormControl, FormGroup, NgControl,
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
  @Input('spotFormBinding') form!:FormControl|FormGroup|FormArray;

  get control():FormControl|FormGroup|FormArray {
    return this.form;
  }

  viewToModelUpdate():void {}
}

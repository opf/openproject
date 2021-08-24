import { Directive, forwardRef, Input } from '@angular/core';
import {
  FormArray, FormControl, FormGroup, NgControl,
} from '@angular/forms';

export const formControlBinding:any = {
  provide: NgControl,
  useExisting: forwardRef(() => OpFormBindingDirective),
};

@Directive({
  selector: '[opFormBinding]',
  providers: [formControlBinding],
  exportAs: 'ngForm',
})
export class OpFormBindingDirective extends NgControl {
  @Input('opFormBinding') form!:FormControl|FormGroup|FormArray;

  get control():FormControl|FormGroup|FormArray {
    return this.form;
  }

  viewToModelUpdate():void {}
}

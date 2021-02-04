import {
  Directive,
  forwardRef,
  Input,
} from '@angular/core';
import {
  NgControl,
  FormControl,
  FormGroup,
} from '@angular/forms';

export const formControlBinding:any = {
  provide: NgControl,
  useExisting: forwardRef(() => OpFormBindingDirective)
};

@Directive({selector: '[opFormBinding]', providers: [formControlBinding], exportAs: 'ngForm'})
export class OpFormBindingDirective extends NgControl {
  @Input('opFormBinding') form!:FormControl|FormGroup;

  get control():FormControl|FormGroup {
    return this.form;
  }

  viewToModelUpdate():void {}
}

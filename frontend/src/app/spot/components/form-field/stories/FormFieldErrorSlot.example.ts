import { Component } from '@angular/core';
import {
  FormGroup,
  FormControl,
  Validators,
} from '@angular/forms';

@Component({
  templateUrl: './FormFieldErrorSlot.example.html',
})
export class SbFormFieldErrorSlotExample {
  public myForm = new FormGroup({
    myInput: new FormControl(null, [Validators.required, Validators.minLength(8)]),
  });

  get myInputControl() {
    return this.myForm.get('myInput')!;
  }

  onSubmit(event:Event) {
    event.preventDefault();
    console.log('submitted!');
    console.log(this.myInputControl);
  }
}

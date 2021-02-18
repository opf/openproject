import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import {OpFormBindingDirective} from "core-app/modules/common/form-field/form-binding.directive";
import {OpFormFieldComponent} from "core-app/modules/common/form-field/form-field.component";



@NgModule({
  declarations: [
    OpFormBindingDirective,
    OpFormFieldComponent,
  ],
  imports: [
    CommonModule
  ],
  exports: [
    OpFormBindingDirective,
    OpFormFieldComponent,
  ]
})
export class OpFormFieldModule { }

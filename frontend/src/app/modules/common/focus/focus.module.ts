import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FocusWithinDirective } from "core-app/modules/common/focus/focus-within.directive";
import { FocusDirective } from "core-app/modules/common/focus/focus.directive";



@NgModule({
  declarations: [
    FocusDirective,
    FocusWithinDirective,
  ],
  imports: [
    CommonModule
  ],
  exports: [
    FocusDirective,
    FocusWithinDirective,
  ]
})
export class FocusModule { }

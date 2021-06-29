import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { FocusWithinDirective } from "./focus-within.directive";
import { FocusDirective } from "./focus.directive";

@NgModule({
  declarations: [
    FocusDirective,
    FocusWithinDirective,
  ],
  imports: [
    CommonModule,
  ],
  exports: [
    FocusDirective,
    FocusWithinDirective,
  ],
})
export class FocusModule { }

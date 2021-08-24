import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { FocusWithinDirective } from './focus-within.directive';
import { AutofocusDirective } from './autofocus.directive';

@NgModule({
  declarations: [
    AutofocusDirective,
    FocusWithinDirective,
  ],
  imports: [
    CommonModule,
  ],
  exports: [
    AutofocusDirective,
    FocusWithinDirective,
  ],
})
export class FocusModule { }

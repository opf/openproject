import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BooleanEditFieldComponent } from 'core-app/shared/components/fields/edit/field-types/boolean-edit-field/boolean-edit-field.component';

@NgModule({
  declarations: [
    BooleanEditFieldComponent,
  ],
  imports: [
    CommonModule,
  ],
  exports: [
    BooleanEditFieldComponent,
  ],
})
export class BooleanEditFieldModule { }

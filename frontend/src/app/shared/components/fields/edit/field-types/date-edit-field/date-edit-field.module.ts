import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DateEditFieldComponent } from 'core-app/shared/components/fields/edit/field-types/date-edit-field/date-edit-field.component';

@NgModule({
  declarations: [
    DateEditFieldComponent,
  ],
  imports: [
    CommonModule,
  ],
  exports: [
    DateEditFieldComponent,
  ],
})
export class DateEditFieldModule { }

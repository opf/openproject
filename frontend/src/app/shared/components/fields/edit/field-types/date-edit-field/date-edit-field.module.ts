import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DateEditFieldComponent } from 'core-app/shared/components/fields/edit/field-types/date-edit-field/date-edit-field.component';
import { OpSharedModule } from 'core-app/shared/shared.module';

@NgModule({
  imports: [
    CommonModule,
    OpSharedModule,
  ],
  declarations: [
    DateEditFieldComponent,
  ],
  exports: [
    DateEditFieldComponent,
  ],
})
export class DateEditFieldModule { }

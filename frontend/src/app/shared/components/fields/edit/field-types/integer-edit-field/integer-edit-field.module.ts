import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { IntegerEditFieldComponent } from 'core-app/shared/components/fields/edit/field-types/integer-edit-field/integer-edit-field.component';
import { FormsModule } from '@angular/forms';

@NgModule({
  declarations: [
    IntegerEditFieldComponent,
  ],
  imports: [
    CommonModule,
    FormsModule,
  ],
  exports: [
    IntegerEditFieldComponent,
  ],
})
export class IntegerEditFieldModule { }

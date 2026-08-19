import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { SelectEditFieldComponent } from 'core-app/shared/components/fields/edit/field-types/select-edit-field/select-edit-field.component';
import { DynamicModule } from 'ng-dynamic-component';

@NgModule({
  imports: [
    CommonModule,
    DynamicModule,
  ],
  declarations: [
    SelectEditFieldComponent,
  ],
  exports: [
    SelectEditFieldComponent,
  ],
})
export class SelectEditFieldModule { }

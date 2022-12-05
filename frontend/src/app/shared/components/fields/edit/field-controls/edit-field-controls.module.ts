import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { EditFieldControlsComponent } from 'core-app/shared/components/fields/edit/field-controls/edit-field-controls.component';
import { OpSharedModule } from 'core-app/shared/shared.module';

@NgModule({
  declarations: [
    EditFieldControlsComponent,
  ],
  imports: [
    CommonModule,
    OpSharedModule,
  ],
  exports: [
    EditFieldControlsComponent,
  ],
})
export class EditFieldControlsModule { }

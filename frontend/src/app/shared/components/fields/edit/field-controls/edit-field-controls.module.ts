import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { EditFieldControlsComponent } from 'core-app/shared/components/fields/edit/field-controls/edit-field-controls.component';
import { OPSharedModule } from 'core-app/shared/shared.module';

@NgModule({
  declarations: [
    EditFieldControlsComponent,
  ],
  imports: [
    CommonModule,
    OPSharedModule,
  ],
  exports: [
    EditFieldControlsComponent,
  ],
})
export class EditFieldControlsModule { }

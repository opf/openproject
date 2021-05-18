import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { EditFieldControlsComponent } from "core-app/shared/components/fields/edit/field-controls/edit-field-controls.component";
import { OpenprojectCommonModule } from "core-app/modules/common/openproject-common.module";


@NgModule({
  declarations: [
    EditFieldControlsComponent,
  ],
  imports: [
    CommonModule,
    OpenprojectCommonModule,
  ],
  exports: [
    EditFieldControlsComponent,
  ]
})
export class EditFieldControlsModule { }
